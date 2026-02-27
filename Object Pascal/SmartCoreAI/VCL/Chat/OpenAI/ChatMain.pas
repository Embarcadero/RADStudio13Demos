//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit ChatMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, SmartCoreAI.Comp.Connection,
  SmartCoreAI.Comp.Chat, SmartCoreAI.Driver.OpenAI, SmartCoreAI.Types, SmartCoreAI.Consts,
  Vcl.WinXCtrls;

type
  TFrm_ChatMain = class(TForm)
    PanelTop: TPanel;
    EditPrompt: TEdit;
    BtnSend: TButton;
    MemoLog: TMemo;
    AIConnection: TAIConnection;
    AIOpenAIDriver: TAIOpenAIDriver;
    AIChatRequest1: TAIChatRequest;
    BtnCancel: TButton;
    ActivityIndicator1: TActivityIndicator;
    procedure AIChatRequest1Response(Sender: TObject; const Text: string);
    procedure BtnSendClick(Sender: TObject);
    procedure AIChatRequest1Error(Sender: TObject; const ErrorMessage: string);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
    procedure AIOpenAIDriverChatSuccess(Sender: TObject; const ResponseText,
      FullJsonResponse: string);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  end;

var
  Frm_ChatMain: TFrm_ChatMain;

implementation

uses
  System.IniFiles, System.IOUtils, SmartCoreAI.Driver.OpenAI.Models;

{$R *.dfm}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIOpenAIDriver, TAIChatRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// Set parameters via Object Inspecor.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.


procedure TFrm_ChatMain.ActivityMonitor(const AStatus: Boolean);
begin
  ActivityIndicator1.Visible := AStatus;
  ActivityIndicator1.Animate := AStatus;
end;

procedure TFrm_ChatMain.AIChatRequest1Error(Sender: TObject; const ErrorMessage: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('ERROR: ' + ErrorMessage);
end;

procedure TFrm_ChatMain.AIChatRequest1Response(Sender: TObject; const Text: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('AI: ' + Text);
end;

procedure TFrm_ChatMain.AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('Cancelled, RequestId:' + RequestId.ToString);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_ChatMain.AIOpenAIDriverChatSuccess(Sender: TObject;
  const ResponseText, FullJsonResponse: string);
begin
  ActivityMonitor(False);
  MemoLog.Lines.Add('AI: ' + ResponseText);
end;

procedure TFrm_ChatMain.BtnSendClick(Sender: TObject);
var
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIOpenAIParams(AIOpenAIDriver.Params).APIKey := LAPIKey;
    if EditPrompt.Text = '' then
      Exit;

    ActivityMonitor(True);
    MemoLog.Lines.Add('You: ' + EditPrompt.Text);

    //Option A: using AIChatRequest component
    //The response will be available in AIChatRequest1Response event.
    FLastRequestId := AIChatRequest1.Chat(EditPrompt.Text);

    {
    //Option B-1: using the ChatEx method of the Driver.
    //The response will be available in AIOpenAIDriverChatSuccess event.
    var LReq := TOpenAIChatRequest.Create;
    LReq.Messages.Add(TAIChatMessage.Create(cmrUser, EditPrompt.Text));
    FLastRequestId := AIOpenAIDriver.ChatEx(LReq); // No need to free Lreq, it will be handled by library.
    }

    {
    //Option B-2: SimpleChat
    //The response will be available in AIOpenAIDriverChatSuccess event.
    AIOpenAIDriver.SimpleChat(EditPrompt.Text);
    }
  end;
end;

procedure TFrm_ChatMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIOpenAIDriver.Cancel(FLastRequestId); // or AIOpenAIDriver.CancelAll;
end;

procedure TFrm_ChatMain.FormCreate(Sender: TObject);
begin
  ActivityMonitor(False);
end;

procedure TFrm_ChatMain.FormResize(Sender: TObject);
begin
  ActivityIndicator1.Left := (Self.ClientWidth  - ActivityIndicator1.Width)  div 2;
  ActivityIndicator1.Top  := (Self.ClientHeight - ActivityIndicator1.Height) div 2;
end;

function TFrm_ChatMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
var
  IniFileName: string;
  Ini: TIniFile;
  Tmp: string;
begin
  AApiKey := TAIOpenAIParams(AIOpenAIDriver.Params).APIKey;
  if not AApiKey.IsEmpty then
    Exit(True);

  AApiKey := '';
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
