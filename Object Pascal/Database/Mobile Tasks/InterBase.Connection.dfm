object MainDM: TMainDM
  Height = 233
  Width = 455
  object Conn: TFDConnection
    Params.Strings = (
      'DriverID=IB'
      'User_Name=sysdba'
      'Password=masterkey')
    UpdateOptions.AssignedValues = [uvAutoCommitUpdates]
    UpdateOptions.AutoCommitUpdates = True
    ConnectedStoredUsage = [auDesignTime]
    LoginPrompt = False
    Left = 72
    Top = 32
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'FMX'
    Left = 296
    Top = 32
  end
  object FDPhysIBDriverLink1: TFDPhysIBDriverLink
    Left = 168
    Top = 32
  end
end
