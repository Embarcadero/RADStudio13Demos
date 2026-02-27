unit LBMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Data.Bind.Components, SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.Chat,
  SmartCoreAI.Types, SmartCoreAI.Driver.OpenAI, Data.Bind.ObjectScope,
  SmartCoreAI.LiveBindings.Core, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Edit, Fmx.Bind.Editors,
  System.IniFiles, System.IOUtils;

type
  TFrm_LBMain = class(TForm)
    AIChatBindSource1: TAIChatBindSource;
    AIConnection1: TAIConnection;
    AIOpenAIDriver1: TAIOpenAIDriver;
    AIChatRequest1: TAIChatRequest;
    BindingsList1: TBindingsList;
    Button1: TButton;
    Edit1: TEdit;
    Memo1: TMemo;
    LinkControlToField3: TLinkControlToField;
    LinkControlToField4: TLinkControlToField;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  Frm_LBMain: TFrm_LBMain;

implementation

{$IF NOT DEFINED(ANDROID)}
uses
  FMX.DialogService.Sync;
{$ENDIF}

{$R *.fmx}

// SmartCoreAI Delphi Design-Time FMX Demo - liveBinding sample.
// Components: TAIConnection, TAIOpenAIDriver, TAIChatRequest, TAIChatBindSource, TBindingsList.
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_LBMain.Button1Click(Sender: TObject);
var
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIOpenAIParams(AIOpenAIDriver1.Params).APIKey := LAPIKey;
    AIChatRequest1.Chat('Hello!');
  end;
end;

procedure TFrm_LBMain.FormCreate(Sender: TObject);
begin
  AIChatBindSource1.SetChatRequest(AIChatRequest1);
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

function TFrm_LBMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
var
  IniFileName: string;
  Ini: TIniFile;
  Tmp: string;
begin
  AApiKey := TAIOpenAIParams(AIOpenAIDriver1.Params).APIKey;
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
