//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit InterBase.Config;

interface

type
  TInterBaseConnectionType = (Server, Desktop, ToGo, IBLite, ToGoClientRemoteServer);

  TInterBaseConnectionBase = class
  private
    FConnectionType: TInterBaseConnectionType;
    FUserName: string;
    FPassword: string;
    FServer: string;
    FSEPassword: string;
    function GetIsLocal: Boolean;
  public
    constructor Create(AConnectionType: TInterBaseConnectionType;
      const AServer, AUserName, APassword, ASEPassword: string);
    property ConnectionType: TInterBaseConnectionType read FConnectionType;
    property UserName: string read FUserName;
    property Password: string read FPassword;
    property Server: string read FServer;
    property SEPassword: string read FSEPassword;
    property IsLocal: Boolean read GetIsLocal;
  end;

  /// <summary>
  /// Setup the connection to the Admin Database. You shouldn't need to set the AdminDB value.
  /// </summary>
  /// <remarks>
  /// To create a new database the user needs to be added here first to allow a database to be created that it owns.
  /// </remarks>
  TInterBaseAdminConnection = class(TInterBaseConnectionBase)
  private
    FAdminDB: string;
    function GetAdminDB: string;
  public
    constructor Create(AConnectionType: TInterBaseConnectionType;
      const AServer, AUserName, APassword, ASEPassword: string; const AAdminDB: string = '');
  /// <summary>
  /// Path to the Admin database
  /// </summary>
  /// <remarks>
  /// Leave blank by default, it will locate it correctly. You shouldn't need to override this value
  /// </remarks>
    property AdminDB: string read GetAdminDB;
  end;

  TInterBaseDatabaseConnection = class(TInterBaseConnectionBase)
  strict private
    FDataFolder: string;
    FDatabaseFileName: string;
    FEnableEmbeddedUserAuthentication: Boolean;
    FEnableSystemEncryption: Boolean;
  public
    /// <summary>
    /// Creates the Database connection setting.
    /// </summary>
    /// <remarks>
    /// For local data (ToGo, IBLite, Desktop) leave AServer blank. It is recommended to enable
    //  Embedded User Security for extra protection
    /// </remarks>
    constructor Create(AConnectionType: TInterBaseConnectionType;
      const AServer, AUserName, APassword, ASEPassword, ADataFolder, ADatabaseFileName: string;
      AEnableEmbeddedUserAuthentication: Boolean = True; AEnableSystemEncryption: Boolean = True);
    /// <summary>
    /// Creates the database file path based on DataFolder and DatabaseFileName (and checks details for local file connections)
    /// </summary>
    /// <remarks>
    /// By default, windows debug builds overide the file path to support simpler debugging, otherwise the data is pucke
    /// </remarks>
    function BuildDatabaseFilePath: string; virtual;
    property DataFolder: string read FDataFolder;
    property DatabaseFileName: string read FDatabaseFileName;
    property EnableEmbeddedUserAuthentication: Boolean read FEnableEmbeddedUserAuthentication;
    property EnableSystemEncryption: Boolean read FEnableSystemEncryption;
  end;

  /// <summary>
  /// TInterBaseConfigBase is a base class for creating an object that supports
  /// both TInterBaseAdminConnection, TInterBaseDatabaseConnection and other app info.
  /// </summary>
  /// <remarks>
  /// The AdminConnection is used for User Security, and DatabaseConnection for connecting to the database file.
  /// </remarks>
  TInterBaseConfigBase = class
  private
    FDatabaseConnection: TInterBaseDatabaseConnection;
    FAdminConnection: TInterBaseAdminConnection;
    FVersion: Integer;
  public
    constructor Create(ADatabaseConnection: TInterBaseDatabaseConnection;
      AAdminConnection: TInterBaseAdminConnection; AVersion: Integer);
    destructor Destroy; override;
    property AdminConnection: TInterBaseAdminConnection read FAdminConnection;
    property DatabaseConnection: TInterBaseDatabaseConnection read FDatabaseConnection;
    property Version: Integer read FVersion;
  end;

implementation

uses
  System.IOUtils, System.SysUtils;

{ TInterBaseConnectionBase }

constructor TInterBaseConnectionBase.Create(AConnectionType: TInterBaseConnectionType;
  const AServer, AUserName, APassword, ASEPassword: string);
begin
  inherited Create;
  FConnectionType := AConnectionType;
  FUserName := AUserName;
  FServer := AServer;
  FPassword := APassword;
  FSEPassword := ASEPassword;
end;

function TInterBaseConnectionBase.GetIsLocal: Boolean;
begin
  Result := Server.IsEmpty or SameText(Server, '127.0.0.1') or SameText(Server, 'localhost');
end;

{ TInterBaseAdminConnection }

constructor TInterBaseAdminConnection.Create(AConnectionType: TInterBaseConnectionType;
  const AServer, AUserName, APassword, ASEPassword: string; const AAdminDB: string);
begin
  inherited Create(AConnectionType, AServer, AUserName, APassword, ASEPassword);
  FAdminDB := AAdminDB;
end;

function TInterBaseAdminConnection.GetAdminDB: string;
begin
  // Default is for blank, override if you need to specifiy a specific admin DB.
  // You should never need to use this.
  if IsLocal then
  begin
    if TFile.Exists(FAdminDB) then
      Result := FAdminDB
    else
      Result := '';
  end
  else
    Result := FAdminDB;
end;

{ TInterBaseDatabaseConnection }

function TInterBaseDatabaseConnection.BuildDatabaseFilePath: string;
var
  LDBFolder: string;
begin
  Assert(not DatabaseFileName.IsEmpty, 'Database FileName missing');

  // If connencting to a remote DB, we need to check if the folder is setup, otherwise just use DatabaseFileName as the path to the DB.
  if (ConnectionType in [TInterBaseConnectionType.Server, TInterBaseConnectionType.ToGoClientRemoteServer]) and
     not IsLocal then
  begin
    if not DataFolder.IsEmpty then
      Exit(TPath.Combine(DataFolder, DatabaseFileName))
    else
      Exit(DatabaseFileName);
  end
  else
  begin
    // These should all be local connections so we can check the local disk and help get sensible defaults
    // Once path is built, check it exists.
    try
      // If the DataBaseFileName is the actual database, ignore the folder part.
      if TFile.Exists(DatabaseFileName) then
        Exit(DatabaseFileName);

      if TDirectory.Exists(DataFolder) then
        Result := TPath.Combine(DataFolder, DatabaseFileName)
      else
      begin
        {$IF DEFINED(IOS) or DEFINED(ANDROID)}
        // On mobile, its easiest to create the file in the documents folder for the app.
        // If deploying the database file (rather than creating on the fly)
        // on iOS deploy it to 'StartUp\Documents\'
        // on Android deploy to './assets/internal/'
        Result := TPath.Combine(TPath.GetDocumentsPath, DatabaseFileName);
        {$ELSE} // {$ELSEIF DEFINED(MACOS) or DEFINED(MSWINDOWS) or DEFINED(LINUX)}
        if TPath.IsPathRooted(DataFolder) then
          Result := TPath.Combine(DataFolder, DatabaseFileName)
        else
          Result := TPath.Combine(TPath.GetHomePath, DataFolder, DatabaseFileName);
        {$ENDIF}
      end;

      if Result.IsEmpty then
        Result := TPath.Combine(TPath.GetLibraryPath, DataFolder, DatabaseFileName);

    finally
      LDBFolder := TPath.GetDirectoryName(Result);
      if not TDirectory.Exists(LDBFolder) then
        TDirectory.CreateDirectory(LDBFolder);
    end;
  end;
end;

constructor TInterBaseDatabaseConnection.Create(AConnectionType: TInterBaseConnectionType;
  const AServer, AUserName, APassword, ASEPassword, ADataFolder, ADatabaseFileName: string;
  AEnableEmbeddedUserAuthentication, AEnableSystemEncryption: Boolean);
begin
  inherited Create(AConnectionType, AServer, AUserName, APassword, ASEPassword);
  FDataFolder := ADataFolder;
  FDatabaseFileName := ADatabaseFileName;
  FEnableEmbeddedUserAuthentication := AEnableEmbeddedUserAuthentication;
  FEnableSystemEncryption := AEnableSystemEncryption;
end;

{ TInterBaseConfigBase }

constructor TInterBaseConfigBase.Create(
  ADatabaseConnection: TInterBaseDatabaseConnection;
  AAdminConnection: TInterBaseAdminConnection;
  AVersion: Integer);
begin
  Assert(Assigned(AAdminConnection), 'Admin connection details missing');
  Assert(Assigned(ADatabaseConnection), 'Database connection details missing');

  inherited Create;
  FDatabaseConnection := ADatabaseConnection;
  FAdminConnection := AAdminConnection;
  FVersion := AVersion;
end;

destructor TInterBaseConfigBase.Destroy;
begin
  FDatabaseConnection.Free;
  FAdminConnection.Free;
  inherited Destroy;
end;

end.
