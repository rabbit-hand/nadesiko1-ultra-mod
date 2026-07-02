unit SFunc;

//**************************************************
//*  自作汎用関数ライブラリ                        *
//*                                                *
//*                               2001/07/04 改変  *
//*                                                *
//*     (c) CopyRight tarquin All Rights Reserved  *
//**************************************************

{$I taki.inc}

interface

uses
 Windows, SysUtils;

//**********************************************
//               ＯＳ依存定義
//
// コンパイル環境に合わせて変更してください。
// なお、RGBピクセルの並びはWindows標準のBGRの
// 順になっています。
//**********************************************

const
 GLDNONECOLOR = DWORD(-1);

 // 色要素の順番(TGLDPixRGByyと同じに！)
 GLDCorRed    = 2;
 GLDCorGreen  = 1;
 GLDCorBlue   = 0;
 GLDCorReserv = 3;

 GLDRMask15   = $7C00;
 GLDGMask15   = $3E0;
 GLDBMask15   = $1F;

 GLDRMask16   = $F800;
 GLDGMask16   = $7E0;
 GLDBMask16   = $1F;

type
{$IFDEF DEL2}
 PRGBTRIPLE=^TRGBTRIPLE;
{$ENDIF}

 PArrayPalEntry=^TArrayPalEntry;
 TArrayPalEntry=array [0..$FFFFFF] of TPALETTEENTRY;

 PArrayCoreRGB=^TArrayCoreRGB;
 TArrayCoreRGB=array [0..$FFFFFF] of TRGBTRIPLE;

 PArrayRGBQUAD=^TArrayRGBQUAD;
 TArrayRGBQUAD=array [0..$FFFFFF] of TRGBQUAD;

 TPALETTE256=record
   palVersion:    word;
   palNumEntries: word;
   palPalEntry:   array [0..255] of TPALETTEENTRY;
 end;

 // パレットカラーデータ定義
 PGLDPalRGB=^TGLDPalRGB;
 TGLDPalRGB=packed record
  rgbBlue,rgbGreen,rgbRed,rgbReserved: byte;
 end;

 // RGB(24bit)ピクセルデータ定義
 PGLDPixRGB24=^TGLDPixRGB24;
 TGLDPixRGB24=packed record
  rgbBlue,rgbGreen,rgbRed: byte;
 end;

 // RGB(32bit)ピクセルデータ定義
 PGLDPixRGB32=^TGLDPixRGB32;
 TGLDPixRGB32=packed record
  rgbBlue,rgbGreen,rgbRed,rgbReserved: byte;
 end;


//**********************************************
//               ＯＳ非依存定義
//**********************************************

type
 PArrayRect = ^TArrayRect;
 TArrayRect = array[0..9999999] of TRect;

 PArrayRGB=^TArrayRGB;
 TArrayRGB=array [0..100000] of TGLDPalRGB;

 PArrayByte=^TArrayByte;
 TArrayByte=array [0..9999999] of byte;

 PArrayChar=^TArrayChar;
 TArrayChar=array [0..9999999] of char;

 PArraySmallint=^TArraySmallint;
 TArraySmallint=array [0..9999999] of smallint;

 PArrayWord=^TArrayWord;
 TArrayWord=array [0..9999999] of word;

 PArrayLongint=^TArrayLongint;
 TArrayLongint=array [0..9999999] of longint;

 PArrayDWord=^TArrayDWord;
 TArrayDWord=array [0..9999999] of DWORD;

 PArrayDouble=^TArrayDouble;
 TArrayDouble=array [0..99999999] of double;

const
 abs256tbl: array [0..511] of byte=(
             $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f,
             $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f,
             $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f,
             $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f,
             $40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f,
             $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$5b,$5c,$5d,$5e,$5f,
             $60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f,
             $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$7b,$7c,$7d,$7e,$7f,
             $80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$8a,$8b,$8c,$8d,$8e,$8f,
             $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9a,$9b,$9c,$9d,$9e,$9f,
             $a0,$a1,$a2,$a3,$a4,$a5,$a6,$a7,$a8,$a9,$aa,$ab,$ac,$ad,$ae,$af,
             $b0,$b1,$b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9,$ba,$bb,$bc,$bd,$be,$bf,
             $c0,$c1,$c2,$c3,$c4,$c5,$c6,$c7,$c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf,
             $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7,$d8,$d9,$da,$db,$dc,$dd,$de,$df,
             $e0,$e1,$e2,$e3,$e4,$e5,$e6,$e7,$e8,$e9,$ea,$eb,$ec,$ed,$ee,$ef,
             $f0,$f1,$f2,$f3,$f4,$f5,$f6,$f7,$f8,$f9,$fa,$fb,$fc,$fd,$fe,$ff,

             $00,$ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8,$f7,$f6,$f5,$f4,$f3,$f2,$f1,
             $f0,$ef,$ee,$ed,$ec,$eb,$ea,$e9,$e8,$e7,$e6,$e5,$e4,$e3,$e2,$e1,
             $e0,$df,$de,$dd,$dc,$db,$da,$d9,$d8,$d7,$d6,$d5,$d4,$d3,$d2,$d1,
             $d0,$cf,$ce,$cd,$cc,$cb,$ca,$c9,$c8,$c7,$c6,$c5,$c4,$c3,$c2,$c1,
             $c0,$bf,$be,$bd,$bc,$bb,$ba,$b9,$b8,$b7,$b6,$b5,$b4,$b3,$b2,$b1,
             $b0,$af,$ae,$ad,$ac,$ab,$aa,$a9,$a8,$a7,$a6,$a5,$a4,$a3,$a2,$a1,
             $a0,$9f,$9e,$9d,$9c,$9b,$9a,$99,$98,$97,$96,$95,$94,$93,$92,$91,
             $90,$8f,$8e,$8d,$8c,$8b,$8a,$89,$88,$87,$86,$85,$84,$83,$82,$81,
             $80,$7f,$7e,$7d,$7c,$7b,$7a,$79,$78,$77,$76,$75,$74,$73,$72,$71,
             $70,$6f,$6e,$6d,$6c,$6b,$6a,$69,$68,$67,$66,$65,$64,$63,$62,$61,
             $60,$5f,$5e,$5d,$5c,$5b,$5a,$59,$58,$57,$56,$55,$54,$53,$52,$51,
             $50,$4f,$4e,$4d,$4c,$4b,$4a,$49,$48,$47,$46,$45,$44,$43,$42,$41,
             $40,$3f,$3e,$3d,$3c,$3b,$3a,$39,$38,$37,$36,$35,$34,$33,$32,$31,
             $30,$2f,$2e,$2d,$2c,$2b,$2a,$29,$28,$27,$26,$25,$24,$23,$22,$21,
             $20,$1f,$1e,$1d,$1c,$1b,$1a,$19,$18,$17,$16,$15,$14,$13,$12,$11,
             $10,$0f,$0e,$0d,$0c,$0b,$0a,$09,$08,$07,$06,$05,$04,$03,$02,$01 );


 // ビット操作データテーブル

const
 BitOr: array [0..31] of DWORD=(
         $00000001,$00000002,$00000004,$00000008,
         $00000010,$00000020,$00000040,$00000080,
         $00000100,$00000200,$00000400,$00000800,
         $00001000,$00002000,$00004000,$00008000,
         $00010000,$00020000,$00040000,$00080000,
         $00100000,$00200000,$00400000,$00800000,
         $01000000,$02000000,$04000000,$08000000,
         $10000000,$20000000,$40000000,$80000000 );

 BitROr: array [0..7] of DWORD=(
         $80,$40,$20,$10,$8,$4,$2,$1 );

 BitAnd: array [0..31] of DWORD=(
         $FFFFFFFE,$FFFFFFFD,$FFFFFFFB,$FFFFFFF7,
         $FFFFFFEF,$FFFFFFDF,$FFFFFFBF,$FFFFFF7F,
         $FFFFFEFF,$FFFFFDFF,$FFFFFBFF,$FFFFF7FF,
         $FFFFEFFF,$FFFFDFFF,$FFFFBFFF,$FFFF7FFF,
         $FFFEFFFF,$FFFDFFFF,$FFFBFFFF,$FFF7FFFF,
         $FFEFFFFF,$FFDFFFFF,$FFBFFFFF,$FF7FFFFF,
         $FEFFFFFF,$FDFFFFFF,$FBFFFFFF,$F7FFFFFF,
         $EFFFFFFF,$DFFFFFFF,$BFFFFFFF,$7FFFFFFF );

 BitRAnd: array [0..7] of DWORD=(
         $FFFFFF7F,$FFFFFFBF,$FFFFFFDF,$FFFFFFEF,
         $FFFFFFF7,$FFFFFFFB,$FFFFFFFD,$FFFFFFFE );

 BitBAnd: array [0..32] of DWORD=(
         $00000000,$00000001,$00000003,$00000007,
         $0000000F,$0000001F,$0000003F,$0000007F,
         $000000FF,$000001FF,$000003FF,$000007FF,
         $00000FFF,$00001FFF,$00003FFF,$00007FFF,
         $0000FFFF,$0001FFFF,$0003FFFF,$0007FFFF,
         $000FFFFF,$001FFFFF,$003FFFFF,$007FFFFF,
         $00FFFFFF,$01FFFFFF,$03FFFFFF,$07FFFFFF,
         $0FFFFFFF,$1FFFFFFF,$3FFFFFFF,$7FFFFFFF,
         $FFFFFFFF );


// 汎用関数
function  GetLongFileName(s:string):string;

function  FixMul(a,b: integer): integer; register;
function  CheckRect(x1,y1,w1,h1,x2,y2,w2,h2: integer): boolean;
function  CmpTime(now,past: DWORD): DWORD;
function  Sgn(i: integer): integer;
function  Max(a,b: integer): integer;
function  Min(a,b: integer): integer;
procedure Xchange(var i,j: longint);

function  GetNearestPaletteColor(hpal: HPALETTE; RGB: COLORREF): COLORREF;
function  GetNearestPaletteIndex(hpal: HPALETTE; RGB: COLORREF): integer;
function  GetNearestPaletteEntryIndex(pp: PPaletteEntry; RGB: COLORREF; maxno: integer): integer;
function  GetNearestColorTableIndex(pp: PGLDPalRGB; RGB: COLORREF; maxno: integer): integer;
procedure ClearSystemPalette;
function  CreatePaletteHandle(pp: PGLDPalRGB; len: integer): HPALETTE;
function  GetPaletteColorTable(hpal: HPALETTE; pp: PGLDPalRGB): integer;
function  GetPaletteColor(hpal: HPALETTE; idx: integer): COLORREF;
function  CreateGrayScalePalette(pp: PGLDPalRGB; bcnt: integer): integer;

function  GetMaxColor(pp: PBITMAPINFOHEADER): integer;
function  GetMaxColorSub(bcount: integer): integer;

function  GetLineSize(w,bcnt: integer): integer;
function  GetDIBMemLen(lx,ly,bcnt: integer): integer;
function  SwapBR(cor: DWORD): DWORD;
function  GetMaskShift(Mask: longint): integer;
procedure CopyPixelLine(pd,ps: pbyte; sourcebcnt,startx,pixlen: integer);
function  ConvertInchToMeter(n: integer): integer;

procedure DrawBitmapHandle(dc: HDC; dx,dy: integer; hbmp: HBITMAP; sx,sy,w,h,rop: integer);

procedure DebugMes(mes: string);


implementation


//*********************************************************
//    汎用関数
//*********************************************************


//------- CmpTime => タイム差分を求める


function CmpTime(now,past: DWORD): DWORD;
(*
//D4以上専用パスカルコード
begin
 if (now>=past) then
  result:=now-past
 else
  {$O-}
  result:=((now-past)+$FFFFFFFF)+1;
  {$O+}
end;
*)
asm
 cmp eax,edx
 jge @safe
 sub eax,edx
 add eax,$FFFFFFFF
 inc eax
 jmp @end
@safe:
 sub eax,edx
@end:
end;


//------- DrawBitmapHandle => BITMAPハンドルだけで表示


procedure DrawBitmapHandle(dc: HDC; dx,dy: integer; hbmp: HBITMAP; sx,sy,w,h,rop: integer);
var
 hmemdc: HDC;
 oldbmp: HBITMAP;

begin
 oldbmp:=0;
 hmemdc:=CreateCompatibleDC(0);
 try
  oldbmp:=SelectObject(hmemdc,hbmp);
  BitBlt(dc,dx,dy,w,h,hmemdc,sx,sy,rop);
 finally
  if oldbmp<>0 then SelectObject(hmemdc,oldbmp);
  DeleteDC(hmemdc);
 end;
end;


//------- GetLongFileName => 短いファイル名を長いファイル名に


function GetLongFileName(s: string): string;
var
 t:TSearchRec;
 r:integer;

begin
 r:=FindFirst(s,faAnyFile,t);
 Result:=ExtractFilePath(s)+t.FindData.cFileName;
 SysUtils.FindClose(t);
end;


//------- CheckRect => ２つの四角形のあたり判定


function CheckRect(x1,y1,w1,h1,x2,y2,w2,h2: integer): boolean;
begin
 result:=(x2<=x1+w1) and (x1<=x2+w2) and (y2<=y1+h1) and (y1<=y2+h2);
end;


//------- FixMul => (a*b shr 16)


function FixMul(a,b: integer): integer; register;
asm
 imul edx
 shrd eax,edx,16
end;


//------- ConvertInchToMeter => インチ単位をメータ単位に直す


function ConvertInchToMeter(n: integer): integer;
begin
 result:=Trunc((n*10000)/254)
end;


//------- GetMaskShift => マスクシフト数を求める


function GetMaskShift(Mask: longint): integer;
begin
 result := 0;
 // Mask が $100 以上なら 右シフト量を求める
 while Mask>=256 do
 begin
  Mask:=Mask shr 1;
  Inc(result);
 end;

 // Mask が $80 未満なら 左シフト量を求める（マイナス値）
 while Mask<128 do
 begin
  Mask:=Mask shl 1;
  Dec(result);
 end;
end;


//------- CopyPixelLine => ピクセルデータをコピーする
// (部分用です。また送受共同じピクセル専用です）
// (psにはライン先頭のポインタを入れてください)


procedure CopyPixelLine(pd,ps: pbyte; sourcebcnt,startx,pixlen: integer);
var
 sbcnt,dbcnt,s,d,i: integer;

begin
 // ピクセル開始位置までポインタ加算
 Inc(ps,(startx*sourcebcnt) shr 3);
 case sourcebcnt of
   1:  begin
        sbcnt:=BitOr[7-(startx and 7)];
        dbcnt:=$80;
        s:=ps^;
        d:=0;
        for i:=1 to pixlen do
        begin
         if (sbcnt and s)<>0 then d:=d or dbcnt;
         dbcnt:=dbcnt shr 1;
         sbcnt:=sbcnt shr 1;
         if dbcnt=0 then
          begin
           dbcnt:=$80;
           pd^:=d;
           Inc(pd);
           d:=0;
          end;
         if sbcnt=0 then
          begin
           sbcnt:=$80;
           s:=ps^;
           Inc(ps);
          end;
        end;
        if dbcnt<>$80 then pd^:=d;
       end;
   4:  begin
        sbcnt:=StartX and 1;
        dbcnt:=0;
        s:=ps^;
        d:=0;
        for i:=1 to pixlen do
        begin
         if sbcnt<>0 then
          if dbcnt<>0 then
           d:=d or (s and $0F)
          else
           d:=d or ((s and $0F) shl 4)
         else
          if dbcnt<>0 then
           d:=d or ((s and $F0) shr 4)
          else
           d:=d or (s and $F0);
         if dbcnt<>0 then
          begin
           dbcnt:=0;
           pd^:=d;
           Inc(pd);
           d:=0;
          end
         else
          dbcnt:=1;
         if sbcnt<>0 then
          begin
           sbcnt:=0;
           Inc(ps);
           s:=ps^;
          end
         else
          sbcnt:=1;
        end;
        if dbcnt<>0 then pd^:=d;
       end;
   8:  Move(ps^,pd^,pixlen);
   24: Move(ps^,pd^,pixlen*3);
   32: Move(ps^,pd^,pixlen*4);
 end;
end;


//------- SwapBR => BとRを交換する


function SwapBR(cor: DWORD): DWORD;
begin
 result:=((cor and $FF) shl 16)+(cor and $FF00)+((cor and $FF0000) shr 16);
end;


//------- GetLineSize => ラインバイト数を返す


function GetLineSize(w,bcnt: integer): integer;
begin
 result:=(((w*bcnt+7) shr 3)+3) and (not 3);
end;


//------- GetDIBMemLen => DIBのバイトサイズ計算


function GetDIBMemLen(lx,ly,bcnt: integer): integer;
begin
 result:=Abs(ly)*GetLineSize(lx,bcnt);
end;


//------- SGN => SGN関数(basicと同じ)


function Sgn(i: integer): integer; assembler;
asm
  cmp	eax,0
  jz    @zero
  jc    @small
@large:
  mov	eax,1
  jmp	@procend

@zero:
  sub	eax,eax
  jmp	@procend

@small:
  mov	eax,$FFFFFFFF
@procend:
end;


//------- XChange => 入れ替え


procedure Xchange(var i,j: longint);  assembler;
asm
 mov      ecx,[eax]
 xchg     ecx,[edx]
 mov      [eax],ecx
end;


//------- Min => 最小を返す


function Min(a,b: integer): integer;
begin
 if a<b then
  result:=a
 else
  result:=b;
end;


//------- Max => 最大を返す


function Max(a,b: integer): integer;
begin
 if a>b then
  result:=a
 else
  result:=b;
end;


//------- GetNearestColorTableIndex => １番近いパレット番号を返す(カラーテーブル用)


function GetNearestColorTableIndex(pp: PGLDPalRGB; RGB: COLORREF; maxno: integer): integer;
var
 i,maxn,palno,n: integer;
 R,G,B: integer;

begin
 R:=RGB and $FF;
 G:=(RGB shr 8) and $FF;
 B:=(RGB shr 16) and $FF;

 i:=0;
 palno:=0;
 maxn:=256*256*256;
 while (i<maxno) do
 begin
  n:= Abs256TBL[(pp^.rgbBlue -B) and 511]
     +Abs256TBL[(pp^.rgbRed  -R) and 511]
     +Abs256TBL[(pp^.rgbGreen-G) and 511];
  if n=0 then
   begin
    result:=i;
    Exit;
   end
  else
   if maxn>n then
    begin
     palno:=i;
     maxn:=n;
    end;
  Inc(pp);
  Inc(i);
 end;
 result:=palno;
end;


//------- GetNearestPaletteEntryIndex => １番近いパレット番号を返す(パレットエントリ用)


function GetNearestPaletteEntryIndex(pp: PPaletteEntry; RGB: COLORREF; maxno: integer): integer;
var
 i,maxn,palno,n: integer;
 R,G,B: integer;

begin
 R:=RGB and $FF;
 G:=(RGB shr 8) and $FF;
 B:=(RGB shr 16) and $FF;

 i:=0;
 palno:=0;
 maxn:=256*256*256;
 while (i<maxno) do
 begin
  n:= Abs256TBL[(pp^.peBlue -B) and 511]
     +Abs256TBL[(pp^.peRed  -R) and 511]
     +Abs256TBL[(pp^.peGreen-G) and 511];
  if n=0 then
   begin
    result:=i;
    Exit;
   end
  else
   if maxn>n then
    begin
     palno:=i;
     maxn:=n;
    end;
  Inc(pp);
  Inc(i);
 end;
 result:=palno;
end;


//------- GetNearestPaletteIndex => １番近いパレット番号を返す(パレットハンドル用：Index型)


function GetNearestPaletteIndex(hpal: HPALETTE; RGB: COLORREF): integer;
var
 palety: array [0..255] of TPALETTEENTRY;
 len: integer;

begin
 len:=GetPaletteEntries(hpal,0,256,palety);
 if len>0 then
  result:=SFunc.GetNearestPaletteEntryIndex(PPALETTEENTRY(@palety),RGB,len)
 else
  result:=-1;
end;


//------- GetNearestPaletteColor => １番近いパレット番号を返す(パレットハンドル用：COLORREF型)


function GetNearestPaletteColor(hpal: HPALETTE; RGB: COLORREF): COLORREF;
var
 palety: array [0..255] of TPALETTEENTRY;
 len,n: integer;

begin
 len:=GetPaletteEntries(hpal,0,256,palety);
 if len>0 then
  begin
   n:=SFunc.GetNearestPaletteEntryIndex(PPALETTEENTRY(@palety),RGB,len);
   result:=(palety[n].peBlue shl 16)+(palety[n].peGreen shl 8)+palety[n].peRed;
  end
 else
  result:=COLORREF(-1);
end;


//------- CreatePaletteHandle => カラーテーブルからパレットハンドル作成


function CreatePaletteHandle(pp: PGLDPalRGB; len: integer): HPALETTE;
var
 LOGPAL256:  TPalette256;
 i: integer;

begin
 LogPal256.palVersion:=$300;
 LogPal256.palNumEntries:=len;
 for i:=0 to Pred(len) do
 begin
  LogPal256.palPalEntry[i].peRed  :=PArrayRGB(pp)^[i].rgbRed;
  LogPal256.palPalEntry[i].peGreen:=PArrayRGB(pp)^[i].rgbGreen;
  LogPal256.palPalEntry[i].peBlue :=PArrayRGB(pp)^[i].rgbBlue;
  LogPal256.palPalEntry[i].peFlags:=0;
 end;
 result:=CreatePalette(PLogPalette(@LogPal256)^);
end;


//------- GetPaletteColor => パレットハンドルから指定色抜き取り


function GetPaletteColor(hpal: HPALETTE; idx: integer): COLORREF;
var
 palety: TPALETTEENTRY;

begin
 if GetPaletteEntries(hpal,idx,1,palety)>0 then
  result:=(palety.peBlue shl 16)+(palety.peGreen shl 8)+palety.peRed
 else
  result:=COLORREF(-1);
end;


//------- GetPaletteColorTable => パレットハンドルから全色抜き


function GetPaletteColorTable(hpal: HPALETTE; pp: PGLDPalRGB): integer;
var
 LOGPAL256:  TPalette256;
 i: integer;

begin
 result:=GetPaletteEntries(hpal,0,256,TPALETTEENTRY(LOGPAL256.palPalEntry[0]));
 if result>0 then
  for i:=0 to Pred(result) do
  begin
   PArrayRGB(pp)^[i].rgbRed    :=LogPal256.palPalEntry[i].peRed;
   PArrayRGB(pp)^[i].rgbGreen  :=LogPal256.palPalEntry[i].peGreen;
   PArrayRGB(pp)^[i].rgbBlue   :=LogPal256.palPalEntry[i].peBlue;
   PArrayRGB(pp)^[i].rgbReserved:=0;
  end;
end;


//------- CreateGrayScalePalette => グレイスケールパレット作成


function CreateGrayScalePalette(pp: PGLDPalRGB; bcnt: integer): integer;
var
 i,len,cinc,cor: integer;

begin
 case bcnt of
  1: begin
      cinc:=$FF;
      len:=1;
     end;
  2: begin
      cinc:=$55;
      len:=3;
     end;
  4: begin
      cinc:=$11;
      len:=15;
     end;
 else
  begin
   cinc:=1;
   len:=255;
  end;                 
 end;
 cor:=0;
 for i:=0 to len do
 begin
  pp^.rgbBlue    :=cor;
  pp^.rgbGreen   :=cor;
  pp^.rgbRed     :=cor;
  pp^.rgbReserved:=0;
  Inc(cor,cinc);
  Inc(pp);
 end;
 result:=len+1;
end;


//------- ClearSystemPalette => システムパレットクリア


procedure ClearSystemPalette;
var
 LOGPAL256:  TPalette256;
 i: integer;
 dc,hpal: THANDLE;

begin
 LogPal256.palVersion:=$300;
 LogPal256.palNumEntries:=256;
 for i:=0 to 255 do
 begin
  LogPal256.palPalEntry[i].peRed  :=0;
  LogPal256.palPalEntry[i].peGreen:=0;
  LogPal256.palPalEntry[i].peBlue :=0;
  LogPal256.palPalEntry[i].peFlags:=PC_NOCOLLAPSE;
 end;
 hpal:=CreatePalette(PLogPalette(@LogPal256)^);
 dc:=GetDC(0);
 hpal:=SelectPalette(dc,hpal,FALSE);
 RealizePalette(dc);
 hpal:=SelectPalette(dc,hpal,TRUE);
 ReleaseDC(0,dc);
 DeleteObject(hpal);
end;


//------- GetMaxColorSub => 最大パレットカラーを返す１


function GetMaxColorSub(bcount: integer): integer;
begin
 if bcount>8 then result:=0 else result:=1 shl bcount;
end;


//------- GetMaxColor => 最大パレットカラーを返す２


function GetMaxColor(pp: PBITMAPINFOHEADER): integer;
begin
 with pp^ do
 begin
  if biClrUsed=0 then
   result:=GetMaxColorSub(bibitcount)
  else
   result:=biClrUsed;
 end;
end;


//------- DebugMes => デバッグ用ダイヤログ表示


procedure DebugMes(mes: string);
begin
 MessageBoxEX(0,pchar(mes),'デバッグ中',
              MB_SYSTEMMODAL or MB_OK or MB_DEFBUTTON1,LANG_JAPANESE);
end;

end.
