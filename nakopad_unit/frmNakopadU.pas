unit frmNakopadU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ComCtrls, ToolWin, ImgList, ExtCtrls,
  System.Threading, System.Net.HttpClient, System.JSON, System.Hash, System.NetEncoding; // ★最新AIコアに必要なユニット

type
  TFormMain = class(TForm)
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    EditMenu: TMenuItem;
    RunMenu: TMenuItem;
    Memo1: TRichEdit; // なでしこのエディタ画面
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); // ★キー判定用
  private
    { Private declarations }
    procedure CallAiAssistant; // ★AI脳を呼び出す秘密の関数
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // なでしこエディタ初期化（既存の処理をそのまま維持）
  Application.Title := 'なでしこぱっど';
end;

{ ★見た目はそのまま、キーボードの「Ctrl + F1」で発動するAI診断脳 }
procedure TFormMain.Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // ユーザーが Ctrl + F1 を押したかチェック
  if (Key = VK_F1) and (ssCtrl in Shift) then
  begin
    Key := 0; // システムの標準挙動をパス
    CallAiAssistant; // AIアシスタント起動！
  end;
end;

procedure TFormMain.CallAiAssistant;
var
  CurrentCode: string;
begin
  CurrentCode := Memo1.Text;
  if Trim(CurrentCode) = '' then Exit;

  // ステータスバーでひっそり状況を伝える（見た目は汚さない）
  StatusBar1.SimpleText := 'AIがコードを確認しています...';

  // バックグラウンド並列処理（エディタを絶対にフリーズさせない）
  TTask.Run(
    procedure
    var
      HTTP: THTTPClient;
      Response: IHTTPResponse;
      RequestBody: TJSONObject;
      MessagesArray, MessageObj: TJSONArray;
      SystemPrompt: string;
      JsonStream: TStringStream;
      ResponseBody, AiReply: string;
      ResponseJson: TJSONObject;
      WrongPart, FixedCode: string;
      UserChoice: Integer;
    begin
      HTTP := THTTPClient.Create;
      RequestBody := TJSONObject.Create;
      JsonStream := nil;
      try
        HTTP.SecureProtocols := [TSecureProtocol.Tls12, TSecureProtocol.Tls13];
        HTTP.ContentType := 'application/json';
        // ★あなたのAPIキーをここにセット
        HTTP.CustomHeaders['Authorization'] := 'Bearer YOUR_AI_API_KEY'; 

        SystemPrompt := 'あなたは日本語プログラミング言語「なでしこv1」のメンターです。' +
                       '与えられたコードの間違いを指摘し、修正後のコードを次のJSON形式だけで返してください。' +
                       '{"wrong": "指摘内容", "fixed": "修正後の全コード"}';

        MessagesArray := TJSONArray.Create;
        MessageObj := TJSONObject.Create;
        MessageObj.AddPair('role', 'system');
        MessageObj.AddPair('content', SystemPrompt);
        MessagesArray.AddElement(MessageObj);

        MessageObj := TJSONObject.Create;
        MessageObj.AddPair('role', 'user');
        MessageObj.AddPair('content', CurrentCode);
        MessagesArray.AddElement(MessageObj);

        RequestBody.AddPair('model', 'gpt-4o-mini');
        RequestBody.AddPair('messages', MessagesArray);

        JsonStream := TStringStream.Create(RequestBody.ToString, TEncoding.UTF8);
        Response := HTTP.Post('https://api.openai.com/v1/chat/completions', JsonStream);
        
        ResponseBody := Response.ContentAsString(TEncoding.UTF8);
        ResponseJson := TJSONObject.ParseJSONValue(ResponseBody) as TJSONObject;
        
        if ResponseJson <> nil then
        begin
          AiReply := ResponseJson.Get('choices').JsonValue.AsType<TJSONArray>.Items[0].Get('message').JsonValue.AsType<TJSONObject>.Get('content').JsonValue.Value;
          with TJSONObject.ParseJSONValue(AiReply) as TJSONObject do
          begin
            WrongPart := TEncoding.GetEncoding(932).GetString(TEncoding.UTF8.GetBytes(Get('wrong').JsonValue.Value));
            FixedCode := TEncoding.GetEncoding(932).GetString(TEncoding.UTF8.GetBytes(Get('fixed').JsonValue.Value));
            Free;
          end;
          ResponseJson.Free;
        end;

        // エディタのメイン画面へ安全に結果を書き戻す
        TThread.Synchronize(nil,
          procedure
          begin
            StatusBar1.SimpleText := 'AIの確認が完了しました。';
            
            // ダイアログを出して確認（使い慣れたポップアップ形式）
            UserChoice := Windows.MessageBox(FormMain.Handle, 
              PChar('【AIからのアドバイス】' + #13#10 + WrongPart + #13#10#13#10 + 'この提案通りにコードを自動修正しますか？'), 
              'AIコード脳アシスタント', 
              MB_YESNO or MB_ICONINFORMATION);
              
            if UserChoice = IDYES then
            begin
              // エディタのテキストを書き換える
              Memo1.Text := FixedCode;
            end;
          end);

      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              StatusBar1.SimpleText := 'AI確認エラー。';
              Windows.MessageBox(FormMain.Handle, PChar('通信失敗: ' + E.Message), 'エラー', MB_OK or MB_ICONERROR);
            end);
        end;
      end;
      finally
        JsonStream.Free;
        RequestBody.Free;
        HTTP.Free;
      end;
    end
  );
end;

end.
