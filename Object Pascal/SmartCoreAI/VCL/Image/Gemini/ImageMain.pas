//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit ImageMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, SmartCoreAI.Comp.Connection,
  SmartCoreAI.Comp.Image, SmartCoreAI.Types, SmartCoreAI.Consts, SmartCoreAI.Driver.Gemini,
  Vcl.WinXCtrls, SmartCoreAI.Driver.Gemini.Models, System.JSON;

type
  TFormImage = class(TForm)
    PanelTop: TPanel;
    EditPrompt: TEdit;
    BtnGen: TButton;
    Img: TImage;
    MemoLog: TMemo;
    AIConnection: TAIConnection;
    AIGeminiDriver: TAIGeminiDriver;
    ActivityIndicator1: TActivityIndicator;
    ImgReq: TAIImageRequest;
    BtnCancel: TButton;
    procedure BtnGenClick(Sender: TObject);
    procedure ImgReqError(Sender: TObject; const ErrorMessage: string);
    procedure ImgReqSuccess(Sender: TObject; const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>; FullResponse: string);
    procedure FormResize(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIGeminiDriverCancel(Sender: TObject; const RequestId: TGUID);
    procedure FormCreate(Sender: TObject);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'Gemini'; const AIdent: string = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  FormImage: TFormImage;

implementation

uses
  System.IniFiles, System.IOUtils;

{$R *.dfm}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIGeminiDriver, TAIImageRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFormImage.ActivityMonitor(const AStatus: Boolean);
begin
  ActivityIndicator1.Visible := AStatus;
  ActivityIndicator1.Animate := AStatus;
end;

procedure TFormImage.AIGeminiDriverCancel(Sender: TObject;
  const RequestId: TGUID);
begin
  MemoLog.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  ActivityMonitor(False);
  FLastRequestId := Tguid.Empty;
end;

procedure TFormImage.ImgReqError(Sender: TObject; const ErrorMessage: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('ERROR: ' + ErrorMessage);
end;

procedure TFormImage.ImgReqSuccess(Sender: TObject;
  const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>;
  FullResponse: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('Generating image...');

  if Length(Images) > 0 then
  begin
    if Assigned(Images[0].ImageStream) then
    begin
      Img.Picture.LoadFromStream(Images[0].ImageStream);
      MemoLog.Lines.Add('Image assigned to TImage.');
    end
    else if not Images[0].ImageURL.IsEmpty then
    begin
      var LStream := TAIUtil.DownloadImage(Images[0].ImageURL);
      if Assigned(LStream) then
      begin
        Img.Picture.LoadFromStream(LStream);
        MemoLog.Lines.Add('Image assigned to TImage.');
      end;
      LStream.Free;
    end
    else
      MemoLog.Lines.Add('No image in result.');
  end
  else
    MemoLog.Lines.Add('No image returned.');
end;

procedure TFormImage.BtnGenClick(Sender: TObject);
var
  LReqGemini: IAIImageGenerationRequest;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    Img.Picture := nil;
    TAIGeminiParams(AIGeminiDriver.Params).APIKey := LAPIKey;
    LReqGemini := nil;
    ActivityMonitor(True);
    MemoLog.Lines.Add('Requesting image...');
    LReqGemini := TAIGeminiGenerateImageRequest.Create;
    LReqGemini.Prompt := EditPrompt.Text;
    ImgReq.APIRequestObject := LReqGemini;
    FLastRequestId := ImgReq.Execute;
  end;
end;

procedure TFormImage.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIGeminiDriver.Cancel(FLastRequestId);
end;

procedure TFormImage.FormCreate(Sender: TObject);
begin
  ActivityMonitor(False);
end;

procedure TFormImage.FormResize(Sender: TObject);
begin
  ActivityIndicator1.Left := (Self.ClientWidth  - ActivityIndicator1.Width)  div 2;
  ActivityIndicator1.Top  := (Self.ClientHeight - ActivityIndicator1.Height) div 2;
end;

function TFormImage.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
var
  IniFileName: string;
  Ini: TIniFile;
  Tmp: string;
begin
  AApiKey := TAIGeminiParams(AIGeminiDriver.Params).APIKey;
  if not AApiKey.IsEmpty then
    Exit(True);

  IniFileName := AIniPath;
  if IniFileName = '' then
    IniFileName := TPath.ChangeExtension(ParamStr(0), '.ini');

  Ini := TIniFile.Create(IniFileName);
  try
    Tmp := Trim(Ini.ReadString(ASection, AIdent, ''));
    while Tmp = '' do
    begin
      if not InputQuery('Please Enter the API Key', 'API Key', Tmp) then
        Exit(False); // user cancelled
      Tmp := Trim(Tmp);
    end;

    if Ini.ReadString(ASection, AIdent, '') <> Tmp then
      Ini.WriteString(ASection, AIdent, Tmp);

    AApiKey := Tmp;
    Result := True;
  finally
    Ini.Free;
  end;
end;

end.
