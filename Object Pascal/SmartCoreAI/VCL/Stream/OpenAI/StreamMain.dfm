object Frm_StreamMain: TFrm_StreamMain
  Left = 0
  Top = 0
  Caption = 'VCL Stream (OpenAI)'
  ClientHeight = 291
  ClientWidth = 477
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 477
    Height = 48
    Align = alTop
    TabOrder = 0
    object BtnPickAudio: TButton
      AlignWithMargins = True
      Left = 98
      Top = 4
      Width = 375
      Height = 40
      Align = alClient
      Caption = 'Transcribe/Understand Audio'
      TabOrder = 0
      OnClick = BtnPickAudioClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 88
      Height = 40
      Align = alLeft
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = BtnCancelClick
    end
  end
  object MemoLog: TMemo
    Left = 0
    Top = 48
    Width = 477
    Height = 243
    Align = alClient
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Audio|*.wav;*.mp3;*.m4a|All|*.*'
    Left = 168
    Top = 136
  end
  object AIConnection: TAIConnection
    Driver = AIOpenAIDriver
    Left = 272
    Top = 144
  end
  object AIOpenAIDriver: TAIOpenAIDriver
    Params.Strings = (
      'Model=whisper-1')
    OnCancel = AIOpenAIDriverCancel
    OnError = AIOpenAIDriverError
    Left = 56
    Top = 136
  end
  object StreamReq: TAIStreamRequest
    Connection = AIConnection
    OnSuccess = StreamReqSuccess
    OnPartial = StreamReqPartial
    OnError = StreamReqError
    Left = 56
    Top = 192
  end
end
