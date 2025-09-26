object Frm_JsonMain: TFrm_JsonMain
  Left = 0
  Top = 0
  Caption = 'VCL JSON (OpenAI)'
  ClientHeight = 536
  ClientWidth = 973
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 973
    Height = 46
    Align = alTop
    TabOrder = 0
    object EditText: TEdit
      Left = 1
      Top = 1
      Width = 732
      Height = 44
      Align = alClient
      TabOrder = 0
      Text = 
        'Return array of any 5 cities with fields name (string), average_' +
        'temperture (number), and number_ of_citizens (number). Only JSON' +
        '-array.'
      ExplicitHeight = 23
    end
    object BtnSend: TButton
      AlignWithMargins = True
      Left = 830
      Top = 4
      Width = 139
      Height = 38
      Align = alRight
      Caption = 'Send JSON Request'
      TabOrder = 1
      OnClick = BtnSendClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 736
      Top = 4
      Width = 88
      Height = 38
      Align = alRight
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = BtnCancelClick
    end
  end
  object Grid: TDBGrid
    Left = 0
    Top = 46
    Width = 973
    Height = 330
    Align = alClient
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object MemoRaw: TMemo
    Left = 0
    Top = 376
    Width = 973
    Height = 160
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 368
    Top = 216
    IndicatorSize = aisXLarge
  end
  object AIConnection: TAIConnection
    Driver = AIOpenAIDriver
    Left = 64
    Top = 200
  end
  object AIOpenAIDriver: TAIOpenAIDriver
    Params.Strings = (
      'Model=gpt-4o-mini')
    OnCancel = AIOpenAIDriverCancel
    Left = 64
    Top = 120
  end
  object JsonReq: TAIJSONRequest
    Connection = AIConnection
    DataSet = FDMemTable1
    OnSuccess = JsonReqSuccess
    OnError = JsonReqError
    Left = 64
    Top = 280
  end
  object DataSource1: TDataSource
    DataSet = FDMemTable1
    Left = 168
    Top = 136
  end
  object FDMemTable1: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 176
    Top = 224
  end
end
