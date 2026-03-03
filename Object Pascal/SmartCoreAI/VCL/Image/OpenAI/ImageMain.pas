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
  SmartCoreAI.Comp.Image, SmartCoreAI.Types, SmartCoreAI.Consts, SmartCoreAI.Driver.OpenAI,
  Vcl.WinXCtrls, System.JSON;

type
  TFrm_ImageMain = class(TForm)
    PanelTop: TPanel;
    EditPrompt: TEdit;
    BtnGen: TButton;
    Img: TImage;
    MemoLog: TMemo;
    AIConnection: TAIConnection;
    AIOpenAIDriver: TAIOpenAIDriver;
    ImgReq: TAIImageRequest;
    ActivityIndicator1: TActivityIndicator;
    BtnCancel: TButton;
    procedure ImgReqError(Sender: TObject; const ErrorMessage: string);
    procedure BtnGenClick(Sender: TObject);
    procedure ImgReqSuccess(Sender: TObject;
      const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>;
      FullResponse: string);
    procedure FormResize(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  Frm_ImageMain: TFrm_ImageMain;

implementation

uses
  SmartCoreAI.Driver.OpenAI.Models, System.IniFiles, System.IOUtils;

{$R *.dfm}

 // SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIOpenAIDriver, TAIImageRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_ImageMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  AIOpenAIDriver.CancelAll; //This is obligatory to avoid unexpected exceptions.
end;

procedure TFrm_ImageMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not AIOpenAIDriver.IsRunning;
  if not CanClose then
  begin
    ActivityMonitor(True);
    AIOpenAIDriver.CancelAll;
    MemoLog.Lines.Add('Cancelling all operations, try again later...');
  end;
end;

procedure TFrm_ImageMain.FormCreate(Sender: TObject);
begin
  ActivityMonitor(False);
end;

procedure TFrm_ImageMain.FormResize(Sender: TObject);
begin
  ActivityIndicator1.Left := (Self.ClientWidth  - ActivityIndicator1.Width)  div 2;
  ActivityIndicator1.Top  := (Self.ClientHeight - ActivityIndicator1.Height) div 2;
end;

procedure TFrm_ImageMain.ImgReqError(Sender: TObject; const ErrorMessage: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('Error: ' + ErrorMessage);
end;

procedure TFrm_ImageMain.ImgReqSuccess(Sender: TObject;
  const Images: TArray<SmartCoreAI.Types.IAIImageGenerationResult>;
  FullResponse: string);
var
  I: Integer;
begin
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
      try
        if Assigned(LStream) then
        begin
          Img.Picture.LoadFromStream(LStream);
          MemoLog.Lines.Add('Image assigned to TImage.');
        end;
      finally
        LStream.Free;
      end;
    end
    else
      MemoLog.Lines.Add('No image in result.');
  end
  else
    MemoLog.Lines.Add('No image returned.');

  for I := 0 to Pred(Length(Images)) do
    Images[I] := nil;

  ActivityMonitor(False);
  FLastRequestId := TGUID.Empty;
end;

procedure TFrm_ImageMain.ActivityMonitor(const AStatus: Boolean);
begin
  ActivityIndicator1.Visible := AStatus;
  ActivityIndicator1.Animate := AStatus;
end;

procedure TFrm_ImageMain.AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_ImageMain.BtnCancelClick(Sender: TObject);
begin
  if not FLastRequestId.IsEmpty then
    AIOpenAIDriver.Cancel(FLastRequestId); // OR AIOpenAIDriver.CancelAll;
end;

procedure TFrm_ImageMain.BtnGenClick(Sender: TObject);
var
  ReqOpenAI: TAIOpenAIImageGenerationRequest;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    Img.Picture := nil;
    TAIOpenAIParams(AIOpenAIDriver.Params).APIKey := LAPIKey;
    MemoLog.Lines.Add('Requesting image...');
    ActivityMonitor(True);

    ReqOpenAI := TAIOpenAIImageGenerationRequest.Create;
    ReqOpenAI.Prompt := EditPrompt.Text;
    ReqOpenAI.Size := '1024x1024';
    ReqOpenAI.Quality := 'standard';
    ReqOpenAI.ResponseFormat := 'png';
    ReqOpenAI.Model := 'dall-e-3';

    // Set other parameters of ReqOpenAI here if needed.

    ImgReq.APIRequestObject := ReqOpenAI;
    FLastRequestId := ImgReq.Execute;
  end;
end;

function TFrm_ImageMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
var
  IniFileName: string;
  Ini: TIniFile;
  Tmp: string;
begin
  AApiKey := TAIOpenAIParams(AIOpenAIDriver.Params).APIKey;
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
