unit nako_mod_secure_core;

interface

uses
  System.SysUtils, System.Classes, System.Threading, System.Net.HttpClient, 
  System.JSON, System.Hash, System.NetEncoding, dnako_import_types;

// なでしこ本体に登録する最新型関数
procedure Nako_SecureFetch(const URL: string; const JsonPayload: string; CallbackID: Integer);
function Nako_GetSHA256(const InputStr: string): string;

implementation

{ ⚡️ 最新セキュア非同期通信（メイン画面をフリーズさせない並列処理） }
procedure Nako_SecureFetch(const URL: string; const JsonPayload: string; CallbackID: Integer);
begin
  // メインスレッドから切り離してバックグラウンドのマルチスレッドで実行
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
        // 【現代の主流セキュリティ】TLS 1.2 および最新の TLS 1.3 通信を強制指定
        HTTP.SecureProtocols := [TSecureProtocol.Tls12, TSecureProtocol.Tls13];
        
        HTTP.ContentType := 'application/json';
        HTTP.CustomHeaders['Accept'] := 'application/json';

        // なでしこ(Shift_JIS)から届いた文字列を、Web標準のUTF-8に変換して送信
        if JsonPayload <> '' then
          RequestStream := TStringStream.Create(JsonPayload, TEncoding.UTF8);

        if RequestStream <> nil then
          Response := HTTP.Post(URL, RequestStream)
        else
          Response := HTTP.Get(URL);

        // レスポンス(UTF-8)をなでしこが読めるShift_JIS(CP932)へ自動コンバート
        ResponseBody := Response.ContentAsString(TEncoding.UTF8);
        S_SjisResult := TEncoding.GetEncoding(932).GetString(TEncoding.UTF8.GetBytes(ResponseBody));

        // 通信が終わったらメインスレッドへ安全に同期して結果を返す
        TThread.Synchronize(nil,
          procedure
          begin
            // TODO: ここでなでしこのグローバル変数「それ」や指定されたイベントに S_SjisResult を格納して発火
            // なでしこ内部の引数スタックやコールバック関数をキックする処理に繋げます
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
end;

{ 🔒 外部DLL不要のネイティブなSHA-256ハッシュ計算 }
function Nako_GetSHA256(const InputStr: string): string;
begin
  Result := THashSHA2.GetHashString(InputStr, THashSHA2.TSHA2Version.SHA256);
end;

end.
