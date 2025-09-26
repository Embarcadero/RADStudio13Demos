unit LBMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.Chat, Data.Bind.Components,
  Data.Bind.ObjectScope, SmartCoreAI.LiveBindings.Core, SmartCoreAI.Types,
  SmartCoreAI.Driver.OpenAI, Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti,
  System.Bindings.Outputs, Vcl.Bind.Editors;

type
  TFrm_LBMain = class(TForm)
    AIConnection1: TAIConnection;
    AIOpenAIDriver1: TAIOpenAIDriver;
    AIChatBindSource1: TAIChatBindSource;
    AIChatRequest1: TAIChatRequest;
    Edit1: TEdit;
    BindingsList1: TBindingsList;
    LinkControlToField1: TLinkControlToField;
    Button1: TButton;
    Memo1: TMemo;
    LinkControlToField2: TLinkControlToField;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string   = 'ApiKey'; const AIniPath: string = ''): Boolean;
  public
    { Public declarations }
  end;

var
  Frm_LBMain: TFrm_LBMain;

implementation

uses
  System.IniFiles, System.IOUtils;

{$R *.dfm}

// SmartCoreAI Delphi Design-Time Demo - liveBinding sample.
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
