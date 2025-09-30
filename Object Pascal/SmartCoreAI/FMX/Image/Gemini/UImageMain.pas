unit UImageMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, SmartCoreAI.Types,
  SmartCoreAI.Driver.Gemini, SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.Image,
  FMX.Memo.Types, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Edit,
  FMX.Controls.Presentation, System.IniFiles, System.IOUtils,
  System.JSON;

type
  TFrm_ImageMain = class(TForm)
    AIConnection1: TAIConnection;
    AIImageRequest1: TAIImageRequest;
    AIGeminiDriver1: TAIGeminiDriver;
    Panel1: TPanel;
    Edit1: TEdit;
    BtnGenerate: TButton;
    Image1: TImage;
    Memo1: TMemo;
    AniIndicator1: TAniIndicator;
    BtnCancel: TButton;
    procedure AIImageRequest1Error(Sender: TObject; const ErrorMessage: string);
    procedure AIImageRequest1Success(Sender: TObject;
      const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>;
      FullResponse: string);
    procedure BtnGenerateClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIGeminiDriver1Cancel(Sender: TObject; const RequestId: TGUID);
    procedure FormCreate(Sender: TObject);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'Gemini'; const AIdent: string = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  Frm_ImageMain: TFrm_ImageMain;

implementation

uses
  SmartCoreAI.Driver.Gemini.Models{$IF NOT DEFINED(ANDROID)}, FMX.DialogService.Sync{$ENDIF};

{$R *.fmx}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIGeminiDriver, TAIImageRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_ImageMain.ActivityMonitor(const AStatus: Boolean);
begin
  AniIndicator1.Enabled := AStatus;
  AniIndicator1.Visible := AStatus;
end;

procedure TFrm_ImageMain.AIGeminiDriver1Cancel(Sender: TObject;
  const RequestId: TGUID);
begin
  Memo1.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  ActivityMonitor(False);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_ImageMain.AIImageRequest1Error(Sender: TObject; const ErrorMessage: string);
begin
  AniIndicator1.Enabled := False;
  AniIndicator1.Visible := False;
  Memo1.Lines.Add('ERROR: ' + ErrorMessage);
end;

procedure TFrm_ImageMain.AIImageRequest1Success(Sender: TObject;
  const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>;
  FullResponse: string);
var
  Src: TStream;
  Tmp: TMemoryStream;
begin
  AniIndicator1.Enabled := False;
  AniIndicator1.Visible := False;

  if Length(Images) = 0 then
  begin
    Memo1.Lines.Add('No image returned.');
    Exit;
  end;

  Src := Images[0].ImageStream;
  if Assigned(Src) then
  begin
    try
      // Some streams may not be seekable; copy to a temp memory stream if needed
      try
        Src.Position := 0;
        Image1.Bitmap.LoadFromStream(Src);
      except
        // Fallback: copy to memory, then load
        Tmp := TMemoryStream.Create;
        try
          Src.Position := 0;
          Tmp.CopyFrom(Src, Src.Size);
          Tmp.Position := 0;
          Image1.Bitmap.LoadFromStream(Tmp);
        finally
          Tmp.Free;
        end;
      end;
      Memo1.Lines.Add('Image assigned to TImage.');
    except
      on E: Exception do
        Memo1.Lines.Add('Failed to load image from stream: ' + E.Message);
    end;
    Exit;
  end;

  if not Images[0].ImageURL.IsEmpty then
  begin
    var LDownStream := TAIUtil.DownloadImage(Images[0].ImageURL);
    try
      if Assigned(LDownStream) then
      begin
        LDownStream.Position := 0;
        Image1.Bitmap.LoadFromStream(LDownStream);
        Memo1.Lines.Add('Image assigned to TImage.');
      end
      else
        Memo1.Lines.Add('Download failed.');
    finally
      LDownStream.Free;
    end;
    Exit;
  end;
  Memo1.Lines.Add('No bitmap in result.');
end;

procedure TFrm_ImageMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIGeminiDriver1.Cancel(FLastRequestId);
end;

procedure TFrm_ImageMain.BtnGenerateClick(Sender: TObject);
var
  LReqGemini: IAIImageGenerationRequest;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIGeminiParams(AIGeminiDriver1.Params).APIKey := LAPIKey;
    LReqGemini := nil;
    AniIndicator1.Enabled := True;
    AniIndicator1.Visible := True;
    Memo1.Lines.Add('Requesting image...');
    LReqGemini := TAIGeminiGenerateImageRequest.Create;
    LReqGemini.Prompt := Edit1.Text;
    AIImageRequest1.APIRequestObject := LReqGemini;
    AIImageRequest1.Execute;
  end;
end;

procedure TFrm_ImageMain.FormCreate(Sender: TObject);
begin
  ActivityMonitor(False);
end;

procedure TFrm_ImageMain.FormResize(Sender: TObject);
begin
  AniIndicator1.Position.X := (Self.ClientWidth  - AniIndicator1.Width) / 2;
  AniIndicator1.Position.Y  := (Self.ClientHeight - AniIndicator1.Height) / 2;
end;

{$IF NOT DEFINED(ANDROID)}
function PromptForApiKey(var S: string): Boolean;
var
  Values: TArray<string>;
begin
  SetLength(Values, 1);
  Values[0] := S;
  Result := TDialogServiceSync.InputQuery('Please Enter the API Key', ['API Key'], Values);
  if Result and (Length(Values) > 0) then
    S := Values[0];
end;
{$ENDIF}

function TFrm_ImageMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
var
  IniFileName: string;
  Ini: TIniFile;
  Tmp: string;
begin
  AApiKey := TAIGeminiParams(AIGeminiDriver1.Params).APIKey;
  if not AApiKey.IsEmpty then
    Exit(True);

  IniFileName := AIniPath;
  if IniFileName = '' then
    IniFileName := TPath.ChangeExtension(ParamStr(0), '.ini');

  Ini := TIniFile.Create(IniFileName);
  try
    Tmp := Trim(Ini.ReadString(ASection, AIdent, ''));
   {$IF NOT DEFINED(ANDROID)}
    while Tmp = '' do
    begin
      if not PromptForApiKey(Tmp) then
        Exit(False); // user cancelled
      Tmp := Trim(Tmp);
    end;
   {$ELSE}
    if Tmp.IsEmpty then
      Exit(False);
   {$ENDIF}

    if Ini.ReadString(ASection, AIdent, '') <> Tmp then
      Ini.WriteString(ASection, AIdent, Tmp);

    AApiKey := Tmp;
    Result := True;
  finally
    Ini.Free;
  end;
end;
end.
