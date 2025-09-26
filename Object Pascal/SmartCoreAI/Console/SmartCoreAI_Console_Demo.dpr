//---------------------------------------------------------------------------

// This software is Copyright (c) 2025 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

program SmartCoreAI_Console_Demo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.SyncObjs,
  System.StrUtils,
  SmartCoreAI.Comp.Connection,
  SmartCoreAI.Comp.Chat,
  SmartCoreAI.Driver.OpenAI,
  SmartCoreAI.Driver.Claude,
  SmartCoreAI.Driver.Ollama,
  SmartCoreAI.Driver.Gemini,
  SmartCoreAI.Types,
  SmartCoreAI.Consts;

type
  TConsoleHandlers = class
  private
    FDone: TEvent;
  public
    constructor Create(ADone: TEvent);
    procedure OnResponse(Sender: TObject; const Text: string);
    procedure OnError(Sender: TObject; const ErrorMessage: string);
  end;

{ TConsoleHandlers }

constructor TConsoleHandlers.Create(ADone: TEvent);
begin
  inherited Create;
  FDone := ADone;
end;

procedure TConsoleHandlers.OnResponse(Sender: TObject; const Text: string);
begin
  Writeln('AI: ' + Text);
  FDone.SetEvent; // signal completion for the current turn
end;

procedure TConsoleHandlers.OnError(Sender: TObject; const ErrorMessage: string);
begin
  Writeln('ERROR: ' + ErrorMessage);
  FDone.SetEvent; // unblock the loop even on error
end;

function AskLine(const APrompt: string): string;
begin
  Write(APrompt);
  Readln(Result);
end;

function CreateDriverByName(const AName: string): TAIDriver;
var
  L: string;
begin
  L := Trim(LowerCase(AName));
  if (L = 'openai') or (L = 'o') then
    Exit(TAIOpenAIDriver.Create(nil));
  if (L = 'claude') or (L = 'c') then
    Exit(TAIClaudeDriver.Create(nil));
  if (L = 'gemini') or (L = 'g') then
    Exit(TAIGeminiDriver.Create(nil));
  if (L = 'ollama') or (L = 'ol') then
    Exit(TAIOllamaDriver.Create(nil));

  // default
  Writeln('Unknown driver: ', AName, ' → using OpenAI.');
  Result := TAIOpenAIDriver.Create(nil);
end;

procedure ConfigureDriverParams(const ADriver: TAIDriver);
var
  S: string;
begin
  // Fill minimal sensible defaults. Replace with your own.
  if ADriver is TAIOpenAIDriver then
  begin
    with TAIOpenAIParams(ADriver.Params) do
    begin
      BaseURL := cOpenAI_BaseURL;
      Model   := 'gpt-4o-mini';
      MaxToken := 1024;
      S := AskLine('Enter OpenAI API key (sk-...): ');
      APIKey := S.Trim;
    end;
    Exit;
  end
  else if ADriver is TAIClaudeDriver then
  begin
    with TAIClaudeParams(ADriver.Params) do
    begin
      BaseURL          := cClaude_BaseURL;
      AnthropicVersion := '2023-06-01';
      Model            := 'claude-sonnet-4-20250514';
      MaxToken         := 1024;
      S := AskLine('Enter Anthropic API key: ');
      APIKey := S.Trim;
    end;
    Exit;
  end
  else if ADriver is TAIGeminiDriver then
  begin
    with TAIGeminiParams(ADriver.Params) do
    begin
      BaseURL := cGemini_BaseURL;
      Model   := 'gemini-2.0-flash';
      S := AskLine('Enter Gemini API key: ');
      APIKey := S.Trim;
    end;
    Exit;
  end
  else if ADriver is TAIOllamaDriver then
  begin
    with TAIOllamaParams(ADriver.Params) do
    begin
      BaseURL := cOllama_BaseURL;
      Model := 'llama3'; // or any local model name you have pulled
    end;
  end;
end;

procedure RunLoop;
var
  Driver : TAIDriver;
  Conn   : TAIConnection;
  Chat   : TAIChatRequest;
  Done   : TEvent;
  H      : TConsoleHandlers;
  Line   : string;
  DName  : string;
begin
  DName := AskLine('Driver [openai/claude/gemini/ollama]: ');
  Driver := CreateDriverByName(DName);
  Conn   := TAIConnection.Create(nil);
  Chat   := TAIChatRequest.Create(nil);
  Done   := TEvent.Create(nil, True, False, '');
  H      := TConsoleHandlers.Create(Done);

  try
    ConfigureDriverParams(Driver);
    Driver.SynchronizeEvents := False;
    Conn.Driver      := Driver;
    Chat.Connection  := Conn;
    Chat.OnResponse  := H.OnResponse;
    Chat.OnError     := H.OnError;

    Writeln('Type /quit to exit.');
    while True do
    begin
      Line := AskLine('You: ');
      if SameText(Line.Trim, '/quit') then
        Break;

      Done.ResetEvent;
      Chat.Chat(Line);           // async call
      Done.WaitFor(INFINITE);    // wait until OnResponse/OnError signals
    end;
  finally
    H.Free;
    Done.Free;
    Chat.Free;
    Conn.Free;
    Driver.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    RunLoop;
  except
    on E: Exception do
      Writeln('FATAL: ', E.ClassName, ': ', E.Message);
  end;
end.

