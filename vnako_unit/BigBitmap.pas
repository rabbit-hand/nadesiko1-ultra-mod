{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}

////////////
//
// TBigBitmap は大きなビットマップを Win95/98/ME
// で安全に保持するクラスです。
// TGraphic から継承しており、TBitmapと
// ほぼ同じ使い勝手にして有ります。
//
// TBigBitmap はビットマップを横に切って
// 複数に分割し 複数のTBitmapで保持します。
// Win95系列のWindowsの制限(64MB程度)
// に制限されないため数百メガバイトの大きな
// ビットマップを保持できます。
//
// TBigBitmapは描画の際 DrawMode=dmBanding ではAPI に
// よる拡大を4倍までにとどめます。足りない拡大は
// TBigBitmap内の Scanline を使った拡大用コードによって行います。
// このため、ビットマップの描画において
// 拡大率に事実上制限がありません。またこの処理では
// 小さなビットマップに拡大して描いてからそれを
// １～４倍でコピーすることで描画を行うため、メモリを
// あまり消費がすることなく描画が行えます。
// またこの描画はStretchDIBits
// で行われるため、プリンタに安全に印刷が
// 行えます。
//
// つまりTBigBitmapは巨大なビットマップを
// 安全に保持でき、それをどんな拡大率でも
// 安全に印刷／描画できます。


unit BigBitmap;

interface

uses
  Windows, SysUtils, Classes, Graphics;

type
  // TBigBitmap の例外
  EBigBitmapError = class(Exception);

  // TBigBitmap のPixelFormat プロパティの型
  TBigBitmapPixelFormat = (bbpf1bit, bbpf4bit, bbpf8bit, bbpf24bit);

  // TBigBitmap の DrawMode プロパティの型
  // dmUseStretchDraw: TBitmap の StretchDraw つまり StretchBlt API
  // 　で描く。信頼性は低いが早い
  // dmUseBanding: Scanline を使ってAPIを頼らず拡大縮小処理を行った後
  //    それを小さなビットマップに描き、それを描画する。
  //    拡大率に制限が無く、小さなビットマップを大きく拡大して
  //    印刷が可能。但し少々遅い
  TBigBitmapDrawMode    = (dmUseOriginalDraw, dmUseBanding);

  TBitmapArray = array of TBitmap;

  TBigBitmap = class;

  // TBigBitmap の Canvas. TCanvasから継承してはいない
  TBigBitmapCanvas = class
  private
    FBrush: TBrush;
    FFont: TFont;
    FPen: TPen;
    FTextFlags: Longint;
    FCopyMode: TCopyMode;
    FBigBitmap: TBigBitmap;

    {$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
    FClipRgn: HRGN;
    FCopyRectMode: Integer;
    {$ENDIF}

    procedure SetBrush(const Value: TBrush);
    procedure SetFont(const Value: TFont);
    procedure SetPen(const Value: TPen);

    procedure SetupBitmaps;  // 描画のため各ビットマップの
                             // 座標系その他を設定する。
    procedure ResetBitmaps;  // 座標系を元に戻す

    function GetPixel(X, Y: Integer): TColor;
    procedure SetPixel(X, Y: Integer; Value: TColor);

    {$IFNDEF ORIGINAL} // 2002/7/25 追加 DHGL 1.2
    procedure SetClipRgn(const Value: HRGN);
    procedure SetupClipRgn(Force: Boolean);
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;

    // TCanvas 互換メソッド
    procedure Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
    procedure BrushCopy(const Dest: TRect; Bitmap: TBitmap;
      const Source: TRect; Color: TColor);
    procedure Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
    procedure CopyRect(const Dest: TRect; Canvas: TCanvas;
      const Source: TRect); overload;
    procedure DrawFocusRect(const Rect: TRect);
    procedure Ellipse(X1, Y1, X2, Y2: Integer); overload;
    procedure Ellipse(const Rect: TRect); overload;
    procedure FillRect(const Rect: TRect);
    procedure FloodFill(X, Y: Integer; Color: TColor; FillStyle: TFillStyle);
    procedure FrameRect(const Rect: TRect);
    procedure LineTo(X, Y: Integer);

    procedure MoveTo(X, Y: Integer);
    procedure Pie(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
    procedure Polygon(const Points: array of TPoint);
    procedure Polyline(const Points: array of TPoint);
    procedure PolyBezier(const Points: array of TPoint);
    procedure PolyBezierTo(const Points: array of TPoint);
    procedure Rectangle(X1, Y1, X2, Y2: Integer); overload;
    procedure Rectangle(const Rect: TRect); overload;
    procedure RoundRect(X1, Y1, X2, Y2, X3, Y3: Integer);
    function TextExtent(const Text: string): TSize;
    function TextHeight(const Text: string): Integer;
    procedure TextOut(X, Y: Integer;
                      const Text: string);
    procedure TextRect(Rect: TRect; X, Y: Integer; const Text: string);
    function TextWidth(const Text: string): Integer;

    procedure Draw(X, Y: Integer; Graphic: TGraphic);
    procedure StretchDraw(const Rect: TRect; Graphic: TGraphic);

    {$IFNDEF ORIGINAL} //2002/7/25 新設 DHGL 1.2
    procedure CopyRect(Dest: TRect; Bitmap: TBigBitmap; Source: TRect); overload;
    {$ENDIF}

    // TCanvas 互換プロパティ
    property Font: TFont read FFont write SetFont;
    property Brush: TBrush read FBrush write SetBrush;
    property Pen: TPen read FPen write SetPen;
    property TextFlags: Longint read FTextFlags write FTextFlags;
    property CopyMode: TCopyMode read FCopyMode write FCopyMode
                                 default cmSrcCopy;
    property Pixels[X, Y: Integer]: TColor read GetPixel write SetPixel;

    {$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
    // クリップリージョンプロパティ 2002/7/25 新設 DHGL 1.2
    property ClipRgn: HRGN read FClipRgn write SetClipRgn;
    property CopyRectMode: Integer read FCopyRectMode write FCopyRectMode;
    {$ENDIF}
  end;

  // TBigBitmap の宣言
  TBigBitmap = class(TGraphic)
  private
    FBitmaps: TBitmapArray;              // TBitmap の配列
    FPixelFormat: TBigBitmapPixelFormat; // Pixel Format
    FWidth: Integer;                     // ビットマップの幅
    FHeight: Integer;                    // ビットマップの高さ
    FCanvas: TBigBitmapCanvas;           // TBigBitmap用Canvas
    FDrawMode: TBigBitmapDrawMode;       // 描画モード
    FPreview: Boolean;                   // プレビュー用モード

    {$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
    WorkAsCopyRect: Boolean;  // Draw を CopyRect のように
                              // 動かすフラグ
    {$ENDIF}
    // 全TBitmap を廃棄する
    procedure DiscardBitmaps;
    // 全TBitmap を作成する
    procedure SetupBitmaps(NewWidth, NewHeight: Integer;
                           NewPixelFormat: TBigBitmapPixelFormat);


    // プロパティアクセスメソッド
    function GetPixelBits(APixelFormat: TBigBitmapPixelFormat): Integer;

    procedure SetPixelFormat(const Value: TBigBitmapPixelFormat);

    function GetScanline(Index: Integer): Pointer;
    procedure SetDrawMode(const Value: TBigBitmapDrawMode);
    procedure SetPreview(Value: Boolean);
  protected
    // TGraphic 標準インターフェース
    function  GetWidth: Integer; override;
    function  GetHeight: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetWidth(Value: Integer); override;
    function  GetEmpty: Boolean; override;
    function  GetPalette: HPALETTE; override;
    procedure SetPalette(Value: HPALETTE); override;

    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;

    procedure AssignTo(Dest: TPersistent); override;
  public
    // TGraphic 標準インターフェース
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle;
      APalette: HPALETTE); override;
    procedure SaveToClipboardFormat(var AFormat: Word; var AData: THandle;
      var APalette: HPALETTE); override;

    constructor Create; override;
    destructor  Destroy; override;

    // 描画モード
    property PixelFormat: TBigBitmapPixelFormat read FPixelFormat
                                                write SetPixelFormat
                                                default bbpf8bit;
    // TBigBitmap の Canvas
    property Canvas: TBigBitmapCanvas read FCanvas;
    // Scanline : TBitmap互換
    property ScanLine[Index: Integer]: Pointer read GetScanline;
    // 描画モード
    property DrawMode: TBigBitmapDrawMode read FDrawMode
                                          write SetDrawMode
                                          default dmUseOriginalDraw;
    // プレビューモード
    property Preview: Boolean read FPreview write SetPreview;
  end;

  {$IFNDEF ORIGINAL} // 2002/7/28 DHGL 1.2
  procedure CopyRectBigBitmap(Dest: TRect; ACanvas: TCanvas;
                              Source: TRect; Bitmap: TBigBitmap);
  {$ENDIF}

procedure Register;

implementation

uses DIBUtils, ClipBrd;

procedure Register;
begin end;

procedure RaiseError(s: string);
begin
  raise EBigBitmapError.Create(s);
end;

// TBigBitmap 内の TBitmap の大きさの最大値
const MaxOneBitmapSize  = 1024*1024*8;
// TBigBitmap 内の TBitmap のScanline大きさの最大値
const MaxBitmapScanline = 65536-256;


type
  // TrueColor のビットマップデータアクセス用のレコード型です。
  // Scanline Property で TrueColor のデータをアクセスするときに便利です。
  TTriple = packed record
    B, G, R: Byte;
  end;
  TTripleArray = array[0..40000000] of TTriple;
  PTripleArray = ^TTripleArray;

  // DWORD 配列アクセス用の型。16bpp/32bpp 用
  TDWordArray = array[0..100000000] of DWORD;
  PDWordArray = ^TDWordArray;



{ TBigBitmap }

// TBigBitmap のコピー
procedure TBigBitmap.Assign(Source: TPersistent);
var
  i: Integer;
  Bitmaps: TBitmapArray;
  nBitmaps: Integer;
  Clip: TClipBoard;    // クリップボード
  AData: THandle;      // クリップボードのデータハンドル
  MS: TMemoryStream;
begin
  if Source is TBigBitmap then
  begin
    // 内部の TBitmap をコピーする
    nBitmaps := Length(TBigBitmap(Source).FBitmaps);
    SetLength(Bitmaps, nBitmaps);
    FillChar(Bitmaps[0], SizeOf(TBitmap) * nBitmaps, 0);
    try
      for i := 0 to nBitmaps-1 do
      begin
        Bitmaps[i] := TBitmap.Create;
        Bitmaps[i].Assign(TBigBitmap(Source).FBitmaps[i]);
      end
    except
      for i := 0 to nBitmaps-1 do
        Bitmaps[i].Free;
      raise;
    end;
    // TBitmap群を差し替える
    DiscardBitmaps;
    FBitmaps := Bitmaps;
    FWidth := TBigBitmap(Source).FWidth;
    FHeight := TBigBitmap(Source).FHeight;

    // 属性をコピーする
    FPixelFormat := TBigBitmap(Source).FPixelFormat;
    FDrawMode := TBigBitmap(Source).FDrawMode;

    PaletteModified := True;
    Modified := True; // OnChange
  end
  else if Source is TClipBoard then
  begin
    Clip := Source as TClipBoard;
    Clip.Open;
    try
      // クリップボードから ClipboardFormat 型のデータを取得
      AData := Clip.GetAsHandle(CF_DIB);
      // ここで、データが取得できたかのチェックはしない。
      // ADataと LoadFromClipboardFormat が行う。

      // データを押し込む
      LoadFromClipboardFormat(CF_DIB, AData, 0);
    finally
      Clip.Close;
    end;
  end
  else if Source is TBitmap then
  begin
    MS := TMemoryStream.Create;
    try
      (Source as TBitmap).SaveToStream(MS);
      MS.Position := 0;
      LoadFromStream(MS);
    finally
      MS.Free;
    end;
  end
  {$IFNDEF ORIGINAL} // 2002/7/25 追加 DHGL 1.2
  else if Source = Nil then
  begin
    Width := 0; Height := 0;
  end
  {$ENDIF}
  else
    inherited;
end;

procedure TBigBitmap.AssignTo(Dest: TPersistent);
var
  MS: TMemoryStream;
begin
  if Dest is TBitmap then
  begin
    MS := TMemoryStream.Create;
    try
      SaveToStream(MS);
      MS.Position := 0;
      (Dest as TBitmap).LoadFromStream(MS);
    finally
      MS.Free;
    end;
  end
  else
    inherited;
end;

constructor TBigBitmap.Create;
begin
  inherited;
  // 属性の初期値をセットし、Canvas を作る
  FPixelFormat := bbpf8bit;
  FDrawMode := dmUseOriginalDraw;
  FCanvas := TBigBitmapCanvas.Create;
  FCanvas.FBigBitmap := Self;
end;

destructor TBigBitmap.Destroy;
begin
  // Canvas と TBitmap群を破棄する
  FCanvas.Free;
  DiscardBitmaps;
  inherited;
end;

procedure TBigBitmap.DiscardBitmaps;
var
  i: Integer;
begin
  // TBigBitmap内の TBitmap群を全て破棄する
  for i := 0 to Length(FBitmaps)-1 do
    FBitmaps[i].Free;
  SetLength(FBitmaps, 0);
end;

procedure TBigBitmap.Draw(ACanvas: TCanvas; const Rect: TRect);
var
  i: Integer;

  // dmUseOriginalDraw 用
  SumOfHeights: Integer;     //各TBitmapの高さの積算
  NextHeight: Integer;       //次に描画すべき位置(高さ)

  // 共用
  w, h: Integer;             // 描画領域の幅と高さ(絶対値‘)

  // dmBanding 用
  Band: TBitmap;             // Banding用ビットマップ
  ScanlineLength: Integer;   // Banding用ビットマップのScanline長
  UsedBitmapWidth: Integer;  // Banding用ビットマップの中で実際に
  UsedBitmapHeight: Integer; //  使われている領域
  RestWidth: Integer;        // 最終的なZoomが行われる前の描画領域の未処理の幅
  RestHeight: Integer;       // 最終的なZoomが行われる前の描画領域の未処理の高さ
  //描画元とBanding用ビットマップのスキャンライン
  DestScan, SourceScan: Pointer;
  X, Y: Integer;             // Banding用ビットマップの座標
  Bits: Byte;                // ピクセルの値(bbpf4bit, bbpf1bit用)
  Index: Integer;            // 描画元ピクセルアクセス用インデックス
                             //  (bbpf4bit, bbpf1bit用)
  SepDIB: TSepDIB;           // Bandingビットマップを StretchDIBits するときの
                             // DIB情報
  pBits: Pointer;            // DIBのピクセルデータへのポインタ
  BPP: Integer;              // スクリーンのピクセルのビット数。
  XOrient, YOrient: Integer; // 描画領域の向き
  OldPalette: HPALETTE;      // パレットを選択する前のパレット

  ZoomFactorX,               // Banding ビットマップから Canvas への
  ZoomFactorY: Integer;      // Zoom Factor  1～4倍

  BandDrawWidth,             // Zoom 後のBanding ビットマップの
  BandDrawHeight: Integer;   //  「使用領域」の大きさ

  BandWidth,                 // Banding ビットマップの大きさのキャッシュ
  BandHeight: Integer;       //  プロパティにアクセスすると遅いのでここにいれる

  // バンドのインデックス。現在の Band が担当している領域の位置を表します。
  XBandIndex, YBandIndex: Integer;

  {$IFNDEF ORIGINAL} // 2002/7/27 挿入 DHGL 1.2
  ClipBox: TRect;            // 描画先のクリッピング矩形
  DestRect: TRect;           // バンドの描画エリア
  Temp: TRect;
  {$ENDIF}

  const MaxBandWidth  = 1024;// Band の最大の大きさ 32bpp で 4MB
        MaxBandHeight = 1024;
begin
  if Empty then Exit;

  {$IFNDEF ORIGINAL} // 2002/7/27 挿入 DHGL 1.2
  GetClipBox(ACanvas.Handle, ClipBox);
  {$ENDIF}

  Canvas.SetupBitmaps;  // 各ビットマップのCanvas を最新状態にアップデート
  Canvas.ResetBitmaps;  // 2002.2.3 追加

  // 各 TBitmap を描画先に StretchDraw で描画する
  if FDrawMode = dmUseOriginalDraw then // StretchDraw を使う
  begin
    // 描画領域の大きさを算出する
    w := Rect.Right - Rect.Left;
    h := Rect.Bottom - Rect.Top;

    if (w = 0) or (h = 0) then Exit;


    // TBitmap の Draw で小さなビットマップを描画する
    SumOfHeights := 0;
    for i := 0 to Length(FBitmaps)-1 do
    begin
      // 各TBitmapの描画位置を計算し描画する
      NextHeight := SumOfHeights + FBitmaps[i].Height;
      {$IFDEF ORIGINAL} // 2002/7/26 DHGL 1.2
      ACanvas.StretchDraw(
        Classes.Rect(Rect.Left,
                     Rect.Top + SumOfHeights * h div FHeight,
                     Rect.Right,
                     Rect.Top + NextHeight * h div FHeight),
        FBitmaps[i]);
      {$ELSE}
      if not WorkAsCopyRect then
        ACanvas.StretchDraw(
          Classes.Rect(Rect.Left,
                       Rect.Top + SumOfHeights * h div FHeight,
                       Rect.Right,
                       Rect.Top + NextHeight * h div FHeight),
          FBitmaps[i])
      else
        ACanvas.CopyRect(
          Classes.Rect(Rect.Left,
                       Rect.Top + SumOfHeights * h div FHeight,
                       Rect.Right,
                       Rect.Top + NextHeight * h div FHeight),
          FBitmaps[i].Canvas,
          Classes.Rect(0, 0, FBitmaps[i].Width, FBitmaps[i].Height));
      {$ENDIF}
      SumOfHeights := NextHeight;
    end;
  end
  // バンディングによる表示(印刷)
  else if FDrawMode = dmUseBanding then
  begin
    // 描画先の大きさの絶対値を得る
    w := abs(Rect.Right - Rect.Left);
    h := abs(Rect.Bottom - Rect.Top);

    if (w = 0) or (h = 0) then Exit;

    // ZoomFactor を決めます。大きな拡大率で大きな領域に
    // 印刷する時は 最終的な StretchDIBits による拡大率を
    // 4倍まで大きくします。これは印刷時にプリンタへ送る
    // データ量を激減させます。
    if      w < 256         then ZoomFactorX := 1
    else if FPreview        then ZoomFactorX := 4
    else if w <= FWidth     then ZoomFactorX := 1
    else if w >= FWidth * 4 then ZoomFactorX := 4
    else if w >= FWidth * 2 then ZoomFactorX := 2
    else                         ZoomFactorX := 1;

    if      h <= 256         then ZoomFactorY := 1
    else if FPreview         then ZoomFactorY := 4
    else if h <= FHeight     then ZoomFactorY := 1
    else if h >= FHeight * 4 then ZoomFactorY := 4
    else if h >= FHeight * 2 then ZoomFactorY := 2
    else                          ZoomFactorY := 1;


    // 描画先の向き得る。
    if Rect.Right > Rect.Left then XOrient := 1
                              else XOrient := -1;

    if Rect.Bottom > Rect.Top then YOrient := 1
                              else YOrient := -1;

    // まずBanding用ビットマップを作る
    Band := TBitmap.Create;
    try
      Band.PixelFormat := FBitmaps[0].PixelFormat;
      Band.Canvas.Font := Canvas.Font;    // 2002.2.3 追加
      Band.Canvas.Brush := Canvas.Brush;  // 2002.2.3 追加

      // 描画先が 1024 x 1024 以上にならないように大きさを決める
      BandWidth :=  MaxBandWidth div ZoomFactorX;
      BandHeight := MaxBandHeight div ZoomFactorY;
      Band.Width := BandWidth;
      Band.Height := BandHeight;

      // 後で拡大縮小処理のために Scanline 長を算出しておく
      ScanlineLength := (Band.Width * GetPixelBits(FPixelFormat) + 31) div 32 * 4;

      // パレットをコピーする
      Band.Palette := CopyPalette(Palette);

      {$IFDEF ORIGINAL} // 2002/7/26 DHGL 1.1
      // パレットを実体化する
      if Palette <> 0 then
      begin
        OldPalette := SelectPalette(ACanvas.Handle, Palette, True);
        RealizePalette(ACanvas.Handle);
      end;
      {$ELSE}
      if (Palette <> 0) and not WorkAsCopyRect then
      begin
        OldPalette := SelectPalette(ACanvas.Handle, Palette, True);
        RealizePalette(ACanvas.Handle);
      end;
      {$ENDIF}

      BPP := GetDeviceCaps(ACanvas.Handle, BITSPIXEL) *
             GetDeviceCaps(ACanvas.Handle, PLANES);

      // 描画先が8bpp以下で描画ものが 16bpp以上なら
      // Canvas をハーフトーンモードに設定する
      {$IFDEF ORIGINAL} // 2002/7/26 DHGL 1.2
      if (BPP <= 8) and
         not (Band.PixelFormat in [pf1bit, pf4bit, pf8bit]) then
        SetStretchBltMode(ACanvas.Handle, HALFTONE)
      else
        SetStretchBltMode(ACanvas.Handle, COLORONCOLOR);
      {$ELSE}
      if not WorkAsCopyRect then
        if (BPP <= 8) and
           not (Band.PixelFormat in [pf1bit, pf4bit, pf8bit]) then
          SetStretchBltMode(ACanvas.Handle, HALFTONE)
        else
          SetStretchBltMode(ACanvas.Handle, COLORONCOLOR);
      {$ENDIF}

      try
        RestWidth := w div ZoomFactorX; // Zoom 前の描画領域の幅を算出
        UsedBitmapWidth := Band.Width;  // Bandの使用領域の幅を初期化

        XBandIndex := 0;                // 表示の X 方向のループ
        while RestWidth > 0 do
        begin
          RestHeight := h div ZoomFactorY; // Zoom 前の描画領域の高さを算出
          UsedBitmapHeight := Band.Height; // Bandの使用領域の高さを初期化

          YBandIndex := 0;                 // 表示の Y 方向のループ
          while RestHeight > 0 do
          begin
            // Zoom前の表示領域の残に従ってビットマップの縦の使用領域を補正
            if RestHeight < UsedBitmapHeight then
              UsedBitmapHeight := RestHeight;


            {$IFNDEF ORIGINAL} // 2002/7/27 挿入}
            BandDrawWidth  := UsedBitmapWidth * ZoomFactorX;
            BandDrawHeight := UsedBitmapHeight * ZoomFactorY;

            // Zoom によって描画する場合、Canvas の描画先が最大 ZoomFactor-1
            // 余って描画されない領域が出来る。これを防ぐため微妙に
            // 拡大率を変える(1%程度)。
            if w - (Band.Width * XBandIndex * ZoomFactorX + BandDrawWidth) <
               ZoomFactorX then
              BandDrawWidth := w - Band.Width * XBandIndex * ZoomFactorX;
            if h - (Band.Height * YBandIndex * ZoomFactorY + BandDrawHeight) <
               ZoomFactorY then
              BandDrawHeight := h - Band.Height * YBandIndex * ZoomFactorY;

            // 描画先矩形を計算
            DestRect.Left := Rect.Left + Band.Width * XBandIndex *
                             ZoomFactorX * XOrient;
            DestRect.Top  := Rect.Top + Band.Height * YBandIndex *
                             ZoomFactorY * YOrient;

            // 描画先の大きさを境界座標で求める
            DestRect.Right := DestRect.Left + BandDrawWidth * XOrient;
            DestRect.Bottom := DestRect.Top + BandDrawHeight * YOrient;

            temp := DestRect;
            if DestRect.Left > DestRect.Right then
            begin
              DestRect.Left := Temp.Right + 1;
              DestRect.Right := Temp.Left + 1;
            end;
            if DestRect.Top > DestRect.Bottom then
            begin
              DestRect.Top := Temp.Bottom + 1;
              DestRect.Bottom := Temp.Top + 1;
            end;

            if IntersectRect(Temp, ClipBox, DestRect) then
            begin
            {$ENDIF}


              //　描画もとから Band への拡大縮小処理
              for Y := 0 to UsedBitmapHeight-1 do
              begin
                SourceScan := Scanline[(YBandIndex*BandHeight + y) *
                                       FHeight div (h  div ZoomFactorY)];
                DestScan := Band.Scanline[Y];
                FillChar(DestScan^, ScanLinelength, 0);

                if RestWidth < UsedBitmapWidth then UsedBitmapWidth := RestWidth;


                for X := 0 to UsedBitmapWidth-1 do
                begin
                  case PixelFormat of
                    bbpf8bit:
                      begin
                        PByteArray(DestScan)^[x] :=
                          PByteArray(SourceScan)^[(XBandIndex * BandWidth + x) *
                          FWidth div (w div ZoomFactorX)];
                      end;
                    bbpf24bit:
                      begin
                        PTripleArray(DestScan)^[X] :=
                          PTripleArray(SourceScan)^[(XBandIndex * BandWidth + x) *
                          FWidth div (w div ZoomFactorX)];
                      end;
                    bbpf4bit:
                      begin
                        Index := (XBandIndex * BandWidth + x) * FWidth
                                 div (w div ZoomFactorX);
                        Bits := PByteArray(SourceScan)^[Index div 2];
                        Bits := (Bits shr (4*(1 - Index mod 2))) and $0f;

                        PByteArray(DestScan)^[X div 2] :=
                          PByteArray(DestScan)^[X div 2] or
                          (Bits shl (4*(1 - X mod 2)));
                      end;
                    bbpf1bit:
                      begin
                        Index := (XBandIndex * BandWidth + x) * FWidth
                                 div (w div ZoomFactorX);
                        Bits := PByteArray(SourceScan)^[Index div 8];
                        Bits := (Bits shr (7 - Index mod 8)) and $01;

                        PByteArray(DestScan)^[X div 8] :=
                          PByteArray(DestScan)^[X div 8] or
                          (Bits shl (7 - X mod 8));
                      end;
                  end;
                end;
              end;

              // Band の DIB情報を作る
              FillChar(SepDIB, SizeOf(SepDIB), 0);
              SepDIB.W3Head.biSize := SizeOf(TBitmapInfoHeader);
              SepDIB.W3Head.biWidth := Band.Width;
              SepDIB.W3Head.biPlanes := 1;
              SepDIB.W3Head.biBitCount := GetPixelBits(FPixelFormat);
              SepDIB.W3Head.biCompression := BI_RGB;
              SepDIB.W3Head.biHeight := Band.Height;

              // カラーテーブルを取得する
              SepDIB.W3Head.biClrUsed :=
                GetDIBColorTable(Band.Canvas.Handle,
                                 0, 256,
                                 SepDIB.W3HeadInfo.bmiColors[0]);
              SepDIB.W3Head.biClrImportant := SepDIB.W3Head.biClrUsed;

              // ピクセルデータの先頭を求める
              pBits := Band.Scanline[Band.Height-1];

              {$IFDEF ORIGINAL} // 2002/7/27 削除 DHGL 1.2
              BandDrawWidth  := UsedBitmapWidth * ZoomFactorX;
              BandDrawHeight := UsedBitmapHeight * ZoomFactorY;

              // Zoom によって描画する場合、Canvas の描画先が最大 ZoomFactor-1
              // 余って描画されない領域が出来る。これを防ぐため微妙に
              // 拡大率を変える(1%程度)。
              if w - (Band.Width * XBandIndex * ZoomFactorX + BandDrawWidth) <
                 ZoomFactorX then
                BandDrawWidth := w - Band.Width * XBandIndex * ZoomFactorX;
              if h - (Band.Height * YBandIndex * ZoomFactorY + BandDrawHeight) <
                 ZoomFactorY then
                BandDrawHeight := h - Band.Height * YBandIndex * ZoomFactorY;
              {$ENDIF}

              // 位置を計算してStretchDIBitsで等倍で描画する
              StretchDIBits(ACanvas.Handle,
                            // 描画先の位置
                            Rect.Left + Band.Width * XBandIndex *
                            ZoomFactorX * XOrient,
                            Rect.Top + Band.Height * YBandIndex *
                            ZoomFactorY * YOrient,
                            // 描画先の大きさ
                            BandDrawWidth * XOrient,
                            BandDrawHeight * YOrient,
                            // 描画元(Band)の位置。左下が原点であることに注意！
                            0,
                            Band.Height - UsedBitmapHeight,
                            // 描画元(Band)の使用領域の大きさ
                            UsedBitmapWidth,
                            UsedBitmapHeight,
                            pBits,
                            SepDIB.W3HeadInfo,
                            DIB_RGB_COLORS,
                            ACanvas.CopyMode);

            {$IFNDEF ORIGINAL} // 2002/7/27 挿入 DHGL 1.2
            end;
            {$ENDIF}

            // 残り Zoom前の未処理の描画領域を算出する
            if BandDrawHeight = h - Band.Height * YBandIndex * ZoomFactorY then
              RestHeight := 0
            else
              Dec(RestHeight, UsedBitmapHeight);
            Inc(YBandIndex);
          end;
          // 残り Zoom前の未処理の描画領域を算出する
          if BandDrawWidth = w - Band.Width * XBandIndex * ZoomFactorX then
            RestWidth := 0
          else
            Dec(RestWidth, UsedBitmapWidth);
          Inc(XBandIndex);
        end;
      finally
        {$IFDEF ORIGINAL} // 2002/7/26 DHGL 1.2
        if Palette <> 0 then
          SelectPalette(ACanvas.Handle, OldPalette, True);
        {$ELSE}
        if (Palette <> 0) and not WorkAsCopyRect then
          SelectPalette(ACanvas.Handle, OldPalette, True);
        {$ENDIF}
      end;
    finally
      Band.Free;
    end;
  end
  else
    RaiseError('TBigBitmap.Draw: Unknown Mode');
end;

// 空かどうかを返す
function TBigBitmap.GetEmpty: Boolean;
begin
  Result := (FWidth = 0) or (FHeight = 0);
end;

// TBigBitmap の高さを返す
function TBigBitmap.GetHeight: Integer;
begin
  Result := FHeight;
end;

// TBigBitmap のパレットを返す
function TBigBitmap.GetPalette: HPALETTE;
begin
  if Length(FBitmaps) >= 1 then
    Result := FBitmaps[0].Palette
  else
    Result := 0;
end;

// PixelFormatからピクセルあたりのビット数を計算する
function TBigBitmap.GetPixelBits(APixelFormat: TBigBitmapPixelFormat)
  : Integer;
begin
  case APixelFormat of
    bbpf1bit: Result := 1;
    bbpf4bit: Result := 4;
    bbpf8bit: Result := 8;
    bbpf24bit: Result := 24;
    else
      RaiseError('TBigBitmap.GetPixelBits: Invalid Pixel Format');
  end;
end;

// TBigBitmapPixelFormat を TPixelFormat に変換
function BBPixelFormatToPixelFormat(ABBPixelFormat: TBigBitmapPixelFormat)
  : TPixelFormat;
begin
  case ABBPixelFormat of
    bbpf1bit: Result := pf1bit;
    bbpf4bit: Result := pf4bit;
    bbpf8bit: Result := pf8bit;
    bbpf24bit: Result := pf24bit;
    else
      RaiseError('BBPixelFormatToPixelFormat: Invalid Pixel Format');
  end;
end;

// TPixelFormat を TBigBitmapPixelFormat に変換
function PixelFormatToBBPixelFormat(APixelFormat: TPixelFormat)
  : TBigBitmapPixelFormat;
begin
  case APixelFormat of
    pf1bit: Result := bbpf1bit;
    pf4bit: Result := bbpf4bit;
    pf8bit: Result := bbpf8bit;
    pf24bit: Result := bbpf24bit;
    else
      RaiseError('PixelFormatToBBPixelFormat: Invalid Pixel Format');
  end;
end;

// TBigBitmap の ScanLine を得る
// TBiitmap と互換で、巨大なビットマップの
// Scanline と同等のものが得られる
function TBigBitmap.GetScanline(Index: Integer): Pointer;
var
  BitmapHeight: Integer;
begin
  if Empty then
    RaiseError('TBigBitmap.GetScanline: No Bitomaps');
  if (Index >= FHeight) or (Index < 0) then
    RaiseError('TBigBitmap.GetScanline: Index is out of Range');

  BitmapHeight := FBitmaps[0].Height;
  Result := FBitmaps[Index div BitmapHeight].Scanline[Index mod BitmapHeight];
end;

// TBigBitmap の高さを返す
function TBigBitmap.GetWidth: Integer;
begin
  Result := FWidth;
end;

type
  // メモリ内容をシフトして読み書きするメモリストリーム
  TShiftedMemoryStream = class(TStream)
  private
    FBufferForShift: PChar;   // シフト分のデータが入るバッファ
    FShiftLength: DWORD;      // シフト分のデータが入るバッファの長さ
    FMemPtr: PChar;           // ストリーム内のメモリへのポインタ
    FMemSize: DWORD;          // ストリーム内のメモリ量
    FPosition: Integer;      // 外から見たストリームの現在位置
  public
    constructor Create(BufferForShift: Pointer; ShiftLength: DWORD;
                       MemPtr: Pointer; MemSize: DWORD);
    function Seek(Offset: Longint; Origin: Word): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

{ TShiftedMemoryStream }

constructor TShiftedMemoryStream.Create(BufferForShift: Pointer;
  ShiftLength: DWORD; MemPtr: Pointer; MemSize: DWORD);
begin
  inherited Create;
  FBufferForShift := BufferForShift;
  FShiftLength := ShiftLength;
  FMemPtr := MemPtr;
  FMemSize := MemSize;
end;

// Seek
function TShiftedMemoryStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  // ストリームサイズが FMemSize + FShiftLength になることを考慮
  case Origin of
    soFromBeginning: FPosition := Offset;
    soFromCurrent: Inc(FPosition, Offset);
    soFromEnd: FPosition := FMemSize + FShiftLength + Offset;
  end;
  Result := FPosition;
end;

// ストリームを読む
// Position が 0 から FShiftLength-1 までは FBufferForShift から
// Position が FShiftLength から後は FMemPtr から読む
function TShiftedMemoryStream.Read(var Buffer; Count: Longint): Longint;
var
  CopyLength: Integer;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Result := Size - FPosition; // 残サイズ計算
    if Result > 0 then
    begin
      if Result > Count then Result := Count;  // 残サイズが Count より
                                               // 大きければ COunt だけ読む
      if FPosition < FShiftLength then
      // ２領域をまたがったコピー
      begin
        // FPosition から FShiftLength-1 までのコピー
        CopyLength := FShiftLength - FPosition;
        if CopyLength > Count then CopyLength := Count;
        Move((FBufferForShift + FPosition)^, Buffer, CopyLength);
        // FShiftLength 以降のコピー
        if FPosition + Count > FShiftLength then
        Move(FMemPtr^, (PChar(@Buffer) + FShiftLength - FPosition)^,
             FPosition + Count - FShiftLength);
      end
      else
      // ２領域をまたがらないコピー
        Move((FMemPtr + FPosition - FShiftLength)^, Buffer, Count);

      Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
end;

// ストリームに書く
// Position が 0 から FShiftLength-1 までは FBufferForShift に
// Position が FShiftLength から後は FMemPtr に書く
function TShiftedMemoryStream.Write(const Buffer; Count: Longint): Longint;
var
  CopyLength: Integer;
begin
  if (FPosition >= 0) and (Count >= 0) then
  begin
    Result := Size - FPosition;   // 残サイズ計算
    if Result > 0 then
    begin
      if Result > Count then Result := Count;  // 残サイズが Count より
                                               // 大きければ COunt だけ書く

      if FPosition < FShiftLength then
      // ２領域をまたがったコピー
      begin
        // FPosition から FShiftLength-1 までのコピー
        CopyLength := FShiftLength - FPosition;
        if CopyLength > Count then CopyLength := Count;
        Move(Buffer, (FBufferForShift + FPosition)^, CopyLength);
        // FShiftLength 以降のコピー
        if FPosition + Count > FShiftLength then
        Move((PChar(@Buffer) + FShiftLength - FPosition)^, FMemPtr^,
             FPosition + Count - FShiftLength);
      end
      else
      // ２領域をまたがらないコピー
        Move(Buffer, (FMemPtr + FPosition - FShiftLength)^, Count);

      Inc(FPosition, Result);
      Exit;
    end;
  end;
  Result := 0;
end;


procedure TBigBitmap.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);

var FileHeader: TBitmapFileHeader; // ビットマップファイルヘッダ
    pDIB: Pointer;
    DIBSize: Integer;
    ShiftedStream: TShiftedMemoryStream;

  function CreateBitmapFileHeaderFromPackedDIB(pHead: PBitmapInfoHeader;
                                               MemorySize: Integer)
    : TBitmapFileHeader;
  var
    pCoreHead: PBitmapCoreHeader;
    HeadSize: Integer; // ビットマップのへッダサイズ。カラーテーブルも含む
  begin
    if pHead.biSize < SizeOf(TBitmapInfoHeader) then
    // OS2 ヘッダ
    begin
      pCoreHead := PBitmapCoreHeader(PHead);
      HeadSize := pCorehead.bcSize;  // ヘッダサイズ
      // カラーテーブルサイズを加算
      case pCoreHead.bcBitCount * pCoreHead.bcPlanes of
      1: Inc(HeadSize, Sizeof(TRGBTriple) * 2);
      4: Inc(HeadSize, Sizeof(TRGBTriple) * 16);
      8: Inc(HeadSize, Sizeof(TRGBTriple) * 256);
      24: ;
      else raise EInvalidGraphic.Create('Invalid Clipbboard Data');
      end;
    end
    else
    begin
      HeadSize := pHead.biSize;    // へッダサイズ
      // V3 ヘッダでビットフィールド形式ならマスクサイズを加算
      if (pHead.biCompression = BI_BITFIELDS) and
          (pHead.biSize = SizeOf(TBitmapInfoHeader)) then
        Inc(HeadSize, SizeOf(DWORD) * 3);
      // カラーテーブルサイズを加算
      if pHead.biClrUsed <> 0 then
        Inc(HeadSize, SizeOf(DWORD) * pHead.biClrUsed)
      else
        case pHead.biPlanes * phead.biBitCount of
        1: Inc(HeadSize, SizeOf(DWORD) * 2);
        4: Inc(HeadSize, SizeOf(DWORD) * 16);
        8: Inc(HeadSize, SizeOf(DWORD) * 256);
        16, 24, 32: ;
        else raise EInvalidGraphic.Create('Invalid Clipbboard Data');
        end;
    end;
    Result.bfType := $4D42;
    Result.bfSize := SizeOf(TBitmapFileHeader) + MemorySize;
    Result.bfReserved1 := 0; Result.bfReserved2 := 0;
    Result.bfOffBits := SizeOf(TBitmapFileHeader) + HeadSize;
  end;
begin
  if (AFormat <> CF_DIB)then
    raise EInvalidGraphic.Create('Invalid Clipbboard Data');

  DIBSize := GlobalSize(AData);
  if DIBSize < SizeOf(TBitmapCoreHeader) then
    raise EInvalidGraphic.Create('Invalid Clipbboard data');
  pDIB := GlobalLock(AData);
  if pDIB = Nil then raise EInvalidGraphic.Create('Invalid Clipbboard data');
  try
    FileHeader := CreateBitmapFileHeaderFromPackedDIB(pDIB, DIBSize);
    ShiftedStream := TShiftedMemoryStream.Create(@FileHeader,
                                                 SizeOf(FileHeader),
                                                 pDIB, DIBSize);
    try
      LoadFromStream(ShiftedStream);
    finally
      ShiftedStream.Free;
    end;

  finally
    GlobalUnlock(AData);
  end;
end;

procedure TBigBitmap.LoadFromStream(Stream: TStream);
const
  Black: TRGBQUAD = (rgbBlue:0; rgbGreen:0; rgbRed:0; rgbReserved:0);
var
  SepDIB, NewSepDIB: TSepDIB;   // DIB情報
  i, j: LongInt;

  ScanlineLength: Integer;  // 各TBitmapのスキャンライン長
  nBitmaps: Integer;        // TBitmapの数
  BitmapHeight: Integer;    // TBitmapの高さ(最後のものは除く)
  Bitmaps: TBitmapArray;    // TBitmapの配列
  TotalHeight: Integer;     // TBitmapの高さの計
  RestHeight: Integer;      // 未処理の高さ
  BottomUp: Boolean;        // ビットマップの向き
  BitsSize: Integer;        // ビットマップのピクセルデータの大きさ
begin

  LoadDIBFromStream(SepDIB, Stream);

  // 16 or 32 bpp なら 24bpp に直す。
  if SepDIB.W3Head.biBitCount in [16, 32] then
  begin
    DIB32_16ToDIB24(SepDIB, NewSepDIB);
    SepDIB := NewSepDIB;
  end;

  // 圧縮されたままではビットマップを TBitmap群に分配できないので
  // でコードする

  if SepDIB.W3Head.biCompression = BI_RLE4 then
  begin
    Convert4BitRLETo4bitRGB(SepDIB, NewSepDIB);
    SepDIB := NewSepDIB;
  end
  else if SepDIB.W3Head.biCompression = BI_RLE8 then
  begin
    Convert8BitRLETo8bitRGB(SepDIB, NewSepDIB);
    SepDIB := NewSepDIB;
  end;

  // TBitmap群の大きさと数を決める
  ScanLineLength := (SepDIB.W3Head.biWidth * SepDIB.W3Head.biBitCount + 31)
                     div 32 * 4;

  // 全ピクセルデータサイズを計算
  BitsSize := ScanLineLength * abs(SepDIB.W3Head.biHeight);

  if  ScanLineLength >= MaxBitmapScanline then
    RaiseError('TBigBitmap.LoadFromStream: Too Big Width or Too Many Pixel Bits');

  BitmapHeight := MaxOneBitmapSize div ScanLineLength;
  if BitmapHeight > abs(SepDIB.W3Head.biHeight) then
    BitmapHeight := abs(SepDIB.W3Head.biHeight);
  nBitmaps := (abs(SepDIB.W3Head.biHeight) + BitmapHeight - 1) div BitmapHeight;

  // 配列を確保
  SetLength(Bitmaps, nBitmaps);
  FillChar(Bitmaps[0], SizeOf(TBitmap) * nBitmaps, 0);

  TotalHeight := abs(SepDIB.W3Head.biHeight);
  RestHeight := TotalHeight;


  if SepDIB.W3Head.biHeight > 0 then BottomUp := True
                                else BottomUp := False;
  try
    for i := 0 to nBitmaps-1 do
    begin
      Bitmaps[i] := TBitmap.Create;
      case SepDIB.W3Head.biBitCount of
        1: Bitmaps[i].PixelFormat := pf1bit;
        4: Bitmaps[i].PixelFormat := pf4bit;
        8: Bitmaps[i].PixelFormat := pf8bit;
       24: Bitmaps[i].PixelFormat := pf24bit;
      end;
      Bitmaps[i].Width := SepDIB.W3Head.biWidth;
      Bitmaps[i].Palette := CreatePaletteFromDIB(SepDIB);

      if RestHeight > BitmapHeight then
      begin
        Bitmaps[i].Height := BitmapHeight;
        for j := 0 to Bitmaps[i].Height-1 do
          if BottomUp then
            System.Move(AddOffset(Pointer(SepDIB.Bits),
                                  BitsSize - i * BitmapHeight * ScanlineLength -
                                  (j+1) * ScanlineLength)^,
                                  Bitmaps[i].Scanline[j]^, ScanLineLength)
          else
            System.Move(AddOffset(Pointer(SepDIB.Bits),
                                  i * BitmapHeight * ScanlineLength +
                                  j * ScanlineLength)^,
                                  Bitmaps[i].Scanline[j]^, ScanLineLength);
      end
      else
      begin
        Bitmaps[i].Height := RestHeight;
        for j := 0 to Bitmaps[i].Height-1 do
          if BottomUp then
            System.Move(AddOffset(Pointer(SepDIB.Bits),
                                  RestHeight * ScanlineLength -
                                  (j+1) * ScanlineLength)^,
                                  Bitmaps[i].Scanline[j]^, ScanLineLength)
          else
            System.Move(AddOffset(Pointer(SepDIB.Bits),
                                  j * ScanlineLength)^,
                                  Bitmaps[i].Scanline[j]^, ScanLineLength);
      end;
      Dec(RestHeight, BitmapHeight);
    end;
  except
    for i := 0 to nBitmaps-1 do
      Bitmaps[i].Free;
    raise;
  end;
  // 仕上げ
  DiscardBitmaps;        // 古いビットマップを捨て差し替える
  FBitmaps := Bitmaps;
  FWidth := SepDIB.W3Head.biWidth;
  FHeight := TotalHeight;
  FPixelFormat := PixelFormatToBBPixelFormat(FBitmaps[0].PixelFormat);
  PaletteModified := True;
  Modified := True;
end;

procedure TBigBitmap.SaveToClipboardFormat(var AFormat: Word;
  var AData: THandle; var APalette: HPALETTE);
var
  FileHeader: TBitmapFileHeader;       // ダミーのファイルヘッダ
  DIBSize, ScanlineLength: Integer;    // Packed DIB のサイズ
  Colors: array[0..255] of DWORD;      // ダミーのカラーテーブル
  ColorCount: Integer;                 // ビットマップの色数
  ShiftedStream: TShiftedMemoryStream; // ファイルヘッダをカットするストリーム
  DIBPtr: Pointer;                     // PackedDIB へのポインタ
begin
  if Empty then
  begin
    AData := 0;
    AFormat := CF_DIB;
    Exit;
  end;

  DIBSize := SizeOf(TBitmapInfoHeader);                     // ヘッダ長
  ColorCount := GetDIBColorTable(FBitmaps[0].Canvas.Handle, //カラーテーブル
                     0, 256,                                // 長を加算
                     Colors[0]);
  Inc(DIBSize, SizeOf(DWORD) * ColorCount);
  case PixelFormat of                                       //ピクセルデータ
  bbpf1bit:  ScanlineLength := ((Width + 31) div 32) * 4;   // 長を加算
  bbpf4bit:  ScanlineLength := ((Width * 4 + 31) div 32) * 4;
  bbpf8bit:  ScanlineLength := ((Width * 8 + 31) div 32) * 4;
  bbpf24bit: ScanlineLength := ((Width * 24 + 31) div 32) * 4;
  end;

  Inc(DiBSize, ScanlineLength * Height);
  AFormat := CF_DIB;

  // クリップボードに渡すメモリを確保
  AData := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, DIBSize);
  if AData = 0 then RaiseError('Cannot Allocate Memory');
  try
    DIBPtr := GlobalLock(AData);
    if DIBPtr = Nil then RaiseError('Cannnot Lock Memory for CLipboard');
    try
      ShiftedStream := TShiftedMemoryStream.Create(@FileHeader,
                                                   SizeOf(FileHeader),
                                                   DIBPtr,
                                                   DIBSize);
      try
        SaveToStream(ShiftedStream);
      finally
        ShiftedStream.Free;
      end;
    finally
      GlobalUnlock(AData);
    end;
  except
    GlobalFree(AData);
  end;
end;

procedure TBigBitmap.SaveToStream(Stream: TStream);
var
  bfh: TBitmapFileHeader;
  SepDIB: TSepDIB;
  ScanLineLength: Integer;
  i: Integer;
begin
  if Empty then Exit;

  // 複数のビットマップをひとつのDIBファイルイメージにして書き出す
  ScanLineLength := (FWidth * GetPixelBits(FPixelFormat) + 31) div 32 * 4;

  FillChar(SepDIB, SizeOf(SepDIB), 0);
  SepDIB.W3Head.biSize := SizeOf(TBitmapInfoHeader);
  SepDIB.W3Head.biWidth := FWidth;
  SepDIB.W3Head.biHeight := FHeight;
  SepDIB.W3Head.biPlanes := 1;
  SepDIB.W3Head.biBitCount := GetPixelBits(FPixelFormat);
  SepDIB.W3Head.biCompression := BI_RGB;

  SepDIB.W3Head.biClrUsed :=
    GetDIBColorTable(FBitmaps[0].Canvas.Handle,
                     0, 256,
                     SepDIB.W3HeadInfo.bmiColors[0]);

  SepDIB.W3Head.biHeight := FHeight;

  bfh.bfType := $4D42;
  bfh.bfSize := SizeOf(bfh) + SizeOf(SepDIB.W3Head) +
                SizeOf(TRGBQUAD) * SepDIB.W3Head.biClrUsed +
                ScanLineLength * FHeight;
  bfh.bfReserved1 := 0;
  bfh.bfReserved2 := 0;
  bfh.bfOffBits   := SizeOf(bfh) + SizeOf(SepDIB.W3Head) +
                     SizeOf(TRGBQUAD) * SepDIB.W3Head.biClrUsed;
  Stream.WriteBuffer(bfh, SizeOf(bfh));
  Stream.WriteBuffer(SepDIB.Dummy, SizeOf(SepDIB.W3Head) +
                     SizeOf(TRGBQUAD) * SepDIB.W3Head.biClrUsed);

  for i := Length(FBitmaps)-1 downto 0 do
    Stream.WriteBuffer(FBitmaps[i].Scanline[FBitmaps[i].Height-1]^,
                       ScanlineLength * FBitmaps[i].Height);
end;

// 描画モードの設定
procedure TBigBitmap.SetDrawMode(const Value: TBigBitmapDrawMode);
begin
  FDrawMode := Value;
  PaletteModified := True;
  Modified := True;
end;

// 高さを変更する。ビットマップはクリアされる
procedure TBigBitmap.SetHeight(Value: Integer);
begin
  SetupBitmaps(FWidth, Value, FPixelFormat);
end;

// パレットを変更する。
procedure TBigBitmap.SetPalette(Value: HPALETTE);
var
  i: Integer;
begin
  for i := 0 to Length(FBitmaps) -1 do
    FBitmaps[i].Palette := CopyPalette(Value);

  DeleteObject(Value);

  PaletteModified := True;
  Modified := True;
end;

// ピクセル形式を変更する。ビットマップはクリアされる。
procedure TBigBitmap.SetPixelFormat(const Value: TBigBitmapPixelFormat);
begin
  SetupBitmaps(FWidth, FHeight, Value);
end;

// 幅、高さ、ピクセル形式を元に TBitmap群を作る
procedure TBigBitmap.SetPreview(Value: Boolean);
begin
  if FPreview <> Value then
  begin
    FPreview := Value;
    Modified := True;
  end;
end;

procedure TBigBitmap.SetupBitmaps(NewWidth, NewHeight: Integer;
                                  NewPixelFormat: TBigBitmapPixelFormat);
var
  nBitmaps: Integer;
  BitmapHeight: Integer;
  ScanLineLength: Integer;
  Bitmaps: TBitmapArray;
  RestHeight: Integer;
  i: Integer;
begin
  if NewWidth < 0 then
    RaiseError('TBigBitmap.SetBitmaps: Negative Width');
  if NewHeight < 0 then
    RaiseError('TBigBitmap.SetBitmaps: Negative Height');

  ScanLineLength := (NewWidth * GetPixelBits(NewPixelFormat) + 31) div 32 * 4;
  if  ScanLineLength >= MaxBitmapScanline then
    RaiseError('TBigBitmap.SetBitmaps: Too Big Width or Too Many Pixel Bits');
  if (NewWidth = 0) or (NewHeight = 0) then
  begin
    DiscardBitmaps;
    FWidth := NewWidth; FHeight := NewHeight;
    FPixelFormat := NewPixelFormat;
    PaletteModified := True;
    Modified := True;
    Exit;
  end;

  // TBitmap の大きさと数を決める」
  BitmapHeight := MaxOneBitmapSize div ScanLineLength;
  if BitmapHeight > NewHeight then
    BitmapHeight := NewHeight;
  nBitmaps := (NewHeight + BitmapHeight - 1) div BitmapHeight;

  // 配列を用意する
  SetLength(Bitmaps, nBitmaps);
  FillChar(Bitmaps[0], SizeOf(TBitmap) * nBitmaps, 0);
  RestHeight := NewHeight;
  try
    // ビットマップ群を作る
    for i := 0 to nBitmaps-1 do
    begin
      Bitmaps[i] := TBitmap.Create;
      Bitmaps[i].PixelFormat := BBPixelFormatToPixelFormat(NewPixelFormat);
      Bitmaps[i].Width := NewWidth;
      if RestHeight > BitmapHeight then
        Bitmaps[i].Height := BitmapHeight
      else
        Bitmaps[i].Height := RestHeight;

      // 白に初期化する
      Bitmaps[i].Canvas.FillRect(Rect(0, 0, NewWidth, Bitmaps[i].Height));

      Dec(RestHeight, BitmapHeight);
  end
  except
    for i := 0 to nBitmaps-1 do
      Bitmaps[i].Free;
    raise;
  end;
  //仕上げ」
  DiscardBitmaps;     // 古いビットマップを捨て差し替える
  FBitmaps := Bitmaps;
  FWidth := NewWidth;
  FHeight := NewHeight;
  FPixelFormat := NewPixelFormat;
  PaletteModified := True;
  Modified := True;
  Canvas.MoveTo(0, 0); // ペンの初期位置を (0, 0) に
end;

// 幅を変更する。ビットマップはクリアされる
procedure TBigBitmap.SetWidth(Value: Integer);
begin
  SetupBitmaps(Value, FHeight, FPixelFormat);
end;

{ TBigBitmapCanvas }

// 弧を描く
procedure TBigBitmapCanvas.Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Arc(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// BrushCopy
procedure TBigBitmapCanvas.BrushCopy(const Dest: TRect; Bitmap: TBitmap;
  const Source: TRect; Color: TColor);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.BrushCopy(Dest, Bitmap, Source, Color);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 弦を描く
procedure TBigBitmapCanvas.Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Chord(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// CopyRect
procedure TBigBitmapCanvas.CopyRect(const Dest: TRect; Canvas: TCanvas;
  const Source: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    {$IFNDEF ORIGINAL} // 2002/7/26 DHGL 1.2
    SetStretchBltMode(FBigBitmap.FBitmaps[i].Canvas.Handle,
                      FCopyRectMode);
    {$ENDIF}
    FBigBitmap.FBitmaps[i].Canvas.CopyRect(Dest, Canvas, Source);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// Canvas の作成
constructor TBigBitmapCanvas.Create;
begin
  FFont := TFont.Create;
  FBrush := TBrush.Create;
  FPen := TPen.Create;
  FCopyMode := cmSrcCopy;
  {$IFNDEF ORIGINAL} // 2002/7/26 追加 DHGL 1.2
  FCopyRectMode := COLORONCOLOR;
  {$ENDIF}
end;

destructor TBigBitmapCanvas.Destroy;
begin
  FPen.Free;
  FBrush.Free;
  FFont.Free;

  {$IFNDEF ORIGINAL} // 2002/7/26 DHGL 1.2
  if FClipRgn <> 0 then DeleteObject(FClipRgn);
  {$ENDIF}
  inherited;
end;

// DrawFocusRect
procedure TBigBitmapCanvas.Draw(X, Y: Integer; Graphic: TGraphic);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Draw(X, Y, Graphic);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

procedure TBigBitmapCanvas.DrawFocusRect(const Rect: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.DrawFocusRect(Rect);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

{$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
// TBigBitmap から TBigBitmap への CopyRect
procedure TBigBitmapCanvas.CopyRect(Dest: TRect; Bitmap: TBigBitmap;
  Source: TRect);
var
  DestRectForDraw: TRect;
  DestRGN, SavedClipRgn: HRGN;

  function SourceToDest(Pt: TPoint): TPoint;
  begin
    Result.x := (Pt.x - Source.Left) *
                (Dest.Right - Dest.Left) div
                (Source.Right - Source.Left) +
                Dest.Left;

    Result.y := (Pt.y - Source.Top) *
                (Dest.Bottom - Dest.Top) div
                (Source.Bottom - Source.Top) +
                Dest.Top;
  end;
begin
  // ビットマップ全体を Draw でコピーするが、不要な
  // 部分はクリッピングでカットする
  if Source.Left = Source.Right then
    Inc(Source.Right);
  if Source.Top = Source.Bottom then
    Inc(Source.Bottom);

  // クリッピング無しの場合の描画先矩形を計算
  DestRectForDraw.TopLeft := SourceToDest(Point(0, 0));
  DestRectForDraw.BottomRight := SourceToDest(Point(Bitmap.Width,
                                                    Bitmap.Height));
  // 描画先エリアを座標反転を考慮書して補正(旧CopyRect に合わせる)
  with Dest do
  begin
    if Left > Right then begin Inc(Left); Inc(Right); end;
    if Top > Bottom then begin Inc(Top); Inc(Bottom); end;
    DestRgn := CreateRectRgn(Left, Top, Right, Bottom);
  end;

  if DestRgn = 0 then
    RaiseError('TBigBitmap.CopyRect: Cannot Create Rgn for Dest');
  try
    // クリッピングをセットして StretchDraw する
    if FClipRgn <> 0 then
      if CombineRgn(DestRgn, FClipRgn, DestRgn, RGN_AND) = ERROR then
        RaiseError('TBigBitmap.CopyRect: Cannot Create Rgn for Bitmaps');

    SavedClipRgn := FClipRgn;
    FClipRgn := DestRgn;
    SetupClipRgn(True);
    try
      Bitmap.WorkAsCopyRect := True;
      FBigBitmap.WorkAsCopyRect := True;
      try
        StretchDraw(DestRectForDraw, Bitmap);
      finally
        FBigBitmap.WorkAsCopyRect := True;
        Bitmap.WorkAsCopyRect := False;
      end;
    finally
      FClipRgn := SavedClipRgn;
      SetupClipRgn(True);
    end;
  finally
    DeleteObject(DestRgn);
  end;
end;
{$ENDIF}

// 楕円を描く
procedure TBigBitmapCanvas.Ellipse(const Rect: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Ellipse(Rect);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 楕円を描く
procedure TBigBitmapCanvas.Ellipse(X1, Y1, X2, Y2: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Ellipse(X1, Y1, X2, Y2);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// FillRect
procedure TBigBitmapCanvas.FillRect(const Rect: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.FillRect(Rect);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// FloodFill
procedure TBigBitmapCanvas.FloodFill(X, Y: Integer; Color: TColor;
  FillStyle: TFillStyle);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.FloodFill(X, Y, Color, FillStyle);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// FrameRect
procedure TBigBitmapCanvas.FrameRect(const Rect: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.FrameRect(Rect);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 線を引く
function TBigBitmapCanvas.GetPixel(X, Y: Integer): TColor;
var
  SmallBitmapHeight: Integer;
begin
  Result := -1;
  if (X <0) or (Y < 0) or (X >= FBigBitmap.Width) or
     (Y >= FBigBitmap.Height) then Exit;

  SmallBitmapHeight := FBigBitmap.FBitmaps[0].Height;
  Result := FBigBitmap.FBitmaps[Y div SmallBitmapHeight].Canvas.Pixels[x, Y mod SmallBitmapHeight];
end;

procedure TBigBitmapCanvas.LineTo(X, Y: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.LineTo(X, Y);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// ペン位置を動かす
procedure TBigBitmapCanvas.MoveTo(X, Y: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.MoveTo(X, Y);
  end;
  ResetBitmaps;
end;

// 扇形を描く
procedure TBigBitmapCanvas.Pie(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Pie(X1, Y1, X2, Y2, X3, Y3, X4, Y4);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// べジエ曲線を描く
procedure TBigBitmapCanvas.PolyBezier(const Points: array of TPoint);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.PolyBezier(Points);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// べジエ曲線を描く
procedure TBigBitmapCanvas.PolyBezierTo(const Points: array of TPoint);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.PolyBezierTo(Points);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 多角形を描く
procedure TBigBitmapCanvas.Polygon(const Points: array of TPoint);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Polygon(Points);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 折れ線を描く
procedure TBigBitmapCanvas.Polyline(const Points: array of TPoint);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Polyline(Points);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 矩形を描く
procedure TBigBitmapCanvas.Rectangle(X1, Y1, X2, Y2: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Rectangle(X1, Y1, X2, Y2);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 矩形を描く
procedure TBigBitmapCanvas.Rectangle(const Rect: TRect);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.Rectangle(Rect);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// 各TBitmapの原点をリセットする
procedure TBigBitmapCanvas.ResetBitmaps;
var
  i: Integer;
begin
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
    SetWindowOrgEx(FBigBitmap.FBitmaps[i].Canvas.Handle, 0, 0, Nil);
end;

// 角丸矩形を描く
procedure TBigBitmapCanvas.RoundRect(X1, Y1, X2, Y2, X3, Y3: Integer);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.RoundRect(X1, Y1, X2, Y2, X3, Y3);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

//ブラシの更新
procedure TBigBitmapCanvas.SetBrush(const Value: TBrush);
begin
  FBrush.Assign(Value);
end;

{$IFNDEF ORIGINAL} // 2002/7/25 追加 DHGL 1.2
// クリッピングリージョンの設定
procedure TBigBitmapCanvas.SetClipRgn(const Value: HRGN);
begin
  if FClipRgn <> Value then
  begin
    if FClipRgn <> 0 then DeleteObject(FClipRgn);
    FClipRgn := Value;
  end;
  SetupClipRgn(True);
end;
{$ENDIF}

//フォントの更新
procedure TBigBitmapCanvas.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

// ペンの更新
procedure TBigBitmapCanvas.SetPen(const Value: TPen);
begin
  FPen.Assign(Value);
end;

procedure TBigBitmapCanvas.SetPixel(X, Y: Integer; Value: TColor);
var
  SmallBitmapHeight: Integer;
begin
  if (X <0) or (Y < 0) or (X >= FBigBitmap.Width) or
     (Y >= FBigBitmap.Height) then Exit;

  SmallBitmapHeight := FBigBitmap.FBitmaps[0].Height;
  FBigBitmap.FBitmaps[Y div SmallBitmapHeight].Canvas.Pixels[x, Y mod SmallBitmapHeight]
    := Value;
  FBigBitmap.Modified := True;
end;

// 各TBitmapのCanvasを整える
procedure TBigBitmapCanvas.SetupBitmaps;
var
  i: Integer;
begin
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    // Canvasの属性を更新する
    FBigBitmap.FBitmaps[i].Canvas.Font := Font;
    FBigBitmap.FBitmaps[i].Canvas.Brush := Brush;
    FBigBitmap.FBitmaps[i].Canvas.Pen := Pen;
    FBigBitmap.FBitmaps[i].Canvas.CopyMode := CopyMode;
    FBigBitmap.FBitmaps[i].Canvas.TextFlags := TextFlags;

    //座標系をTBitmapの位置にあわせて補正する
    SetWindowOrgEx(FBigBitmap.FBitmaps[i].Canvas.Handle,
      0, i * FBigBitmap.FBitmaps[0].Height, Nil);
  end;
  {$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
  // ビットマップのデバイスコンテキストが壊されている
  // 恐れがあるので クリッピングの再設定が必要
  if FClipRgn <> 0 then SetupClipRgn(False);
  {$ENDIF}
end;

{$IFNDEF ORIGINAL} // 2002/7/25 DHGL 1.2
// 各ビットマップにクリップリージョンを設定
procedure TBigBitmapCanvas.SetupClipRgn(Force: Boolean);
var
  i: Integer;
  Rgn: HRGN;
  Ret: Integer;
begin
  // ここは時間的にクリチカルなので注意深くコーディング
  if FClipRgn <> 0 then
  begin
    if Length(FBigBitmap.FBitmaps) = 0 then Exit;

    if Not Force then
    begin
      // ビットマップのデバイスコンテキストが破棄され
      // クリッピングリージョンが破棄されていないかチェックする。
      // 破棄されていなければ再設定はしない(高速化！)。
      // 再設定は大きな時間がかかるので時間が大幅に無駄になる。
      Rgn := CreateRectRgn(0, 0, 1, 1);
      try
      if Rgn = 0 then
        RaiseError('TBigBitmapCanvas.SetupClipRgn: ' +
                   'Cannot Create Rgn for Test');
      ret := GetClipRgn(FBigBitmap.FBitmaps[0].Canvas.Handle, Rgn);
      if Ret = 1 then Exit
      else if Ret = Error then
        RaiseError('TBigBitmapCanvas.SetupClipRgn: ' +
                   'Failed to retrieve Clipping Region');
      finally
        DeleteObject(Rgn);
      end;
    end;

    // リージョンのコピーを作る
    Rgn := CreateRectRgn(0, 0, 1, 1);
    if Rgn = 0 then
      RaiseError('TBigBitmapCanvas.SetupClipRgn: ' +
                 'Cannot Create Rgn for Clipping');
    if CombineRgn(Rgn, FClipRgn, 0, RGN_COPY) = ERROR then
      RaiseError('TBigBitmapCanvas.SetupClipRgn: ' +
                 'Cannot Copy Rgn for Clipping');
    try
      for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
      begin
        // Canvasのクリップリージョンを変更する
        SelectClipRgn(FBigBitmap.FBitmaps[i].Canvas.Handle, Rgn);

        //クリップリージョンはデバイス座標なので、
        //TBitmapの位置にあわせて補正する
        OffsetRgn(Rgn, 0, -FBigBitmap.FBitmaps[0].Height);
      end;
    finally
      DeleteObject(Rgn); // コピーなので破棄
    end;
  end
  else
    // Canvasのクリップリージョンを削除する
    for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
      SelectClipRgn(FBigBitmap.FBitmaps[i].Canvas.Handle, 0);
end;
{$ENDIF}

// ビットマップへグラフィック描画
procedure TBigBitmapCanvas.StretchDraw(const Rect: TRect;
  Graphic: TGraphic);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    {$IFNDEF ORIGINAL} // 2002/7/26 DHGL 1.2
    if FBigBitmap.WorkAsCopyRect then
      SetStretchBltMode(FBigBitmap.FBitmaps[i].Canvas.Handle, FCopyRectMode);
    {$ENDIF}
    FBigBitmap.FBitmaps[i].Canvas.StretchDraw(Rect, Graphic);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// テキストの大きさ
function TBigBitmapCanvas.TextExtent(const Text: string): TSize;
begin
  if Length(FBigBitmap.FBitmaps) = 0 then
    raise EInvalidOperation.Create(
      'TBigBitmapCanvas.TExtExtent: No Bitmap');
  SetupBitmaps;
    Result := FBigBitmap.FBitmaps[0].Canvas.TextExtent(Text);
  ResetBitmaps;
end;

// テキストの高さ
function TBigBitmapCanvas.TextHeight(const Text: string): Integer;
begin
  if Length(FBigBitmap.FBitmaps) = 0 then
    raise EInvalidOperation.Create(
      'TBigBitmapCanvas.TExtExtent: No Bitmap');
  SetupBitmaps;
    Result := FBigBitmap.FBitmaps[0].Canvas.TextHeight(Text);
  ResetBitmaps;
end;

// テキストの幅
procedure TBigBitmapCanvas.TextOut(X, Y: Integer; const Text: string);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.TextOut(X, Y, Text);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// TextRect
procedure TBigBitmapCanvas.TextRect(Rect: TRect; X, Y: Integer;
  const Text: string);
var
  i: Integer;
begin
  SetupBitmaps;
  for i := 0 to Length(FBigBitmap.FBitmaps)-1 do
  begin
    FBigBitmap.FBitmaps[i].Canvas.TextRect(Rect, X, Y, Text);
  end;
  ResetBitmaps;
  FBigBitmap.Modified := True;
end;

// テキストの幅
function TBigBitmapCanvas.TextWidth(const Text: string): Integer;
begin
  if Length(FBigBitmap.FBitmaps) = 0 then
    raise EInvalidOperation.Create(
      'TBigBitmapCanvas.TExtExtent: No Bitmap');
  SetupBitmaps;
    Result := FBigBitmap.FBitmaps[0].Canvas.TextWidth(Text);
  ResetBitmaps;
end;

{$IFNDEF ORIGINAL} // 2002/7/28 DHGL 1.2
// TBigBitmap から TCanvas への CopyRect
procedure CopyRectBigBitmap(Dest: TRect; ACanvas: TCanvas;
                            Source: TRect; Bitmap: TBigBitmap);
var
  DestRectForDraw: TRect;
  DestRgn: HRGN;

  function SourceToDest(Pt: TPoint): TPoint;
  begin
    Result.x := (Pt.x - Source.Left) *
                (Dest.Right - Dest.Left) div
                (Source.Right - Source.Left) +
                Dest.Left;

    Result.y := (Pt.y - Source.Top) *
                (Dest.Bottom - Dest.Top) div
                (Source.Bottom - Source.Top) +
                Dest.Top;
  end;
begin
  // ビットマップ全体を Draw でコピーするが、不要な
  // 部分はクリッピングでカットする
  if Source.Left = Source.Right then
    Inc(Source.Right);
  if Source.Top = Source.Bottom then
    Inc(Source.Bottom);

  // クリッピング無しの場合の描画先矩形を計算
  DestRectForDraw.TopLeft := SourceToDest(Point(0, 0));
  DestRectForDraw.BottomRight := SourceToDest(Point(Bitmap.Width,
                                                    Bitmap.Height));
  // 描画先エリアを座標反転を考慮書して補正(旧CopyRect に合わせる)
  with Dest do
  begin
    if Left > Right then begin Inc(Left); Inc(Right); end;
    if Top > Bottom then begin Inc(Top); Inc(Bottom); end;
    DestRgn := CreateRectRgn(Left, Top, Right, Bottom);
  end;

  if DestRgn = 0 then
    RaiseError('CopyRectBigBitmap: Cannot Create Rgn for Dest');

  try
    // クリッピングをセットして Draw する
    SaveDC(ACanvas.Handle);
    ExtSelectClipRgn(ACAnvas.Handle, DestRgn, RGN_AND);
    try
      Bitmap.WorkAsCopyRect := True;
      try
        ACanvas.StretchDraw(DestRectForDraw, Bitmap);
      finally
        Bitmap.WorkAsCopyRect := False;
      end;
    finally
      RestoreDC(ACanvas.Handle, -1);
    end;
  finally
    DeleteObject(DestRgn);
  end;
end;
{$ENDIF}



{
initialization
  TPicture.RegisterClipboardFormat(CF_DIB, TBigBitmap);
  TPicture.RegisterClipboardFormat(CF_DIB, TBigBitmap);

finalization
  TPicture.UnregisterGraphicClass(TBigBitmap);
}
end.


