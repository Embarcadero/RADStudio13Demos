unit UChatMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.Chat, SmartCoreAI.Types,
  SmartCoreAI.Driver.OpenAI, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit, System.IniFiles,
  System.IOUtils;

type
  TFrm_ChatMain = class(TForm)
    AIConnection: TAIConnection;
    AIOpenAIDriver: TAIOpenAIDriver;
    AIChatRequest1: TAIChatRequest;
    Panel1: TPanel;
    Edit1: TEdit;
    BtnSend: TButton;
    Memo1: TMemo;
    BtnCancel: TButton;
    procedure BtnSendClick(Sender: TObject);
    procedure AIChatRequest1Response(Sender: TObject; const Text: string);
    procedure AIChatRequest1Error(Sender: TObject; const ErrorMessage: string);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIOpenAIDriverCancel(Sender: TObject; const RequestId: TGUID);
    procedure AIChatRequest1FullResponse(Sender: TObject;
      const FullJsonResponse: string);
  private
    FLastRequestId: TGUID;
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  Frm_ChatMain: TFrm_ChatMain;

implementation
{$IF NOT DEFINED(ANDROID)}
uses
  FMX.DialogService.Sync;
{$ENDIF}

{$R *.fmx}

// SmartCoreAI Delphi Design-Time Demo - FMX sample
// Components: TAIConnection, TAIOpenAIDriver, TAIChatRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// Possible to set parameters via Object Inspecor.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_ChatMain.AIChatRequest1Error(Sender: TObject; const ErrorMessage: string);
begin
  Memo1.Lines.Add('ERROR: ' + ErrorMessage);
end;

procedure TFrm_ChatMain.AIChatRequest1FullResponse(Sender: TObject;
  const FullJsonResponse: string);
begin
  Memo1.Lines.Add('=======================================');
  Memo1.Lines.Add('===== Full Http Response content ======');
  Memo1.Lines.Add('=======================================');
  Memo1.Lines.Add(FullJsonResponse);
  Memo1.Lines.Add('=======================================');
end;

procedure TFrm_ChatMain.AIChatRequest1Response(Sender: TObject; const Text: string);
begin
  Memo1.Lines.Add('=======================================');
  Memo1.Lines.Add('======== The actual answer ============');
  Memo1.Lines.Add('=======================================');
  Memo1.Lines.Add('AI: ' + Text);
  Memo1.Lines.Add('=======================================');
end;

procedure TFrm_ChatMain.AIOpenAIDriverCancel(Sender: TObject;
  const RequestId: TGUID);
begin
  Memo1.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  FLastRequestId := TGUID.Empty;
end;

procedure TFrm_ChatMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIOpenAIDriver.Cancel(FLastRequestId);
end;

procedure TFrm_ChatMain.BtnSendClick(Sender: TObject);
var
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    if Edit1.Text = '' then
      Exit;

    TAIOpenAIParams(AIOpenAIDriver.Params).APIKey := LAPIKey;
    Memo1.Lines.Add('You: ' + Edit1.Text);
    AIChatRequest1.Chat(Edit1.Text);
  end;
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

function TFrm_ChatMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
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
