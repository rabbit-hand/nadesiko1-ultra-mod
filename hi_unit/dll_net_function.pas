unit dll_net_function;

interface

uses
  Windows, SysUtils, Classes, UrlMon, WinInet, kskFtp, SyncObjs, 
  dll_plugin_helper, dnako_import, dnako_import_types, winsock, unit_eml, 
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdFTPCommon, 
  IdFTP, IdFTPList, IdHttp, IdTcpServer, IdSNTP, IdSMTP, IdMessage, 
  IdPOP3, IdReplyPOP3, IdSASLLogin, IdAttachmentFile, IdMessageParts, 
  IdUserPassProvider, IdSSLOpenSSL, IdExplicitTLSClientServerBase, IdLogFile, IdURI,
  System.Threading, System.Net.HttpClient, System.JSON, System.Hash, System.NetEncoding, ComObj, Variants; // ★最新型コア ＆ Office連携ライブラリを完全インポート

const
  NAKONET_DLL_VERSION = '1.512-ULTRA-MOD'; // 魔改造版バージョン

type
  TNetDialogStatus = (statWork, statError, statComplete, statCancel);
  
  TNetDialog = class(TComponent)
  private
    hParent: HWND;
    hProgress: HWND;
    WorkCount: Integer;
    bMinMaxInitialized: boolean;
    iPrevPercent: Integer;
  public
    target: string;
    ResultData: string;
    errormessage: string;
    Status: TNetDialogStatus;
    procedure WorkBegin(Sender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Integer);
    procedure WorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure Work(Sender: TObject; AWorkMode: TWorkMode; AWorkCount: Integer);
    procedure WorkBegin64(Sender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure Work64(Sender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    function ShowDialog(stext, sinfo: AnsiString; Visible: Boolean; hObj: THANDLE = 0): Boolean;
    procedure setInfo(s: string);
    procedure setText(s: string);
    procedure Cancel;
    procedure Comlete;
    procedure Error;
  end;

  TNetThread = class(TThread)
  protected
    critical: TCriticalSection;
    procedure Execute; override;
  public
    method: procedure (Sender: TNetThread; ptr: Pointer);
    arg0: Pointer;
    arg1: Pointer;
    arg2: Pointer;
    arg3: Pointer;
    arg4: Pointer;
    constructor Create(CreateSuspended: Boolean);
    destructor Destroy; override;
  end;

function NetDialog: TNetDialog;
function get_on_off(str: string): Boolean;
procedure alert(msg: AnsiString);
procedure RegistFunction;

// ★魔改造関数のすべての宣言
function sys_http_secure_fetch(args: DWORD): PHiValue; stdcall;
function sys_get_sha256(args: DWORD): PHiValue; stdcall;
function sys_libre_calc_write(args: DWORD): PHiValue; stdcall;
function sys_modern_excel_write(args: DWORD): PHiValue; stdcall;

implementation

uses 
  mini_file_utils, unit_file, KPop3, KSmtp, KTcp, KTCPW, unit_string, 
  WSockUtils, Icmp, KHttp, jconvert, md5, nako_dialog_function, 
  nadesiko_version, messages, nako_dialog_const, CommCtrl, unit_kabin, 
  hima_types, unit_content_type, IdAttachment, unit_date, Math, EasyMasks;

var
  pProgDialog: PHiValue = nil;
  FNetDialog: TNetDialog = nil;

const
  NAKO_HTTP_OPTION = 'HTTPオプション';
  FTP_NG_PATTERN   = 'FTPフォルダ除外パターン';

procedure alert(msg: AnsiString);
begin
  Windows.MessageBoxA(0, PAnsiChar(msg), 'Alert', MB_OK);
end;

function NetDialog: TNetDialog;
begin
  if FNetDialog = nil then
  begin
    FNetDialog := TNetDialog.Create(nil);
  end;
  Result := FNetDialog;
end;

{ ==========================================================================
  ★魔改造ロジック1：最新セキュア非同期通信の実装
  ========================================================================== }
function sys_http_secure_fetch(args: DWORD): PHiValue; stdcall;
var
  pURL, pPayload: PHiValue;
  URL, Payload: string;
begin
  pURL := nako_getFuncArg(args, 0);
  pPayload := nako_getFuncArg(args, 1);
  
  URL := string(hi_strU(pURL));
  Payload := string(hi_strU(pPayload));

  TTask.Run(
    procedure
    var
      HTTP: THTTPClient;
      Response: IHTTPResponse;
      RequestStream: TStringStream;
      ResponseBody, S_SjisResult: string;
    begin
      HTTP := THTTPClient.Create;
      RequestStream := nil;
      try
        HTTP.SecureProtocols := [TSecureProtocol.Tls12, TSecureProtocol.Tls13];
        HTTP.ContentType := 'application/json';
        HTTP.CustomHeaders['Accept'] := 'application/json';

        if Payload <> '' then
          RequestStream := TStringStream.Create(Payload, TEncoding.UTF8);

        if RequestStream <> nil then
          Response := HTTP.Post(URL, RequestStream)
        else
          Response := HTTP.Get(URL);

        ResponseBody := Response.ContentAsString(TEncoding.UTF8);
        S_SjisResult := TEncoding.GetEncoding(932).GetString(TEncoding.UTF8.GetBytes(ResponseBody));

        TThread.Synchronize(nil,
          procedure
          begin
            hi_setStrU(nako_getVariable('それ'), AnsiString(S_SjisResult));
          end);
      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              raise Exception.Create('最新セキュア通信エラー: ' + E.Message);
            end);
        end;
      end;
      finally
        RequestStream.Free;
        HTTP.Free;
      end;
    end
  );
  Result := nil;
end;

{ ==========================================================================
  ★魔改造ロジック2：外部DLL不要のネイティブSHA-256ハッシュ計算
  ========================================================================= }
function sys_get_sha256(args: DWORD): PHiValue; stdcall;
var
  pInput: PHiValue;
  InputStr, HashRes: string;
begin
  pInput := nako_getFuncArg(args, 0);
  InputStr := string(hi_strU(pInput));
  
  HashRes := THashSHA2.GetHashString(InputStr, THashSHA2.TSHA2Version.SHA256);
  Result := hi_newStrU(AnsiString(HashRes));
end;

{ ==========================================================================
  ★魔改造ロジック3：LibreOffice Calc（表計算）を直接自動制御する
  ========================================================================== }
function sys_libre_calc_write(args: DWORD): PHiValue; stdcall;
var
  pSheetName, pCell, pText: PHiValue;
  SheetName, CellRef, TextVal: string;
  ServiceManager, Desktop, Document, Sheets, Sheet, Cell: OleVariant;
  Url: string;
  ArgsArray: OleVariant;
begin
  pSheetName := nako_getFuncArg(args, 0);
  pCell      := nako_getFuncArg(args, 1);
  pText      := nako_getFuncArg(args, 2);
  
  SheetName := string(hi_strU(pSheetName));
  CellRef   := string(hi_strU(pCell));
  TextVal   := string(hi_strU(pText));

  try
    ServiceManager := CreateOleObject('com.sun.star.ServiceManager');
    Desktop := ServiceManager.createInstance('com.sun.star.frame.Desktop');
    Url := 'private:factory/scalc';
    ArgsArray := VarArrayCreate([0, -1], varVariant);
    Document := Desktop.loadComponentFromURL(Url, '_blank', 0, ArgsArray);
    Sheets := Document.getSheets;
    
    if Sheets.hasByName(SheetName) then
      Sheet := Sheets.getByName(SheetName)
    else
      Sheet := Sheets.getByIndex(0);
      
    Cell := Sheet.getCellRangeByName(CellRef);
    Cell.setString(WideString(TextVal));
  except
    on E: Exception do
      raise Exception.Create('LibreOffice連携エラー: ' + E.Message);
  end;
  Result := nil;
end;

{ ==========================================================================
  ★魔改造ロジック4：最新の Microsoft Excel への高速書き込み
  ========================================================================== }
function sys_modern_excel_write(args: DWORD): PHiValue; stdcall;
var
  pCell, pText: PHiValue;
  CellRef, TextVal: string;
  ExcelApp, Workbook, Sheet: OleVariant;
begin
  pCell := nako_getFuncArg(args, 0);
  pText := nako_getFuncArg(args, 1);
  
  CellRef := string(hi_strU(pCell));
  TextVal := string(hi_strU(pText));

  try
    try
      ExcelApp := GetActiveOleObject('Excel.Application');
    except
      ExcelApp := CreateOleObject('Excel.Application');
    end;
    
    ExcelApp.Visible := True;
    
    if ExcelApp.Workbooks.Count = 0 then
      Workbook := ExcelApp.Workbooks.Add
    else
      Workbook := ExcelApp.ActiveWorkbook;
      
    Sheet := Workbook.ActiveSheet;
    Sheet.Range[CellRef].Value := WideString(TextVal);
  except
    on E: Exception do
      raise Exception.Create('MS Office連携エラー: ' + E.Message);
  end;
  Result := nil;
end;

// --- 以下、なでしこ本来の既存コード ---

function nako_http_opt_get(name: string): string;
var
  p: PHiValue;
  s: TStringList;
begin
  p := nako_getVariable(NAKO_HTTP_OPTION);
  s := TStringList.Create;
  s.Text := string(hi_str(p));
  Result := Trim(s.Values[name]);
  s.Free;
end;

function get_on_off(str: string): Boolean;
begin
  str := JReplaceW(str, 'オン','1');
  str := JReplaceW(str, 'オフ','0');
  str := JReplaceW(str, 'はい','1');
  str := JReplaceW(str, 'いいえ','0');
  str := JReplaceW(str, '１','1');
  str := JReplaceW(str, '０','0');
  Result := (StrToIntDef(string(str), 0) <> 0);
end;

{ ==========================================================================
  命令登録セクション（なでしこが日本語命令として認識する設定）
  ========================================================================== }
procedure RegistFunction;
begin
  // --- ここに新しい魔改造日本語命令を登録 ---
  nako_addFunction('最新セキュア送信', sys_http_secure_fetch, 'URLへとペイロードを最新セキュア送信');
  nako_addFunction('SHA256計算', sys_get_sha256, 'SのSHA256計算');
  nako_addFunction('リベラ表計算書込', sys_libre_calc_write, 'SのSへSをリベラ表計算書込');
  nako_addFunction('最新エクセル書込', sys_modern_excel_write, 'SへSを最新エクセル書込');
end;

end.
