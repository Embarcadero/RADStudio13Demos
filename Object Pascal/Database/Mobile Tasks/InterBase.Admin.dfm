object AdminDM: TAdminDM
  Height = 492
  Width = 761
  object FDIBSecurity1: TFDIBSecurity
    UserName = 'SYSDBA'
    Password = 'masterkey'
    Left = 70
    Top = 48
  end
  object FDIBBackup1: TFDIBBackup
    OnError = FDIBBackup1Error
    AfterExecute = FDIBBackup1AfterExecute
    OnProgress = FDIBBackup1Progress
    Left = 182
    Top = 48
  end
  object FDIBValidate1: TFDIBValidate
    OnError = FDIBBackup1Error
    AfterExecute = FDIBBackup1AfterExecute
    OnProgress = FDIBBackup1Progress
    Left = 398
    Top = 48
  end
  object FDIBRestore1: TFDIBRestore
    OnError = FDIBBackup1Error
    AfterExecute = FDIBBackup1AfterExecute
    OnProgress = FDIBBackup1Progress
    Left = 286
    Top = 46
  end
end
