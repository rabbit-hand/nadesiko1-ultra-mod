unit sMediaTag;
interface

uses
  Classes;

type
	TsMediaTag = class(TPersistent)
  protected
    FFileFormat: string;
  public
    ElseProp: TStringList;
		constructor Create(); virtual;
		destructor Destroy(); override;
		function ReadFromFile(const FileName: string): Boolean; virtual;
		function RemoveFromFile(const FileName: string): Boolean; virtual;
		function SaveToFile(const FileName: string): Boolean; virtual;
  published
    property FileFormat: string read FFileFormat;
	end;


implementation

constructor TsMediaTag.Create();
begin
	inherited Create();
  FFileFormat := 'unknown';
  ElseProp := TStringList.Create;
end;
destructor TsMediaTag.Destroy();
begin
  ElseProp.Free;
	inherited Destroy();
end;
{ ˆÈ‰º‚ÍŒp³æ‚ÅŒÄ‚Ô‚ÈB‚ ‚é‚¢‚ÍŒÄ‚ñ‚Å‚à‚¢‚¢‚¯‚Çæ“ª‚Å }
function TsMediaTag.ReadFromFile(const FileName: string): Boolean;
begin
	Result := False;
end;
function TsMediaTag.RemoveFromFile(const FileName: string): Boolean;
begin
	Result := False;
end;
function TsMediaTag.SaveToFile(const FileName: string): Boolean;
begin
	Result := False;
end;

end.
