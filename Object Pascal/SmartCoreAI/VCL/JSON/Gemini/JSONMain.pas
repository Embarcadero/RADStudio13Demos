//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit JSONMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, SmartCoreAI.Comp.Connection,
  SmartCoreAI.Comp.JSON, SmartCoreAI.Types, SmartCoreAI.Consts, SmartCoreAI.Driver.Gemini,
  Data.DB, Vcl.DBGrids, Vcl.Grids, System.JSON, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.WinXCtrls;

type
  TFrm_JsonMain = class(TForm)
    PanelTop: TPanel;
    EditText: TEdit;
    BtnSend: TButton;
    Grid: TDBGrid;
    MemoRaw: TMemo;
    AIConnection: TAIConnection;
    AIGeminiDriver: TAIGeminiDriver;
    JsonReq: TAIJSONRequest;
    DataSource1: TDataSource;
    FDMemTable1: TFDMemTable;
    ActivityIndicator1: TActivityIndicator;
    BtnCancel: TButton;
    procedure JsonReqError(Sender: TObject; const ErrorMessage: string);
    procedure FormCreate(Sender: TObject);
    procedure BtnSendClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure JsonReqSuccess(Sender: TObject; const AResponse: string);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIGeminiDriverCancel(Sender: TObject; const RequestId: TGUID);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'Gemini'; const AIdent: string = 'ApiKey'; const AIniPath: string = ''): Boolean;
  end;

var
  Frm_JsonMain: TFrm_JsonMain;

implementation

uses
  System.IniFiles, System.IOUtils;

{$R *.dfm}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIGeminiDriver, TAIJSONRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_JsonMain.FormCreate(Sender: TObject);
begin
  DataSource1.DataSet := JsonReq.DataSet;
  JsonReq.Endpoint := (TAIGeminiParams(AIGeminiDriver.Params)).Endpoint_GenerateContent;
  ActivityMonitor(False);
end;

procedure TFrm_JsonMain.FormResize(Sender: TObject);
begin
  ActivityIndicator1.Left := (Self.ClientWidth  - ActivityIndicator1.Width)  div 2;
  ActivityIndicator1.Top  := (Self.ClientHeight - ActivityIndicator1.Height) div 2;
end;

procedure TFrm_JsonMain.JsonReqError(Sender: TObject; const ErrorMessage: string);
begin
  ActivityMonitor(False);
  MemoRaw.Lines.Text := ErrorMessage;
end;

procedure TFrm_JsonMain.JsonReqSuccess(Sender: TObject; const AResponse: string);
begin
  ActivityMonitor(False);
  MemoRaw.Lines.Text := AResponse;
end;

procedure TFrm_JsonMain.ActivityMonitor(const AStatus: Boolean);
begin
  ActivityIndicator1.Visible := AStatus;
  ActivityIndicator1.Animate := AStatus;
end;

procedure TFrm_JsonMain.AIGeminiDriverCancel(Sender: TObject;
  const RequestId: TGUID);
begin
  MemoRaw.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  ActivityMonitor(False);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_JsonMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIGeminiDriver.Cancel(FLastRequestId);
end;

procedure TFrm_JsonMain.BtnSendClick(Sender: TObject);
var
  LParams: TJSONObject;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIGeminiParams(AIGeminiDriver.Params).APIKey := LAPIKey;

    ActivityMonitor(True);

    LParams := TJSONObject.Create;
    try
      LParams.AddPair('contents', TJSONObject.Create.AddPair('parts', TJSONArray.Create(TJSONObject.Create.AddPair('text', EditText.Text))));
      JsonReq.Params := LParams.ToJSON;
      MemoRaw.Lines.Clear;
      FLastRequestId := JsonReq.Execute; // If a Dataset populated then you will see the data in the Grid.
    finally
      LParams.Free;
    end;
  end;
end;

function TFrm_JsonMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
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
