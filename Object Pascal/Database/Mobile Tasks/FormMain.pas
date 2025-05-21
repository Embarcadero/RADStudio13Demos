//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit FormMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Rtti,
  FMX.Grid.Style, Data.Bind.Controls, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Fmx.Bind.Grid, System.Bindings.Outputs, Fmx.Bind.Editors,
  Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.Layouts, Fmx.Bind.Navigator,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Grid,
  InterBase.Config, InterBase.Constants, FMX.Memo.Types, FMX.Memo, FMX.ListBox;

type
  TMainFrm = class(TForm)
    btnConnect: TButton;
    btnDisconnect: TButton;
    btnBackup: TButton;
    TasksQry: TFDQuery;
    TasksQryID: TIntegerField;
    TasksQryDESCRIPTION: TStringField;
    TasksQryCOMPLETED: TBooleanField;
    Grid1: TGrid;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourceBindSourceDB1: TLinkGridToDataSource;
    ToolBar1: TToolBar;
    NavigatorBindSourceDB1: TBindNavigator;
    Memo1: TMemo;
    btnRestore: TButton;
    Label1: TLabel;
    cbShowTasks: TComboBox;
    procedure btnConnectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure cbShowTasksChange(Sender: TObject);
  private
    { Private declarations }
    FConfig: TInterBaseConfig;
    procedure UpdateUI;
  public
    { Public declarations }
  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.fmx}

uses
  System.IOUtils, InterBase.Connection, InterBase.Admin, DatabaseStructureUpdate;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
  // Create connection configuration for the database, when developing,
  // you can force to a specific database
  {$IF DEFINED(MSWINDOWS) AND DEFINED(DEBUG)}
  FConfig := TInterBaseConfig.Create(TInterBaseConnectionType.Server, '', 'c:\data\devdatabase.ib');
  {$ELSE}
  FSetup := TInterBaseConfig.Create(TInterBaseConnectionType.Server, '','');
  {$ENDIF}
  // Create main and admin data modules
  MainDM := TMainDM.Create(Self);
  AdminDM := TAdminDM.Create(Self, MainDM.FDPhysIBDriverLink1);
  UpdateUI;
end;

procedure TMainFrm.FormDestroy(Sender: TObject);
begin
  btnDisconnectClick(nil);
  FreeAndNil(AdminDM);
  FreeAndNil(MainDM);
  FreeAndNil(FConfig);
end;

procedure TMainFrm.UpdateUI;
begin
  btnConnect.Enabled := not MainDM.Conn.Connected;
  btnDisconnect.Enabled := MainDM.Conn.Connected;
  btnBackup.Enabled := MainDM.Conn.Connected and not AdminDM.InAction;
  btnRestore.Enabled := not AdminDM.InAction;
  Label1.Enabled := MainDM.Conn.Connected;
  cbShowTasks.Enabled := MainDM.Conn.Connected;
end;

procedure TMainFrm.btnConnectClick(Sender: TObject);
begin
  // Connect to the database
  MainDM.Open(FConfig);

  // Example of updating the database structure so it exists
  TMyDatabaseStructureUpdate.UpdateMetaData(MainDM, FConfig);

  // Open the table, ready for work !
  TasksQry.Open;

  // Update button states
  UpdateUI;
end;

procedure TMainFrm.btnDisconnectClick(Sender: TObject);
begin
  try
    MainDM.Conn.Close;
  except
    // Hide any exceptions, mostly related to lost connections
  end;
  UpdateUI;
end;

procedure TMainFrm.btnBackupClick(Sender: TObject);
var
  LDBFile,
  LBackFile: string;
begin
  LDBFile := MainDM.Conn.Params.Database;
  LBackFile := TPath.ChangeExtension(LDBFile, '.backup');

  AdminDM.StartBackupInterBaseDB(
    FConfig.DatabaseConnection, LDBFile, LBackFile, Memo1.Lines,
    procedure(APhase: TAdminActionPhase)
    begin
      UpdateUI;
    end);
end;

procedure TMainFrm.btnRestoreClick(Sender: TObject);
var
  LDBFile,
  LBackFile: string;
begin
  LDBFile := FConfig.DatabaseConnection.BuildDatabaseFilePath;
  LBackFile := TPath.ChangeExtension(LDBFile, '.backup');
  if not TFile.Exists(LBackFile) then
    raise Exception.CreateFmt('Backup file is not found: %s', [LBackFile]);

  AdminDM.StartRestoreInterBaseDB(
    FConfig.DatabaseConnection, LBackFile, LDBFile, Memo1.Lines,
    procedure(APhase: TAdminActionPhase)
    begin
      if APhase = TAdminActionPhase.Starting then
        btnDisconnectClick(nil)
      else
        btnConnectClick(nil);
    end);
end;

procedure TMainFrm.cbShowTasksChange(Sender: TObject);
begin
  TasksQry.Disconnect;
  case cbShowTasks.ItemIndex of
  0: TasksQry.MacroByName('mode').Clear;
  1: TasksQry.MacroByName('mode').AsRaw := 'TRUE';
  2: TasksQry.MacroByName('mode').AsRaw := 'FALSE';
  end;
  TasksQry.Open;
end;

end.
