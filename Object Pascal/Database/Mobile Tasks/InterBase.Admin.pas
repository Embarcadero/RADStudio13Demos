//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit InterBase.Admin;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.UI.Intf, FireDAC.FMXUI.Wait, FireDAC.Phys,
  FireDAC.Phys.IBBase, FireDAC.Phys.IB, FireDAC.Comp.UI, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Phys.IBWrapper, FireDAC.Phys.IBDef, InterBase.Config;

type
  TAdminActionPhase = (Starting, Finished);
  TAdminActionHandler = reference to procedure (APhase: TAdminActionPhase);

  TAdminDM = class(TDataModule)
    FDIBSecurity1: TFDIBSecurity;
    FDIBBackup1: TFDIBBackup;
    FDIBValidate1: TFDIBValidate;
    FDIBRestore1: TFDIBRestore;
    procedure FDIBBackup1Progress(ASender: TFDPhysDriverService;
      const AMessage: string);
    procedure FDIBBackup1Error(ASender, AInitiator: TObject;
      var AException: Exception);
    procedure FDIBBackup1AfterExecute(Sender: TObject);
  private
    FLog: TStrings;
    FInAction: string;

    function GetInAction: Boolean;
    procedure StartAction(const AReqAction: string; const AProc: TAdminActionHandler);
    procedure FinishAction(const AProc: TAdminActionHandler);
    procedure LogClear;
    procedure Log(const ALogMessage: string);

    procedure BackupInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
      const ADatabase, ABackupFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
    procedure RestoreInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
      const ABackupFile, ARestoreToFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
    procedure ValidateInterBaseDB(const ACredentials: TInterBaseConnectionBase;
      const ADatabase: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);

  public
    constructor Create(AOwner: TComponent; ADriverLink: TFDPhysIBDriverLink); reintroduce;

    procedure StartBackupInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
      const ADatabase, ABackupFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
    procedure StartRestoreInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
      const ABackupFile, ARestoreToFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
    procedure StartValidateInterBaseDB(const ACredentials: TInterBaseConnectionBase;
      const ADatabase: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
    property InAction: Boolean read GetInAction;

    function UserExists(const AAdminCredentials: TInterBaseAdminConnection;
      const AUserCredentials: TInterBaseDatabaseConnection): Boolean;
    procedure AddUser(const AAdminCredentials: TInterBaseAdminConnection;
      const AUserCredentials: TInterBaseDatabaseConnection);

    procedure EnableEUA(const AAdminCredentials: TInterBaseAdminConnection;
      const ACredentials: TInterBaseDatabaseConnection);
    procedure EnableSE(const AAdminCredentials: TInterBaseAdminConnection;
      const ACredentials: TInterBaseDatabaseConnection);
  end;

var
  AdminDM: TAdminDM;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  System.Threading;

const
  BACKUP_DB = 'backup database';
  RESTORE_DB = 'restore database';
  VALIDATE_DB = 'validate database';

{ TAdminDM }

constructor TAdminDM.Create(AOwner: TComponent; ADriverLink: TFDPhysIBDriverLink);
begin
  inherited Create(AOwner);
  FDIBSecurity1.DriverLink := ADriverLink;
  FDIBBackup1.DriverLink := ADriverLink;
  FDIBValidate1.DriverLink := ADriverLink;
  FDIBRestore1.DriverLink := ADriverLink;
end;

function TAdminDM.GetInAction: Boolean;
begin
  Result := not FInAction.IsEmpty;
end;

procedure TAdminDM.StartAction(const AReqAction: string; const AProc: TAdminActionHandler);
begin
  if InAction then
    raise Exception.CreateFmt('Cannot "%s", because "%s" is in progress', [AReqAction, FInAction]);
  FInAction := AReqAction;
  if Assigned(AProc) then
    TThread.Synchronize(nil,
      procedure
      begin
        AProc(TAdminActionPhase.Starting);
      end);
end;

procedure TAdminDM.FinishAction(const AProc: TAdminActionHandler);
begin
  FInAction := '';
  if Assigned(AProc) then
    TThread.Synchronize(nil,
      procedure
      begin
        AProc(TAdminActionPhase.Finished);
      end);
end;

procedure TAdminDM.LogClear;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if Assigned(FLog) then
        FLog.Clear;
    end);
end;

procedure TAdminDM.Log(const ALogMessage: string);
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if Assigned(FLog) then
        FLog.Add(Format('%s - %s', [DateTimeToStr(Now), ALogMessage]));
    end);
end;

procedure TAdminDM.FDIBBackup1AfterExecute(Sender: TObject);
begin
  Log('End');
end;

procedure TAdminDM.FDIBBackup1Error(ASender, AInitiator: TObject;
  var AException: Exception);
begin
  Log(Format('** ERROR - %s **', [AException.Message]));
end;

procedure TAdminDM.FDIBBackup1Progress(ASender: TFDPhysDriverService;
  const AMessage: string);
begin
  Log(aMessage);
end;

procedure TAdminDM.BackupInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
  const ADatabase, ABackupFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  StartAction(BACKUP_DB, AProc);
  try
    FDIBBackup1.UserName := ACredentials.UserName;
    FDIBBackup1.Password := ACredentials.Password;
    FDIBBackup1.Host := ACredentials.Server;

    if ACredentials.EnableEmbeddedUserAuthentication then
      FDIBBackup1.EUADatabase := ADatabase;
    if ACredentials.EnableSystemEncryption then
    begin
      FDIBBackup1.EncryptKeyName := 'BackupEncryptionKey';
      FDIBBackup1.SEPassword := ACredentials.SEPassword;
    end;

    FDIBBackup1.Database := ADatabase;
    FDIBBackup1.BackupFiles.Text := ABackupFile;
    FLog := AVerboseTo;
    FDIBBackup1.Verbose := Assigned(FLog);
    if Assigned(FLog) then
      LogClear;

    FDIBBackup1.Backup;
  finally
    FinishAction(AProc);
  end;
end;

procedure TAdminDM.RestoreInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
  const ABackupFile, ARestoreToFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  StartAction(RESTORE_DB, AProc);
  try
    FDIBRestore1.UserName := ACredentials.UserName;
    FDIBRestore1.Password := ACredentials.Password;
    FDIBRestore1.Host := ACredentials.Server;
    FDIBRestore1.Options := FDIBRestore1.Options + [roReplace];

    if ACredentials.EnableSystemEncryption then
    begin
      FDIBRestore1.SEPassword := ACredentials.SEPassword;
      FDIBRestore1.DecryptPassword := ACredentials.SEPassword;
    end;

    FDIBRestore1.Database := ARestoreToFile;
    FDIBRestore1.BackupFiles.Text := ABackupFile;

    FLog := AVerboseTo;
    FDIBRestore1.Verbose := Assigned(FLog);
    if Assigned(FLog) then
      LogClear;

    FDIBRestore1.Restore;
  finally
    FinishAction(AProc);
  end;
end;

procedure TAdminDM.ValidateInterBaseDB(const ACredentials: TInterBaseConnectionBase;
  const ADatabase: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  StartAction(VALIDATE_DB, AProc);
  try
    FDIBValidate1.UserName := ACredentials.UserName;
    FDIBValidate1.Password := ACredentials.Password;
    FDIBValidate1.Host := ACredentials.Server;
    FDIBValidate1.SEPassword := ACredentials.SEPassword;

    FDIBValidate1.Database := ADatabase;

    FLog := AVerboseTo;
    if Assigned(FLog) then
      LogClear;

    FDIBValidate1.Repair;
  finally
    FinishAction(AProc);
  end;
end;

procedure TAdminDM.StartBackupInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
  const ADatabase, ABackupFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  TTask.Run(
    procedure
    begin
      BackupInterBaseDB(ACredentials, ADatabase, ABackupFile, AVerboseTo, AProc);
    end);
end;

procedure TAdminDM.StartRestoreInterBaseDB(const ACredentials: TInterBaseDatabaseConnection;
  const ABackupFile, ARestoreToFile: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  TTask.Run(
    procedure
    begin
      RestoreInterBaseDB(ACredentials, ABackupFile, ARestoreToFile, AVerboseTo, AProc);
    end);
end;

procedure TAdminDM.StartValidateInterBaseDB(const ACredentials: TInterBaseConnectionBase;
  const ADatabase: string; AVerboseTo: TStrings; const AProc: TAdminActionHandler);
begin
  TTask.Run(
    procedure
    begin
      ValidateInterBaseDB(ACredentials, ADatabase, AVerboseTo, AProc);
    end);
end;

function TAdminDM.UserExists(const AAdminCredentials: TInterBaseAdminConnection;
  const AUserCredentials: TInterBaseDatabaseConnection): Boolean;
begin
  FDIBSecurity1.UserName := AAdminCredentials.UserName;
  FDIBSecurity1.Password := AAdminCredentials.Password;
  FDIBSecurity1.Host := AAdminCredentials.Server;

  FDIBSecurity1.EUADatabase := AAdminCredentials.AdminDB;
  if not FDIBSecurity1.EUADatabase.IsEmpty then
    FDIBSecurity1.SEPassword := AAdminCredentials.SEPassword
  else
    FDIBSecurity1.SEPassword := '';

  FDIBSecurity1.AUserName := AUserCredentials.UserName;
  FDIBSecurity1.DisplayUser;
  Result := not FDIBSecurity1.AUserName.IsEmpty;
end;

procedure TAdminDM.AddUser(const AAdminCredentials: TInterBaseAdminConnection;
  const AUserCredentials: TInterBaseDatabaseConnection);
begin
  FDIBSecurity1.UserName := AAdminCredentials.UserName;
  FDIBSecurity1.Password := AAdminCredentials.Password;
  FDIBSecurity1.Host := AAdminCredentials.Server;

  FDIBSecurity1.EUADatabase := AAdminCredentials.AdminDB;
  if not FDIBSecurity1.EUADatabase.IsEmpty then
    FDIBSecurity1.SEPassword := AAdminCredentials.SEPassword
  else
    FDIBSecurity1.SEPassword := '';

  FDIBSecurity1.AUserName := AUserCredentials.UserName;
  FDIBSecurity1.APassword := AUserCredentials.Password;
  FDIBSecurity1.AddUser;
end;

procedure TAdminDM.EnableEUA(const AAdminCredentials: TInterBaseAdminConnection;
  const ACredentials: TInterBaseDatabaseConnection);
begin
  FDIBSecurity1.UserName := ACredentials.UserName;
  FDIBSecurity1.Password := ACredentials.Password;
  FDIBSecurity1.Host := ACredentials.Server;

  FDIBSecurity1.EUADatabase := ACredentials.BuildDatabaseFilePath;
  FDIBSecurity1.KeyName := 'DBEncryptionKey';
  FDIBSecurity1.SEPassword := ACredentials.SEPassword;
  if not FDIBSecurity1.EUAActive then
    FDIBSecurity1.EUAActive := True;
end;

procedure TAdminDM.EnableSE(const AAdminCredentials: TInterBaseAdminConnection;
  const ACredentials: TInterBaseDatabaseConnection);
begin
  FDIBSecurity1.UserName := ACredentials.UserName;
  FDIBSecurity1.Password := ACredentials.Password;
  FDIBSecurity1.Host := ACredentials.Server;

  FDIBSecurity1.EUADatabase := ACredentials.BuildDatabaseFilePath;
  FDIBSecurity1.KeyName := 'DBEncryptionKey';
  FDIBSecurity1.SEPassword := ACredentials.SEPassword;
  if not FDIBSecurity1.DBEncrypted then
  begin
    FDIBSecurity1.SetEncryption(AAdminCredentials.Password,
      ACredentials.SEPassword, True, TIBEncryptionType.ecAES, 256);

    // Login as SYSDSO to create backup key. It must be password protected.
    // Note, each TFDIBSecurity operation clears password related properties.
    FDIBSecurity1.UserName := 'sysdso';
    FDIBSecurity1.Password := AAdminCredentials.Password;
    FDIBSecurity1.SEPassword := ACredentials.SEPassword;

    FDIBSecurity1.KeyName := 'BackupEncryptionKey';
    FDIBSecurity1.CreateKey(False, TIBEncryptionType.ecAES, 256, ACredentials.SEPassword, True, True, '');
    FDIBSecurity1.GrantKey(ACredentials.UserName);
  end;
end;

end.
