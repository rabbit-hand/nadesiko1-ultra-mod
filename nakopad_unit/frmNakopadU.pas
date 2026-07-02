unit frmNakopadU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ComCtrls, ToolWin, ImgList, ExtCtrls; 

type
  TFormMain = class(TForm)
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    EditMenu: TMenuItem;
    RunMenu: TMenuItem;
    Memo1: TRichEdit; // なでしこのエディタ画面
    StatusBar1: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
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

procedure TFormMain.Memo1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F1) and (ssCtrl in Shift) then
  begin
    Key := 0;
    StatusBar1.SimpleText := 'このビルドでは隠しAI支援機能は無効化されています。';
  end;
end;

end.
