library misc1;

uses
  FastMM4 in 'FastMM4.pas',
  Windows, SysUtils, Classes,
  unit_string in 'hi_unit\unit_string.pas',
  hima_types in 'hi_unit\hima_types.pas',
  mt19937 in 'hi_unit\mt19937.pas',

  dll_plugin_helper in 'hi_unit\dll_plugin_helper.pas',
  dnako_import in 'hi_unit\dnako_import.pas',
  dnako_import_types in 'hi_unit\dnako_import_types.pas',
  StrUnit in 'hi_unit\strunit.pas',
  CsvUtils2 in 'vnako_unit\CsvUtils2.pas',
  wildcard in 'hi_unit\wildcard.pas';

//------------------------------------------------------------------------------
function csv_keisen(h: DWORD): PHiValue; stdcall;
var
  csv: TCsvSheet;
begin
  csv := TCsvSheet.Create;
  try
    csv.AsText := getArgStr(h, 0, True);
    Result := hi_newStr( csv.KeisenText );
  finally
    csv.Free;
  end;
end;

function csv_htmltag(h: DWORD): PHiValue; stdcall;
var
  csv: TCsvSheet;
begin
  csv := TCsvSheet.Create;
  try
    csv.AsText := getArgStr(h, 0, True);
    Result := hi_newStr( csv.OutHtmlTable(getArgStr(h, 1)) );
  finally
    csv.Free;
  end;
end;

function csv_getUniqId(h: DWORD): PHiValue; stdcall;
var
  csv: TCsvSheet;
  i, v, max, idx: Integer;
begin
  csv := TCsvSheet.Create;
  try
    csv.AsText  := getArgStr(h, 0, True);
    idx         := getArgInt(h, 1);
    max := 1;
    for i := 0 to csv.Count - 1 do
    begin
      v := StrToIntDef(csv.Cells[idx, i], 0);
      if v > max then max := v;
    end;
    Result := hi_newInt(max + 1);
  finally
    csv.Free;
  end;
end;

//------------------------------------------------------------------------------
// Plug-in import function
procedure ImportNakoFunction; stdcall;
begin
  // 関数を追加する例
  AddFunc('表罫線括る','{=?}Sを|Sの', -1, csv_keisen, 'CSVデータSを与えると罫線で括って返す。','けいせんくくる');
  AddFunc('表テーブルタグ括る','{=?}SをAで', -1, csv_htmltag, 'CSVデータSに属性Aを与えてHTMLのテーブルタグで括って返す。','ひょうてーぶるたぐくくる');
  AddFunc('表ユニークID取得','{=?}SのAで', -1, csv_getUniqId, 'CSVデータSのA列目(0起点)に存在しないユニークなIDを返す。','ひょうゆにーくIDしゅとく');
end;

//------------------------------------------------------------------------------
// プラグインの情報
function PluginInfo(str: PChar; len: Integer): Integer; stdcall;
const STR_INFO = 'misc1 by クジラ飛行机';
begin
  Result := Length(STR_INFO);
  if (str <> nil)and(len > 0) then
  begin
    StrLCopy(str, STR_INFO, len);
  end;
end;

//------------------------------------------------------------------------------
// プラグインのバージョン
function PluginVersion: DWORD; stdcall;
begin
  Result := 1;
end;

//------------------------------------------------------------------------------
// なでしこプラグインバージョン
function PluginRequire: DWORD; stdcall;
begin
  Result := 1;
end;

exports
  ImportNakoFunction,
  PluginInfo,
  PluginVersion,
  PluginRequire;

begin
end.
