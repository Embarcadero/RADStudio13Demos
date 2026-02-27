//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit StreamMain;

interface

uses
  System.SysUtils, System.Classes, System.JSON, Vcl.Forms, Vcl.Controls,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Graphics, Data.DB, Vcl.DBGrids,
  FireDAC.Comp.Client, SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.Stream,
  SmartCoreAI.Types, SmartCoreAI.Consts, SmartCoreAI.Driver.OpenAI;

type
  TFrm_StreamMain = class(TForm)
    PanelTop: TPanel;
    BtnPickAudio: TButton;
    MemoLog: TMemo;
    OpenDialog1: TOpenDialog;
    AIConnection: TAIConnection;
    AIOpenAIDriver: TAIOpenAIDriver;
    StreamReq: TAIStreamRequest;
    BtnCancel: TButton;
    procedure StreamReqPartial(Sender: TObject; const APartialData: TBytes);
    procedure StreamReqSuccess(Sender: TObject; const AStream: TStream);
    procedure StreamReqError(Sender: TObject; const AErrorMessage: string);
    procedure BtnPickAudioClick(Sender: TObject);
    procedure AIOpenAIDriverError(Sender: TObject; const ErrorMessage: string);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
  private
    FLastRequestId: TGUID;
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  end;

var
  Frm_StreamMain: TFrm_StreamMain;

implementation

uses
  System.IniFiles, System.IOUtils;

{$R *.dfm}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIOpenAIDriver, TAIStreamRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_StreamMain.StreamReqError(Sender: TObject; const AErrorMessage: string);
begin
  MemoLog.Lines.Add('ERROR: ' + AErrorMessage);
end;

procedure TFrm_StreamMain.StreamReqPartial(Sender: TObject; const APartialData: TBytes);
begin
  MemoLog.Lines.Add('Partial bytes: ' + IntToStr(Length(APartialData)));
end;

procedure TFrm_StreamMain.StreamReqSuccess(Sender: TObject; const AStream: TStream);
var
  S: TStringStream;
  OutFile: string;
begin
  S := TStringStream.Create('', TEncoding.UTF8);
  try
    try
      S.CopyFrom(AStream, 0);
      MemoLog.Lines.Add('Success (text): ' + S.DataString);
    except
      OutFile := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + 'output.bin';
      AStream.Position := 0;
      with TFileStream.Create(OutFile, fmCreate) do
      try
        CopyFrom(AStream, 0)
      finally
        Free;
      end;
      MemoLog.Lines.Add('Binary saved to: ' + OutFile);
    end;
  finally
    S.Free
  end;
end;

procedure TFrm_StreamMain.AIOpenAIDriverCancel(Sender: TObject;
  const RequestId: TGUID);
begin
  MemoLog.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_StreamMain.AIOpenAIDriverError(Sender: TObject; const ErrorMessage: string);
begin
  MemoLog.Lines.Add(ErrorMessage);
end;

procedure TFrm_StreamMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIOpenAIDriver.Cancel(FLastRequestId);
end;

procedure TFrm_StreamMain.BtnPickAudioClick(Sender: TObject);
var
  LParams: TJSONObject;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIOpenAIParams(AIOpenAIDriver.Params).APIKey := LAPIKey;

    if not OpenDialog1.Execute then Exit;
    LParams := TJSONObject.Create;
    try
      StreamReq.InputFileName := OpenDialog1.FileName;
      StreamReq.Params := LParams;
      StreamReq.Endpoint := (TAIOpenAIParams(AIOpenAIDriver.Params)).EndPoint_TranscribeAudio;
      MemoLog.Lines.Add('Uploading audio: ' + OpenDialog1.FileName);
      FLastRequestId := StreamReq.Execute;
    finally
      LParams.Free;
    end;
  end;
end;

function TFrm_StreamMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
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
