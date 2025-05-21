//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit InterBase.Connection;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.IBDef,
  FireDAC.Phys.IBBase, FireDAC.Phys.IB, Data.DB, FireDAC.Comp.Client,
  FireDAC.FMXUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBWrapper,
  InterBase.Config;

type
  TMainDM = class(TDataModule)
    Conn: TFDConnection;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    FDPhysIBDriverLink1: TFDPhysIBDriverLink;
  public
    { Public declarations }
    /// <summary>
    /// Opens the InterBase connection based on submitted options
    /// </summary>
    /// <remarks>
    /// When database does not exist, then method will automatically create a new
    /// database and enable required security options. Then it will validate
    /// database structure.
    /// For additional security, it is recommended to use Embedded User
    /// Authentication (required for encryption) and System Encryption.
    /// </remarks>
    procedure Open(AConfig: TInterBaseConfigBase);
    /// <summary>
    /// Returns True if the ATableName table exists in the local database.
    /// </summary>
    /// <remarks>
    /// Works using cached information. If you modify the database at runtime you should call
    /// Conn.RefreshMetadataCache to refresh the local cache before calling TableExists.
    /// </remarks>
    function TableExists(const ATableName: string): Boolean;
  end;

var
  MainDM: TMainDM;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  System.IOUtils, FireDAC.Phys.IBCli, InterBase.Admin;

{ TMainDM }

procedure TMainDM.Open(AConfig: TInterBaseConfigBase);
const
  CONNECTION_FAILED = 'Unable to connect to the database ';
var
  LCreateDB: Boolean;
begin
  Assert(Assigned(AConfig), 'Database configuration details missing');

  FDPhysIBDriverLink1.Lite := AConfig.DatabaseConnection.ConnectionType in [ToGo, IBLite, ToGoClientRemoteServer];
  Conn.Params.Database := AConfig.DatabaseConnection.BuildDatabaseFilePath;
  Conn.Params.UserName := AConfig.DatabaseConnection.UserName;
  Conn.Params.Password := AConfig.DatabaseConnection.Password;
  Conn.Params.Values['SEPassword'] := AConfig.DatabaseConnection.SEPassword;

  try
    if not AdminDM.UserExists(AConfig.AdminConnection, AConfig.DatabaseConnection) then
      AdminDM.AddUser(AConfig.AdminConnection, AConfig.DatabaseConnection);

    try
      LCreateDB := False;
      Conn.Open;
    except
      on E: EIBNativeException do
        if E.Errors[0].ErrorCode = isc_io_error then
          LCreateDB := True
        else
          raise;
    end;

    if LCreateDB then
    begin
      // Create database
      Conn.Params.Values['CreateDatabase'] := 'Yes';
      Conn.Open;
      Conn.Close;

      // Setup embedded user authentication and system encryption if requested
      if AConfig.DatabaseConnection.EnableEmbeddedUserAuthentication then
        AdminDM.EnableEUA(AConfig.AdminConnection, AConfig.DatabaseConnection);
      if AConfig.DatabaseConnection.EnableSystemEncryption then
        AdminDM.EnableSE(AConfig.AdminConnection, AConfig.DatabaseConnection);

      // Revert to default value and open database
      Conn.Params.Values['CreateDatabase'] := 'No';
      Conn.Open;
    end;
  except
    on E: Exception do
    begin
      E.Message := CONNECTION_FAILED + Conn.Params.Database + sLineBreak + E.Message;
      raise;
    end;
  end;
end;

function TMainDM.TableExists(const ATableName: string): Boolean;
var
  LTable: TFDTable;
begin
  LTable := TFDTable.Create(nil);
  try
    LTable.Connection := Conn;
    LTable.TableName := ATableName;
    Result := LTable.Exists;
  finally
    LTable.Free;
  end;
end;

end.
