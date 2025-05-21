//---------------------------------------------------------------------------

// This software is Copyright (c) 2021 Embarcadero Technologies, Inc.
// You may only use this software if you are an authorized licensee
// of an Embarcadero developer tools product.
// This software is considered a Redistributable as defined under
// the software license agreement that comes with the Embarcadero Products
// and is subject to that software license agreement.

//---------------------------------------------------------------------------

unit InterBase.Constants;

interface

uses
  InterBase.Config;

type
  TInterBaseConfig = class(TInterBaseConfigBase)
  public const
    // ********************************************************************** //
    // ** Update the values below to the defaults for your implementation. ** //
    // ** This is an example of implementing the classes in the unit       ** //
    // ** InterBase.Config. You can build your own connection using the    ** //
    // ** example in the TInterBaseConfig.Create constructor below.        ** //
    // ********************************************************************** //
    INTERBASE_SERVER_USER = 'SYSDBA';
    INTERBASE_SERVER_PASSWORD = 'masterkey';

    // Update this to the name of the file you want to use for InterBase
    MY_DATABASE_FILENAME = 'AppData.IB';
    // See BuildDatabaseFilePath for how this is used.
    MY_APP_DATA_FOLDER = 'ib_data';

    // If you use a global username for accessing InterBase in the app then set that here.
    MY_INTERBASE_USER_NAME = 'NewUserName';
    MY_INTERBASE_USER_PASSWORD = 'Gr34tD4t48453!';
    CREATE_DATABASE_WITH_EMBEDDED_USERS = True;

    // SET this if you want to have a transportable encryption key for the data at rest.
    // KEEP THIS SECRET AND SECURE!
    MY_INTERBASE_ENCRYPTION_KEY = 'UNSpOYKN542jG3s';
    CREATE_DATABASE_WITH_SYSTEM_ENCRYPTION = True;

    // Set this to the current application database metadata version.
    // Increment it with any change to metadata. See TMyDatabaseStructureUpdate.UpdateMetaData
    MY_APP_DATABASE_VERSION = 1;
  public
    // See usage in FormMain.TMainFrm.FormCreate
    constructor Create(AConnectionType: TInterBaseConnectionType;
      const AServer, AForceDatabaseFileName: string);
  end;

implementation

uses
  System.SysUtils;

{ TInterBaseConfig }

constructor TInterBaseConfig.Create(AConnectionType: TInterBaseConnectionType;
  const AServer, AForceDatabaseFileName: string);
var
  LDBConn: TInterBaseDatabaseConnection;
  LAdmConn: TInterBaseAdminConnection;
begin
  // If you have a defined path for the database, or you want to force the path (e.g. when doing R&D)
  // This paramater allows that to happen.
  if not AForceDatabaseFileName.IsEmpty then
    LDBConn := TInterBaseDatabaseConnection.Create(
                                AConnectionType,
                                AServer,
                                MY_INTERBASE_USER_NAME,
                                MY_INTERBASE_USER_PASSWORD,
                                MY_INTERBASE_ENCRYPTION_KEY,
                                MY_APP_DATA_FOLDER,
                                AForceDatabaseFileName,
                                CREATE_DATABASE_WITH_EMBEDDED_USERS,
                                CREATE_DATABASE_WITH_SYSTEM_ENCRYPTION)
  else
    LDBConn := TInterBaseDatabaseConnection.Create(
                                AConnectionType,
                                AServer,
                                MY_INTERBASE_USER_NAME,
                                MY_INTERBASE_USER_PASSWORD,
                                MY_INTERBASE_ENCRYPTION_KEY,
                                MY_APP_DATA_FOLDER,
                                MY_DATABASE_FILENAME,
                                CREATE_DATABASE_WITH_EMBEDDED_USERS,
                                CREATE_DATABASE_WITH_SYSTEM_ENCRYPTION);

  LAdmConn := TInterBaseAdminConnection.Create(
                              AConnectionType,
                              AServer,
                              INTERBASE_SERVER_USER,
                              INTERBASE_SERVER_PASSWORD,
                              '',
                              '');

  inherited Create(LDBConn, LAdmConn, MY_APP_DATABASE_VERSION);
end;

end.
