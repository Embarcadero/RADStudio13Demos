unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.StdActns, Vcl.ExtActns, Vcl.ActnList,
  System.Actions, Vcl.PlatformDefaultStyleActnCtrls, System.ImageList,
  Vcl.ImgList, Vcl.ComCtrls, Vcl.BaseImageCollection, Vcl.ImageCollection, Vcl.TitleBarCtrls,
  Vcl.VirtualImageList, Vcl.Menus, Vcl.StdCtrls, Vcl.WinXCtrls, Vcl.Buttons;

type
  TFrmMain = class(TForm)
    ActionMainMenuBar1: TActionMainMenuBar;
    TitleBarPanel1: TTitleBarPanel;
    ActionManager1: TActionManager;
    DialogOpenPicture1: TOpenPicture;
    DialogSavePicture1: TSavePicture;
    DialogColorSelect1: TColorSelect;
    DialogFontEdit1: TFontEdit;
    DialogPrintDlg1: TPrintDlg;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    EditSelectAll1: TEditSelectAll;
    EditUndo1: TEditUndo;
    EditDelete1: TEditDelete;
    FileOpen1: TFileOpen;
    FileOpenWith1: TFileOpenWith;
    FileSaveAs1: TFileSaveAs;
    FilePrintSetup1: TFilePrintSetup;
    FilePageSetup1: TFilePageSetup;
    FileRun1: TFileRun;
    FileExit1: TFileExit;
    BrowseForFolder1: TBrowseForFolder;
    InternetBrowseURL1: TBrowseURL;
    InternetDownLoadURL1: TDownLoadURL;
    InternetSendMail1: TSendMail;
    SearchFind1: TSearchFind;
    SearchFindNext1: TSearchFindNext;
    SearchReplace1: TSearchReplace;
    SearchFindFirst1: TSearchFindFirst;
    ToolBar16: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolBar32: TToolBar;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    VirtualImageList16: TVirtualImageList;
    ImageCollection1: TImageCollection;
    VirtualImageList32: TVirtualImageList;
    ColorBoxActive: TColorBox;
    ColorBoxInActive: TColorBox;
    ColorBoxActiveText: TColorBox;
    ColorBoxInActiveText: TColorBox;
    Label3: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    CheckBoxCustomColors: TCheckBox;
    CheckBoxOnPaint: TCheckBox;
    Label7: TLabel;
    Label8: TLabel;
    ColorBoxButtonBackground: TColorBox;
    ColorBoxButtonForeground: TColorBox;
    Label1: TLabel;
    Label2: TLabel;
    ColorBoxButtonInactiveBackground: TColorBox;
    ColorBoxButtonInactiveForeground: TColorBox;
    Label9: TLabel;
    procedure ColorBoxActiveSelect(Sender: TObject);
    procedure ColorBoxInActiveSelect(Sender: TObject);
    procedure ColorBoxActiveTextSelect(Sender: TObject);
    procedure ColorBoxInActiveTextSelect(Sender: TObject);
    procedure CheckBoxCustomColorsClick(Sender: TObject);
    procedure TitleBarPanel1Paint(Sender: TObject; Canvas: TCanvas;
      var ARect: TRect);
    procedure CheckBoxOnPaintClick(Sender: TObject);
    procedure ColorBoxButtonBackgroundSelect(Sender: TObject);
    procedure ColorBoxButtonForegroundSelect(Sender: TObject);
    procedure ColorBoxButtonInactiveBackgroundSelect(Sender: TObject);
    procedure ColorBoxButtonInactiveForegroundSelect(Sender: TObject);
    procedure SystemTitlebarButton1Paint(Sender: TObject);
    procedure SystemTitlebarButton1Click(Sender: TObject);
  private
    procedure DrawSymbol(ACanvas: TCanvas; ARect: TRect; FGColor, BGColor: TColor);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  Vcl.GraphUtil, Vcl.Themes, System.Types, System.Math, Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

{$R *.dfm}

procedure TFrmMain.CheckBoxCustomColorsClick(Sender: TObject);
begin
  if not CheckBoxCustomColors.Checked then
    CustomTitleBar.InitTitleBarColors
  else
  begin
    CustomTitleBar.BackgroundColor := ColorBoxActive.Selected;
    CustomTitleBar.ForegroundColor := ColorBoxActiveText.Selected;
    CustomTitleBar.ButtonBackgroundColor := ColorBoxButtonBackground.Selected;
    CustomTitleBar.ButtonForegroundColor := ColorBoxButtonForeground.Selected;
    CustomTitleBar.ButtonInactiveBackgroundColor := ColorBoxButtonInactiveBackground.Selected;
    CustomTitleBar.ButtonInactiveForegroundColor := ColorBoxButtonInactiveForeground.Selected;
    CustomTitleBar.InactiveBackgroundColor := ColorBoxInActive.Selected;
    CustomTitleBar.InactiveForegroundColor := ColorBoxInActiveText.Selected;
  end;
  CustomTitleBar.Invalidate;
end;

procedure TFrmMain.CheckBoxOnPaintClick(Sender: TObject);
begin
  CustomTitleBar.Invalidate;
end;

procedure TFrmMain.ColorBoxActiveSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
  begin
    CustomTitleBar.BackgroundColor := ColorBoxActive.Selected;
    CustomTitleBar.Invalidate;
  end;
end;

procedure TFrmMain.ColorBoxActiveTextSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
  begin
    CustomTitleBar.ForegroundColor := ColorBoxActiveText.Selected;
    CustomTitleBar.Invalidate;
  end;
end;

procedure TFrmMain.ColorBoxButtonBackgroundSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.ButtonBackgroundColor := ColorBoxButtonBackground.Selected;
end;

procedure TFrmMain.ColorBoxButtonForegroundSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.ButtonForegroundColor := ColorBoxButtonForeground.Selected;
end;

procedure TFrmMain.ColorBoxButtonInactiveBackgroundSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.ButtonInactiveBackgroundColor := ColorBoxButtonInactiveBackground.Selected;
end;

procedure TFrmMain.ColorBoxButtonInactiveForegroundSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.ButtonInactiveForegroundColor := ColorBoxButtonInactiveForeground.Selected;
end;

procedure TFrmMain.ColorBoxInActiveSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.InactiveBackgroundColor := ColorBoxInActive.Selected;
end;

procedure TFrmMain.ColorBoxInActiveTextSelect(Sender: TObject);
begin
  if CustomTitleBar.Enabled and CheckBoxCustomColors.Checked then
    CustomTitleBar.InactiveForegroundColor := ColorBoxInActiveText.Selected;
end;

procedure TFrmMain.DrawSymbol(ACanvas: TCanvas; ARect: TRect; FGColor, BGColor: TColor);
var
  LRect: TRect;
  LGPGraphics: TGPGraphics;
  LGPPen: TGPPen;
  LRGBColor, LSize: Integer;
  LColor: Cardinal;
  LGPRect: TGPRect;
  LPath: TGPGraphicsPath;
begin
  LRGBColor := ColorToRGB(FGColor);
  LColor := MakeColor(GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));
  LGPGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGPGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGPPen := TGPPen.Create(LColor, CurrentPPI / Screen.DefaultPixelsPerInch);
    try
      LPath := TGPGraphicsPath.Create;
      try
        LPath.Reset;
        LSize := MulDiv(9, CurrentPPI, Screen.DefaultPixelsPerInch);
        LRect := CenteredRect(ARect, Rect(0, 0, LSize, LSize));

        LGPRect := MakeRect(LRect.Left, LRect.Top, LRect.Width, LRect.Height);
        LPath.AddEllipse(LGPRect);

        LSize := MulDiv(2, CurrentPPI, Screen.DefaultPixelsPerInch);
        InflateRect(LRect, LSize, LSize);
        LGPRect := MakeRect(LRect.Left, LRect.Top, LRect.Width, LRect.Height);
        LPath.AddEllipse(LGPRect);

        LGPGraphics.DrawPath(LGPPen, LPath);
      finally
        LPath.Free;
      end;
    finally
     LGPPen.Free;
    end;
  finally
    LGPGraphics.Free;
  end;
end;

procedure TFrmMain.SystemTitlebarButton1Click(Sender: TObject);
begin
  ShowMessage('You clicked the custom caption button !!!!!!');
end;

procedure TFrmMain.SystemTitlebarButton1Paint(Sender: TObject);
begin
  DrawSymbol(TSystemTitlebarButton(Sender).Canvas, TSystemTitlebarButton(Sender).ClientRect,
    IfThen(Active, CustomTitleBar.ButtonForegroundColor, CustomTitleBar.ButtonInactiveForegroundColor),
    IfThen(Active, CustomTitleBar.ButtonBackgroundColor, CustomTitleBar.ButtonInactiveBackgroundColor));
end;

procedure TFrmMain.TitleBarPanel1Paint(Sender: TObject; Canvas: TCanvas;
  var ARect: TRect);
const
  AlignStyles: array [TAlignment] of TTextFormats = (tfLeft, tfRight, tfCenter);
  cDefaultGlowSize = 20;
var
  LTextOptions: TStyleTextOptions;
  LTextFormat: TTextFormat;
  s: string;
  LRect: TRect;
  LBitmap: TBitmap;
  BlendFunc: TBlendFunction;
begin
  if CheckBoxOnPaint.Checked then
  begin
    //Bitmap
    LRect := ARect;
    LBitmap := TBitmap.Create;
    try
      LBitmap.PixelFormat := pf32bit;
      LBitmap.SetSize(ScaleValue(200), LRect.Height div 2);
      if Active then
        GradientFillCanvas(LBitmap.Canvas, clWebLightYellow, clWebGreen,
          Rect(0, 0, LBitmap.Width, LBitmap.Height), TGradientDirection.gdHorizontal)
      else
        GradientFillCanvas(LBitmap.Canvas, clWebCornSilk, clWebAzure,
          Rect(0, 0, LBitmap.Width, LBitmap.Height), TGradientDirection.gdHorizontal);

      //LBitmap.AlphaFormat := afPremultiplied;
      SetPreMutipliedAlpha(LBitmap);

      BlendFunc.BlendOp := AC_SRC_OVER;
      BlendFunc.BlendFlags := 0;
      BlendFunc.SourceConstantAlpha := 255;
      BlendFunc.AlphaFormat := AC_SRC_ALPHA;
      Winapi.Windows.AlphaBlend(Canvas.Handle, (Width - LBitmap.Width) div 2,
        ScaleValue(30), LBitmap.Width, LBitmap.Height,
      LBitmap.Canvas.Handle, 0, 0, LBitmap.Width, LBitmap.Height, BlendFunc);
    finally
      LBitmap.Free;
    end;

    //  drawing a text
    LTextOptions.GlowSize := cDefaultGlowSize;
    LTextOptions.Flags := [stfTextColor, stfGlowSize];

    if Active then
      LTextOptions.TextColor := clWebDarkRed
    else
      LTextOptions.TextColor := clBlue;

    LTextFormat := [tfSingleLine, tfVerticalCenter, tfEndEllipsis, tfComposited];
    Include(LTextFormat, AlignStyles[taCenter]);

    Inc(LRect.Top, ScaleValue(20));
    s := 'Sample Text OnPaint event';
    TStyleManager.SystemStyle.DrawText(Canvas.Handle,
      TStyleManager.SystemStyle.GetElementDetails(twCaptionActive), s, LRect,
      LTextFormat, LTextOptions);
  end;
end;

end.
