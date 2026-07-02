unit dll_lan_func;

interface
uses
  windows, dnako_import, dnako_import_types, dll_plugin_helper,
  unit_pack_files, SysUtils, Classes, shellapi, registry, inifiles,
  shlobj, Variants, ActiveX, hima_types, messages, nadesiko_version;

procedure RegistFunction;

implementation

uses unit_file, unit_windows_api, unit_string, hima_stream, StrUnit,
  mini_file_utils, unit_archive, LanUtil, unit_text_file, ComObj,
  unit_kanrenduke,
  EasyMasks;


function nakolan_getUserName(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetUserName);
end;

function nakolan_GetComputerName(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(GetComputerName);
end;

function nakolan_LanEnumDomain(args: DWORD): PHiValue; stdcall;
begin
  Result := hi_newStr(LanEnumDomain);
end;

function nakolan_LanEnumComputer(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) 引数の取得
  a := nako_getFuncArg(args, 0);
  if a = nil then
  begin
    Result := hi_newStr(LanEnumComputer('',True));
  end else
  begin
    Result := hi_newStr(LanEnumComputer(hi_str(a),True));
  end;
end;

function nakolan_LanEnumCommonDir(args: DWORD): PHiValue; stdcall;
var
  a: PHiValue;
begin
  // (1) 引数の取得
  a := nako_getFuncArg(args, 0);
  Result := hi_newStr(LanGetCommonResource(hi_str(a)));
end;

function nakolan_WNetAddConnection2(args: DWORD): PHiValue; stdcall;
var
  drv, dir, pass, user: string;
begin
  Result := nil;
  drv := getArgStr(args, 0, True);
  dir := getArgStr(args, 1);
  user:= getArgStr(args, 2);
  pass:= getArgStr(args, 3);
  //
  drv := Trim(drv);
  drv := UpperCase(Copy(drv,1,1)) + ':';
  dir := ExcludeTrailingPathDelimiter(dir);
  //

  try
    if user = '' then
      AddNetworkDrive(PChar(drv), PChar(dir), nil)
    else
      AddNetworkDrive(PChar(drv), PChar(dir), nil,PChar(pass),Pchar(user));
  except
    on e: Exception do
      raise Exception.Create(Format('"%s"へ"%s"を割り当てできませんでした。' + e.Message,[drv,dir]));
  end;
end;

function nakolan_WNetCancelConnection2(args: DWORD): PHiValue; stdcall;
var
  drv:String;
begin
  Result := nil;
  drv := getArgStr(args, 0, True);
  drv := UpperCase(Copy(drv,1,1)) + ':';
  if WNetCancelConnection2(Pchar(drv),0,False) <> NO_ERROR then
    raise Exception.Create(Format('"%s"の割り当てを解除できませんでした。' + GetLastErrorStr,[drv]));
end;


procedure RegistFunction;
begin
  //<命令>
  //+LAN(nakolan.dll)
  //-コンピューター情報
  AddFunc  ('ユーザー名取得','', 630, nakolan_getUserName,'ログオンユーザー名を返す。','ゆーざーめいしゅとく');
  AddFunc  ('コンピューター名取得','', 631, nakolan_getComputerName,'コンピューターの共有名を返す','こんぴゅーたーめいしゅとく');
  //-LAN共有コンピューター情報
  AddFunc  ('ドメイン列挙','', 632, nakolan_LanEnumDomain,'LAN上のドメインを列挙して返す。','どめいんれっきょ');
  AddFunc  ('コンピューター列挙','{=?}DOMAINの', 633, nakolan_LanEnumComputer,'LAN上のDOMAINに属するコンピューターを列挙して返す。','こんぴゅーたーれっきょ');
  AddFunc  ('共有フォルダ列挙','{=?}COMの', 634, nakolan_LanEnumCommonDir,'LAN上のCOMの共有フォルダを列挙して返す。','きょうゆうふぉるだれっきょ');
  AddFunc  ('ネットワークドライブ接続','AにBの{=「」}USERと{=「」}PASSで|AへBを', 635, nakolan_WNetAddConnection2,'ドライブAにネットワークフォルダBを割り当てる。接続ユーザ名USERとパスワードPASSは省略可能。','ねっとわーくどらいぶせつぞく');
  AddFunc  ('ネットワークドライブ切断','Aの|Aを', 636, nakolan_WNetCancelConnection2,'ドライブAに割り当てられたネットワークフォルダを切断する。','ねっとわーくどらいぶせつだん');
  //</命令>
end;

end.
