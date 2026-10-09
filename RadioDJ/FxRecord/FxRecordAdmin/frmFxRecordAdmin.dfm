object frmFxRecordAdmin: TfrmFxRecordAdmin
  Left = 0
  Top = 0
  Caption = 'FactoryX FxRecord Admin'
  ClientHeight = 690
  ClientWidth = 840
  Color = 5850948
  Constraints.MinHeight = 729
  Constraints.MinWidth = 856
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object lblOperation: TLabel
    Left = 0
    Top = 620
    Width = 840
    Height = 24
    Align = alBottom
    AutoSize = False
    Caption = 'Ready'
    ExplicitTop = 0
    ExplicitWidth = 4
  end
  object pnlConnection: TPanel
    Left = 0
    Top = 0
    Width = 840
    Height = 165
    Align = alTop
    BevelOuter = bvNone
    Color = 5850948
    ParentBackground = False
    TabOrder = 0
    object lblServer: TLabel
      Left = 12
      Top = 17
      Width = 64
      Height = 17
      Caption = 'LAN server'
    end
    object lblWindowsIdentity: TLabel
      Left = 470
      Top = 17
      Width = 164
      Height = 17
      Caption = 'Uses your Windows account'
    end
    object lblSharedConfig: TLabel
      Left = 12
      Top = 51
      Width = 61
      Height = 17
      Caption = 'Shared INI'
    end
    object lblServerConfig: TLabel
      Left = 12
      Top = 85
      Width = 61
      Height = 17
      Caption = 'Service INI'
    end
    object lblService: TLabel
      Left = 370
      Top = 126
      Width = 458
      Height = 25
      AutoSize = False
      Caption = 'FxRecord service: not connected'
    end
    object edServer: TEdit
      Left = 100
      Top = 12
      Width = 228
      Height = 25
      Color = 9216
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TextHint = 'Server name or LAN IPv4 address'
      OnChange = ConnectionChanged
    end
    object btnConnect: TButton
      Left = 340
      Top = 10
      Width = 116
      Height = 30
      Caption = 'Connect / reload'
      TabOrder = 1
      OnClick = ConnectClick
    end
    object edSharedConfig: TEdit
      Left = 100
      Top = 46
      Width = 728
      Height = 25
      Color = 9216
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      TextHint = '\SERVER\FxRecord\FxRecord.ini'
      OnChange = ConnectionChanged
    end
    object edServerConfig: TEdit
      Left = 100
      Top = 80
      Width = 728
      Height = 25
      Color = 9216
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
    end
    object btnStart: TButton
      Left = 12
      Top = 119
      Width = 80
      Height = 30
      Caption = 'Start'
      TabOrder = 4
      OnClick = StartClick
    end
    object btnStop: TButton
      Left = 100
      Top = 119
      Width = 80
      Height = 30
      Caption = 'Stop'
      TabOrder = 5
      OnClick = StopClick
    end
    object btnRestart: TButton
      Left = 188
      Top = 119
      Width = 80
      Height = 30
      Caption = 'Restart'
      TabOrder = 6
      OnClick = RestartClick
    end
    object btnRefresh: TButton
      Left = 276
      Top = 119
      Width = 80
      Height = 30
      Caption = 'Refresh'
      TabOrder = 7
      OnClick = RefreshClick
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 165
    Width = 840
    Height = 455
    ActivePage = tabRecorder
    Align = alClient
    TabOrder = 1
    object tabRecorder: TTabSheet
      Caption = 'Recorder settings'
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 832
        Height = 423
        Align = alClient
        Color = 5850948
        ParentBackground = False
        TabOrder = 0
        object Bevel1: TBevel
          Left = 8
          Top = 100
          Width = 705
          Height = 131
        end
        object lblStreamPath: TLabel
          Left = 6
          Top = 20
          Width = 126
          Height = 17
          Hint = 'Select stream folder'
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Stream folder'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
        end
        object lblArchivePath: TLabel
          Left = 6
          Top = 58
          Width = 126
          Height = 17
          Hint = 'Select archive folder'
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Archive folder'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
        end
        object lblProfile: TLabel
          Left = 16
          Top = 122
          Width = 116
          Height = 17
          Hint = 'Select an output profile'
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Profile'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
        end
        object lblFragmentduration: TLabel
          Left = 3
          Top = 258
          Width = 129
          Height = 17
          Hint = 'Fragment duration in minutes'
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Fragment duration'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
        end
        object lblRetentionDays: TLabel
          Left = 239
          Top = 258
          Width = 106
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Retention days'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblWarningGB: TLabel
          Left = 3
          Top = 292
          Width = 129
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Disk warning free GB'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCriticalGB: TLabel
          Left = 208
          Top = 292
          Width = 137
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Disk critical free GB'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblPollingInterval: TLabel
          Left = 429
          Top = 258
          Width = 106
          Height = 17
          Hint = 'Polling interval in milliseconds'
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Polling interval'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
        end
        object lblMp3Rate: TLabel
          Left = 16
          Top = 157
          Width = 116
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'MP3 sample rate'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblMp3BitRate: TLabel
          Left = 251
          Top = 157
          Width = 94
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Bitrate (kbps)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblAacRate: TLabel
          Left = 16
          Top = 192
          Width = 116
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'AAC sample rate'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblAacBitRate: TLabel
          Left = 251
          Top = 192
          Width = 94
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Bitrate (kbps)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblAacLimits: TLabel
          Left = 450
          Top = 192
          Width = 198
          Height = 17
          Caption = 'Minimum 96 / maximum 192 kbps'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object Label1: TLabel
          Left = 16
          Top = 90
          Width = 145
          Height = 17
          Hint = 'Select output profile'
          Alignment = taCenter
          AutoSize = False
          Caption = 'Output profile settings'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          Transparent = False
        end
        object lblLiveTimeout: TLabel
          Left = 6
          Top = 350
          Width = 126
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Live timeout (sec)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblPathHelp: TLabel
          Left = 251
          Top = 350
          Width = 440
          Height = 34
          AutoSize = False
          Caption = 
            'Folders are paths on the server. Relative paths stay relative to' +
            ' the server INI.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object edStreamPath: TEdit
          Left = 138
          Top = 20
          Width = 534
          Height = 25
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnChange = SettingsChanged
        end
        object edArchivePath: TEdit
          Left = 138
          Top = 55
          Width = 534
          Height = 25
          Hint = 'Select archive folder'
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnChange = SettingsChanged
        end
        object cbOutputProfile: TComboBox
          Left = 138
          Top = 119
          Width = 298
          Height = 25
          Hint = 'Select output profile'
          Style = csDropDownList
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnChange = cbOutputProfileChange
          Items.Strings = (
            'SourceCopy'
            'MP4-H264-AAC'
            'AVI-H264-MP3')
        end
        object edFragmentduration: TEdit
          Left = 138
          Top = 255
          Width = 60
          Height = 25
          Hint = 'Fragment duration in minutes'
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          Text = '60'
          TextHint = '60'
          OnChange = SettingsChanged
        end
        object edRetentionDays: TEdit
          Left = 351
          Top = 255
          Width = 60
          Height = 25
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          TabOrder = 4
          Text = '14'
          TextHint = '14'
          OnChange = SettingsChanged
        end
        object edWarningGB: TEdit
          Left = 138
          Top = 289
          Width = 60
          Height = 25
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          TabOrder = 5
          Text = '20'
          TextHint = '20'
          OnChange = SettingsChanged
        end
        object edCriticalGB: TEdit
          Left = 351
          Top = 289
          Width = 60
          Height = 25
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          TabOrder = 6
          Text = '5'
          TextHint = '5'
          OnChange = SettingsChanged
        end
        object chkRequireLive: TCheckBox
          Left = 138
          Top = 322
          Width = 337
          Height = 21
          Caption = 'Warn when no live stream is present'
          Checked = True
          Color = 5850948
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 7
          OnClick = SettingsChanged
        end
        object edPollingInterval: TEdit
          Left = 541
          Top = 255
          Width = 60
          Height = 25
          Hint = 'Polling interval in milliseconds'
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
          Text = '500'
          TextHint = '500'
          OnChange = SettingsChanged
        end
        object cbMp3Rate: TComboBox
          Left = 138
          Top = 154
          Width = 106
          Height = 25
          Style = csDropDownList
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 9
          OnChange = SettingsChanged
          Items.Strings = (
            '44.1 kHz'
            '48 kHz'
            '32 kHz')
        end
        object cbMp3BitRate: TComboBox
          Left = 351
          Top = 154
          Width = 85
          Height = 25
          Style = csDropDownList
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 11
          OnChange = SettingsChanged
          Items.Strings = (
            '128'
            '160'
            '192')
        end
        object cbAacRate: TComboBox
          Left = 138
          Top = 189
          Width = 106
          Height = 25
          Style = csDropDownList
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 13
          OnChange = SettingsChanged
          Items.Strings = (
            '44.1 kHz'
            '48 kHz')
        end
        object cbAacBitRate: TComboBox
          Left = 351
          Top = 189
          Width = 85
          Height = 25
          Style = csDropDownList
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 10
          OnChange = SettingsChanged
          Items.Strings = (
            '96'
            '128'
            '160'
            '192')
        end
        object edLiveTimeout: TEdit
          Left = 138
          Top = 347
          Width = 60
          Height = 25
          Color = 9216
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          NumbersOnly = True
          ParentFont = False
          TabOrder = 12
          OnChange = SettingsChanged
        end
      end
    end
    object tabServiceLog: TTabSheet
      Caption = 'Service log'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object memServiceLog: TMemo
        Left = 0
        Top = 0
        Width = 832
        Height = 423
        Align = alClient
        Color = 9216
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9889633
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object tabAlertStatus: TTabSheet
      Caption = 'FxAlert status'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object memAlertStatus: TMemo
        Left = 0
        Top = 0
        Width = 832
        Height = 423
        Align = alClient
        Color = 9216
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9889633
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object tabActivity: TTabSheet
      Caption = 'Admin activity'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object memActivity: TMemo
        Left = 0
        Top = 0
        Width = 832
        Height = 423
        Align = alClient
        Color = 9216
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9889633
        Font.Height = -13
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
  end
  object pnlActions: TPanel
    Left = 0
    Top = 644
    Width = 840
    Height = 46
    Align = alBottom
    Color = 5850948
    ParentBackground = False
    TabOrder = 2
    object lblChanges: TLabel
      Left = 12
      Top = 15
      Width = 360
      Height = 20
      AutoSize = False
      Caption = 'Connect to load the recorder settings.'
    end
    object btnSave: TButton
      Left = 444
      Top = 8
      Width = 126
      Height = 30
      Caption = 'Save (stopped)'
      TabOrder = 0
      OnClick = SaveClick
    end
    object btnApply: TButton
      Left = 580
      Top = 8
      Width = 138
      Height = 30
      Caption = 'Save & restart'
      TabOrder = 1
      OnClick = ApplyClick
    end
    object btnClose: TButton
      Left = 730
      Top = 8
      Width = 98
      Height = 30
      Caption = 'Close'
      TabOrder = 2
      OnClick = CloseClick
    end
  end
  object RefreshTimer: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = RefreshClick
  end
end
