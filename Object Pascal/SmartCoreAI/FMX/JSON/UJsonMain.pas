unit UJsonMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  System.Rtti, FMX.Grid.Style, FMX.Grid, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, System.JSON,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  SmartCoreAI.Comp.Connection, SmartCoreAI.Comp.JSON, SmartCoreAI.Types,
  SmartCoreAI.Driver.OpenAI, System.IniFiles, System.IOUtils,
  Data.Bind.Components, Data.Bind.DBScope, Fmx.Bind.Editors, Data.Bind.Grid;

type
  // Tiny helper that owns cached data and serves OnGetValue.
  TGridMemTableAdapter = class(TComponent)
  private
    FGrid: TGrid;
    FData: TArray<TArray<string>>; // [Row, Col]
    procedure GridGetValue(Sender: TObject; const Col, Row: Integer; var Value: TValue);
  public
    constructor Create(AOwner: TComponent; AGrid: TGrid); reintroduce;
    procedure LoadFromDataSet(ADataSet: TFDMemTable);
    procedure Clear;
  end;

  TFrm_JsonMain = class(TForm)
    AniIndicator1: TAniIndicator;
    Memo1: TMemo;
    Panel1: TPanel;
    Edit1: TEdit;
    BtnSend: TButton;
    Grid1: TGrid;
    AIConnection1: TAIConnection;
    AIOpenAIDriver1: TAIOpenAIDriver;
    AIJSONRequest1: TAIJSONRequest;
    DataSource1: TDataSource;
    FDMemTable1: TFDMemTable;
    BtnCancel: TButton;
    procedure BtnSendClick(Sender: TObject);
    procedure AIJSONRequest1Error(Sender: TObject; const ErrorMessage: string);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure AIJSONRequest1Success(Sender: TObject; const AResponse: string);
    procedure BtnCancelClick(Sender: TObject);
    procedure AIOpenAIDriver1Cancel(Sender: TObject; const RequestId: TGUID);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FLastRequestId: TGUID;
    procedure ActivityMonitor(const AStatus: Boolean);
    procedure PopulateGridFromMemTable(AGrid: TGrid; AMemTable: TFDMemTable);
    function EnsureApiKeyFromIni(out AApiKey: string; const ASection: string = 'OpenAI'; const AIdent: string = 'ApiKey'; const AIniPath: string = ''): Boolean;
    procedure ClearGrid(const AGrid: TGrid);
    procedure ClearDatasetSchema(ADataset: TDataSet);
  public
    { Public declarations }
  end;

var
  Frm_JsonMain: TFrm_JsonMain;

implementation

{$IF NOT DEFINED(ANDROID)}
uses
  FMX.DialogService.Sync;
{$ENDIF}

{$R *.fmx}

// SmartCoreAI Delphi Design-Time Demo
// Components: TAIConnection, TAIOpenAIDriver, TAIJSONRequest
// Uses SmartCoreAI.Consts for default endpoints and errors.
// The application will request the API key on its first run and save it to an INI file in the same directory as the executable.
// Each method call generates a request id (GUID) that could be used later for request cancellation.

procedure TFrm_JsonMain.ActivityMonitor(const AStatus: Boolean);
begin
  AniIndicator1.Enabled := AStatus;
  AniIndicator1.Visible := AStatus;
end;

procedure TFrm_JsonMain.AIJSONRequest1Error(Sender: TObject; const ErrorMessage: string);
begin
  AniIndicator1.Enabled := False;
  AniIndicator1.Visible := False;
  Memo1.Lines.Text := ErrorMessage;
end;

procedure TFrm_JsonMain.AIJSONRequest1Success(Sender: TObject;
  const AResponse: string);
begin
  ActivityMonitor(False);
  PopulateGridFromMemTable(Grid1, FDMemTable1);
  Memo1.Lines.Clear;
  Memo1.Lines.Add('Full Response:');
  Memo1.Lines.Add('');
  Memo1.Lines.Text := AResponse;
end;

procedure TFrm_JsonMain.AIOpenAIDriver1Cancel(Sender: TObject;
  const RequestId: TGUID);
begin
  Memo1.Lines.Add('Request Canceled, Request-Id:' + RequestId.ToString);
  ActivityMonitor(False);
  FLastRequestId := Tguid.Empty;
end;

procedure TFrm_JsonMain.BtnCancelClick(Sender: TObject);
begin
  if FLastRequestId <> TGUID.Empty then
    AIOpenAIDriver1.Cancel(FLastRequestId);
end;

procedure TFrm_JsonMain.BtnSendClick(Sender: TObject);
var
  LParams: TJSONObject;
  LAPIKey: string;
begin
  if EnsureApiKeyFromIni(LAPIKey) then
  begin
    TAIOpenAIParams(AIOpenAIDriver1.Params).APIKey := LAPIKey;
    AniIndicator1.Enabled := True;
    AniIndicator1.Visible := True;
    Memo1.Lines.Clear;
    ClearGrid(Grid1);
    ClearDatasetSchema(FDMemTable1);

    LParams := TJSONObject.Create;
    try
      LParams.AddPair('model', TAIOpenAIParams(AIOpenAIDriver1.Params).Model)
             .AddPair('text', TJSONObject.Create
             .AddPair('format', TJSONObject.Create
             .AddPair('type', 'json_object')))
             .AddPair('input', Edit1.Text);
      AIJSONRequest1.Params := LParams.ToJSON;
      FLastRequestId := AIJSONRequest1.Execute;
    finally
      LParams.Free;
    end;
  end;
end;

procedure TFrm_JsonMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ClearGrid(Grid1);

  Memo1.Lines.Clear;
  Memo1.Text := '';

  ClearDatasetSchema(FDMemTable1);
  FDMemTable1.Close;
  AIOpenAIDriver1.CancelAll;
end;

procedure TFrm_JsonMain.FormCreate(Sender: TObject);
begin
  FDMemTable1.FieldDefs.Add('Id', ftInteger);
  FDMemTable1.CreateDataSet;
  ActivityMonitor(False);
end;

procedure TFrm_JsonMain.FormResize(Sender: TObject);
begin
  AniIndicator1.Position.X := (Self.ClientWidth  - AniIndicator1.Width) / 2;
  AniIndicator1.Position.Y  := (Self.ClientHeight - AniIndicator1.Height) / 2;
end;

procedure TFrm_JsonMain.PopulateGridFromMemTable(AGrid: TGrid; AMemTable: TFDMemTable);
var
  Adapter: TGridMemTableAdapter;
begin
  if (AGrid = nil) or (AMemTable = nil) then Exit;

  if Assigned(AGrid.TagObject) and (AGrid.TagObject is TGridMemTableAdapter) then
  begin
    AGrid.TagObject.Free;
    AGrid.TagObject := nil;
  end;

  Adapter := TGridMemTableAdapter.Create(nil, AGrid);
  AGrid.TagObject := Adapter;
  Adapter.LoadFromDataSet(AMemTable);
end;

{ TGridMemTableAdapter }

constructor TGridMemTableAdapter.Create(AOwner: TComponent; AGrid: TGrid);
begin
  inherited Create(AOwner);
  FGrid := AGrid;
end;

procedure TGridMemTableAdapter.GridGetValue(Sender: TObject; const Col,
  Row: Integer; var Value: TValue);
begin
  if (Row >= 0) and (Row < Length(FData)) and
     (Col >= 0) and (Length(FData) > 0) and (Col < Length(FData[Row])) then
    Value := FData[Row, Col]
  else
    Value := '';
end;

procedure TGridMemTableAdapter.LoadFromDataSet(ADataSet: TFDMemTable);

  function NewColumnForField(const AOwner: TComponent; F: TField): TColumn;
  begin
    case F.DataType of
      ftBoolean:   Result := TCheckColumn.Create(AOwner);
      ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc:
                   Result := TIntegerColumn.Create(AOwner);
      ftFloat, ftSingle, ftExtended, ftCurrency, ftBCD, ftFMTBcd:
                   Result := TFloatColumn.Create(AOwner);
      ftDate:      Result := TDateColumn.Create(AOwner);
      ftTime:      Result := TTimeColumn.Create(AOwner);
      ftDateTime, ftTimeStamp, ftTimeStampOffset:
                   Result := TDateTimeColumn.Create(AOwner);
    else
      Result := TStringColumn.Create(AOwner);
    end;
    Result.Header   := F.DisplayLabel;
    Result.ReadOnly := F.ReadOnly;
    Result.Parent   := FGrid;
  end;

var
  Bmk: TBookmark;
  RowCount, ColCount, R, C: Integer;
begin
  if (FGrid = nil) or (ADataSet = nil) then Exit;
  if not ADataSet.Active then Exit;

  FGrid.BeginUpdate;
  try
    FGrid.OnGetValue := nil;
    FGrid.RowCount   := 0;

    FGrid.ClearColumns;
    for C := 0 to ADataSet.Fields.Count - 1 do
      NewColumnForField(FGrid, ADataSet.Fields[C]);

    ADataSet.DisableControls;
    try
      Bmk := ADataSet.GetBookmark;
      try
        RowCount := ADataSet.RecordCount;
        ColCount := ADataSet.Fields.Count;
        SetLength(FData, RowCount);
        for R := 0 to RowCount - 1 do
          SetLength(FData[R], ColCount);

        R := 0;
        ADataSet.First;
        while not ADataSet.Eof do
        begin
          for C := 0 to ColCount - 1 do
            FData[R, C] := ADataSet.Fields[C].DisplayText;
          Inc(R);
          ADataSet.Next;
        end;
      finally
        if ADataSet.BookmarkValid(Bmk) then
          ADataSet.GotoBookmark(Bmk);
        ADataSet.FreeBookmark(Bmk);
      end;
    finally
      ADataSet.EnableControls;
    end;

    FGrid.OnGetValue := GridGetValue;
    FGrid.RowCount   := Length(FData);
  finally
    FGrid.EndUpdate;
  end;
end;

procedure TGridMemTableAdapter.Clear;
begin
  if Assigned(FGrid) then
    FGrid.OnGetValue := nil;
  SetLength(FData, 0);
end;

procedure TFrm_JsonMain.ClearDatasetSchema(ADataset: TDataSet);
var
  I: Integer;
begin
  if ADataset.Active then ADataset.Close;

  ADataset.DisableControls;
  try
    for I := ADataset.Fields.Count - 1 downto 0 do
      ADataset.Fields[I].Free;

    if Assigned(ADataset.FieldDefs) then
      ADataset.FieldDefs.Clear;

    TFDMemTable(ADataset).IndexDefs.Clear;
  finally
    ADataset.EnableControls;
  end;
end;

procedure TFrm_JsonMain.ClearGrid(const AGrid: TGrid);
begin
  if AGrid = nil then Exit;

  AGrid.BeginUpdate;
  try
    AGrid.OnGetValue := nil;
    AGrid.RowCount   := 0;

    if Assigned(AGrid.TagObject) and (AGrid.TagObject is TGridMemTableAdapter) then
    begin
      TGridMemTableAdapter(AGrid.TagObject).Clear;
      AGrid.TagObject.Free;
      AGrid.TagObject := nil;
    end;
    AGrid.ClearColumns;
  finally
    AGrid.EndUpdate;
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

function TFrm_JsonMain.EnsureApiKeyFromIni(out AApiKey: string; const ASection, AIdent, AIniPath: string): Boolean;
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
