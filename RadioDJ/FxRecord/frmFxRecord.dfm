object frmFxRecord: TfrmFxRecord
  Left = 0
  Top = 0
  Caption = 'FxRecord'
  ClientHeight = 440
  ClientWidth = 726
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 726
    Height = 393
    ActivePage = tabStatus
    Align = alClient
    TabOrder = 0
    ExplicitHeight = 394
    object tabStatus: TTabSheet
      Caption = 'Status'
      ExplicitHeight = 362
      object memLog: TMemo
        Left = 0
        Top = 0
        Width = 718
        Height = 307
        Align = alClient
        Color = 9216
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9889633
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitHeight = 289
      end
      object pnlStatusTop: TPanel
        Left = 0
        Top = 307
        Width = 718
        Height = 54
        Align = alBottom
        BevelOuter = bvNone
        Color = 5850948
        ParentBackground = False
        TabOrder = 1
        ExplicitTop = 295
        object lblState: TLabel
          Left = 14
          Top = 18
          Width = 58
          Height = 17
          Caption = 'STOPPED'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnStart: TButton
          Left = 417
          Top = 12
          Width = 94
          Height = 31
          Hint = 'Start recording'
          Caption = 'Start'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = btnStartClick
        end
        object btnStop: TButton
          Left = 517
          Top = 12
          Width = 94
          Height = 31
          Hint = 'Stop recording'
          Caption = 'Stop'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = btnStopClick
        end
        object btnClearLog: TButton
          Left = 617
          Top = 12
          Width = 94
          Height = 31
          Caption = 'Clear Log'
          TabOrder = 2
          OnClick = btnClearLogClick
        end
        object btnOpenArchive: TButton
          Left = 321
          Top = 12
          Width = 90
          Height = 31
          Hint = 'Open Archive Folder'
          Caption = 'Archive Folder'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          OnClick = btnOpenArchiveClick
        end
      end
    end
    object tabRecorder: TTabSheet
      Caption = 'Recorder'
      ImageIndex = 1
      ExplicitHeight = 362
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 718
        Height = 361
        Align = alClient
        Color = 5850948
        ParentBackground = False
        TabOrder = 0
        ExplicitHeight = 362
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
          OnChange = edStreamPathChange
        end
        object btnBrowseStream: TButton
          Left = 678
          Top = 20
          Width = 32
          Height = 25
          Caption = '...'
          TabOrder = 1
          OnClick = btnBrowseStreamClick
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
          TabOrder = 2
          OnChange = edArchivePathChange
        end
        object btnBrowseArchive: TButton
          Left = 678
          Top = 55
          Width = 32
          Height = 25
          Caption = '...'
          TabOrder = 3
          OnClick = btnBrowseArchiveClick
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
          TabOrder = 4
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
          TabOrder = 5
          Text = '60'
          TextHint = '60'
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
          TabOrder = 6
          Text = '14'
          TextHint = '14'
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
          TabOrder = 7
          Text = '20'
          TextHint = '20'
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
          TabOrder = 8
          Text = '5'
          TextHint = '5'
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
          TabOrder = 9
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
          TabOrder = 10
          Text = '500'
          TextHint = '500'
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
          TabOrder = 11
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
          TabOrder = 12
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
          TabOrder = 14
          Items.Strings = (
            '96'
            '128'
            '160'
            '192')
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 393
    Width = 726
    Height = 47
    Align = alBottom
    BevelOuter = bvNone
    Color = 5850948
    ParentBackground = False
    TabOrder = 1
    ExplicitTop = 394
    object btnSave: TButton
      Left = 521
      Top = 8
      Width = 94
      Height = 31
      Hint = 'Save settings'
      Caption = 'Save'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnClose: TButton
      Left = 621
      Top = 8
      Width = 94
      Height = 31
      Hint = 'Close app'
      Caption = 'Close'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnCloseClick
    end
  end
end
