// FactoryX
//
// Copyright (c) FactoryX, Netherlands/Australia/Germany. All rights reserved.
//
// Project: Media Foundation - MFPack - Samples
// Project location: https://sourceforge.net/projects/MFPack
//                   https://github.com/FactoryXCode/MfPack
// Module: FxRecord.Converter.pas
// Kind: Pascal Unit
// Release date: 10-08-2026
// Language: ENU
//
// Revision Version: 4.0.0
// Description: Encodes selected audio profiles and writes AVI or MP4 recordings.
//
// Company: FactoryX
// Intiator(s): Tony (maXcomX), Carmen (carmenh).
// Contributor(s): Tony Kalf (maXcomX), Carmen (carmenh).
//
//------------------------------------------------------------------------------
// CHANGE LOG
// Date       Person              Reason
// ---------- ------------------- ----------------------------------------------
// 24/08/2026 All                 Moby release  SDK 10.0.28000.2705  (Windows 11)
//------------------------------------------------------------------------------
//
// Remarks: Requires Windows 10 or higher.
//
// Related objects: -
// Related projects: MfPackX400
// Known Issues: -
//
// Compiler version: 23 up to 35
// SDK version: 10.0.28000.2705
//
// Todo: -
//
// =============================================================================
// Source: -
//==============================================================================
//
// LICENSE
//
// The contents of this file are subject to the Mozilla Public License
// Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// https://mozilla.org/MPL/2.0/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// Non commercial users may distribute this sourcecode provided that this
// header is included in full at the top of the file.
// Commercial users are not allowed to distribute this sourcecode as part of
// their product.
//
//==============================================================================
unit FxRecord.Converter;

interface

uses

  {WinApi}
  WinApi.Windows,
  {System}
  System.Classes,
  System.SysUtils;

type

  TFxAviIndex = packed record
    ChunkId: DWORD;
    Flags: DWORD;
    Offset: DWORD;
    Size: DWORD;
  end;

  TFxConversionThread = class(TThread)
  private
    FInputFileName: string;
    FPartialFileName: string;
    FFinalFileName: string;
    FErrorText: string;
    FSucceeded: Boolean;
    FOutputProfile: string;
    FSampleRate: Integer;
    FBitRateKbps: Integer;

  protected
    procedure Execute(); override;

  public
    constructor Create(const AInputFileName, APartialFileName,
                             AFinalFileName: string;
                             const AOutputProfile: string = 'AVI-H264-MP3';
                             const ASampleRate: Integer = 44100;
                             const ABitRateKbps: Integer = 192);

    property ErrorText: string read FErrorText;
    property FinalFileName: string read FFinalFileName;
    property InputFileName: string read FInputFileName;
    property Succeeded: Boolean read FSucceeded;
  end;


implementation

uses

  {WinApi}
  WinApi.ActiveX.ObjBase,
  WinApi.ComBaseApi,
  WinApi.WinApiTypes,
  {ActiveX}
  WinApi.ActiveX.PropIdl,
  {WinMM}
  WinApi.WinMM.MMeApi,
  {MediaFoundationApi}
  WinApi.MediaFoundationApi.MfApi,
  WinApi.MediaFoundationApi.MfIdl,
  WinApi.MediaFoundationApi.MfObjects,
  WinApi.MediaFoundationApi.MfReadWrite;


procedure CheckHR(const AResult: HRESULT;
                  const AOperation: string);
begin

  if Failed(AResult) then
    raise Exception.CreateFmt('%s failed (HRESULT 0x%.8x).',
                              [AOperation, Cardinal(AResult)]);
end;


function FourCC(const AText: AnsiString): DWORD;
begin
  if Length(AText) <> 4 then
    raise Exception.Create('Invalid AVI chunk identifier.');
  Move(AText[1], Result, SizeOf(Result));
end;

// The Windows AVI sink does not accept the H.264 format on all systems.
// Mux the Windows-encoded packets here; no external codecs or tools are used.
procedure MuxNativePacketsToAvi(const AEncodedFile, AOutputFile: string);
var
  Reader: IMFSourceReader;
  VideoType, AudioType, StreamType: IMFMediaType;
  MajorType: TGUID;
  VideoIndex, AudioIndex: DWORD;
  Sample: IMFSample;
  Buffer: IMFMediaBuffer;
  Wave: PWAVEFORMATEX;
  WaveSize, Width, Height, RateN, RateD, StreamIndex, Flags: DWORD;
  Data: PByte;
  DataLength, CleanPoint: DWORD;
  Timestamp: Int64;
  Output: TFileStream;
  Index: TMemoryStream;
  Entry: TFxAviIndex;
  RiffStart, HeaderStart, StreamStart, ChunkStart, MoviStart: Int64;
  TotalFramesPosition, VideoLengthPosition, AudioLengthPosition: Int64;
  VideoFrames, AudioBytes: DWORD;
  MainHeader: array[0..13] of DWORD;
  StreamHeader: array[0..13] of DWORD;
  BitmapHeader: array[0..9] of DWORD;
  VideoEnded, AudioEnded: Boolean;
  PaddingByte: Byte;

  // Helpers
  procedure WriteDWord(const AValue: DWORD);
  begin

    Output.WriteBuffer(AValue,
                       SizeOf(AValue));
  end;

  function BeginChunk(const AId: AnsiString): Int64;
  begin

    WriteDWord(FourCC(AId));
    Result := Output.Position;
    WriteDWord(0);
  end;

  procedure PatchDWord(const APosition: Int64;
                       const AValue: DWORD);
  var
    Saved: Int64;

  begin

    Saved := Output.Position;
    Output.Position := APosition;
    WriteDWord(AValue);
    Output.Position := Saved;
  end;

  procedure EndChunk(const AStart: Int64);
  begin

    PatchDWord(AStart, DWORD(Output.Position - AStart - 4));

    if Odd(Output.Position) then
      Output.WriteBuffer(PaddingByte,
                         1);
  end;

begin

  PaddingByte := 0;
  CheckHR(MFCreateSourceReaderFromURL(PWideChar(AEncodedFile),
                                      nil,
                                      Reader),
                                      'Open encoded packets');

  CheckHR(Reader.GetNativeMediaType(0,
                                    0,
                                    @StreamType),
          'Read first encoded stream');

  CheckHR(StreamType.GetGUID(MF_MT_MAJOR_TYPE,
                             MajorType),
          'Read first stream type');

  if IsEqualGUID(MajorType,
                 MFMediaType_Video) then
    begin
      VideoIndex := 0;
      AudioIndex := 1;
    end
  else
    begin
      VideoIndex := 1;
      AudioIndex := 0;
    end;

  CheckHR(Reader.GetNativeMediaType(VideoIndex,
                                    0,
                                    @VideoType),
          'Read encoded video');

  CheckHR(Reader.GetNativeMediaType(AudioIndex,
                                    0,
                                    @AudioType),
          'Read encoded audio');

  CheckHR(Reader.SetCurrentMediaType(VideoIndex,
                                     0,
                                     VideoType),
          'Select H.264 packets');

  CheckHR(Reader.SetCurrentMediaType(AudioIndex,
                                     0,
                                     AudioType),
          'Select MP3 packets');

  CheckHR(MFGetAttributeSize(VideoType,
                             MF_MT_FRAME_SIZE,
                             Width,
                             Height),
          'Read AVI dimensions');

  CheckHR(MFGetAttributeRatio(VideoType,
                              MF_MT_FRAME_RATE,
                              RateN,
                              RateD),
          'Read encoded frame rate');

  if (RateN <> 25 * RateD) then
    raise Exception.Create('The Windows encoder did not produce 25 fps.');

  Wave := nil;
  CheckHR(MFCreateWaveFormatExFromMFMediaType(AudioType,
                                              Wave,
                                              WaveSize),
          'Create AVI MP3 format');
  try
    Output := TFileStream.Create(AOutputFile,
                                 fmCreate);

    try
      Index := TMemoryStream.Create();

      try
        RiffStart := BeginChunk('RIFF');
        WriteDWord(FourCC('AVI '));
        HeaderStart := BeginChunk('LIST');
        WriteDWord(FourCC('hdrl'));
        ChunkStart := BeginChunk('avih');
        FillChar(MainHeader,
                 SizeOf(MainHeader), 0);
        MainHeader[0] := 40000;
        MainHeader[1] := 150000 + Wave.nAvgBytesPerSec;
        MainHeader[3] := $10; // AVIF_HASINDEX
        MainHeader[6] := 2;
        MainHeader[8] := Width;
        MainHeader[9] := Height;

        TotalFramesPosition := Output.Position + 4 * 4;
        Output.WriteBuffer(MainHeader,
                           SizeOf(MainHeader));
        EndChunk(ChunkStart);

        StreamStart := BeginChunk('LIST');
        WriteDWord(FourCC('strl'));
        ChunkStart := BeginChunk('strh');
        FillChar(StreamHeader,
                 SizeOf(StreamHeader),
                        0);

        StreamHeader[0] := FourCC('vids');
        StreamHeader[1] := FourCC('H264');
        StreamHeader[5] := 1;
        StreamHeader[6] := 25;
        StreamHeader[10] := DWORD(-1);
        StreamHeader[13] := (Height shl 16) or Width;

        VideoLengthPosition := Output.Position + 8 * 4;
        Output.WriteBuffer(StreamHeader,
                           SizeOf(StreamHeader));
        EndChunk(ChunkStart);
        ChunkStart := BeginChunk('strf');

        FillChar(BitmapHeader,
                 SizeOf(BitmapHeader),
                 0);

        BitmapHeader[0] := 40;
        BitmapHeader[1] := Width;
        BitmapHeader[2] := Height;
        BitmapHeader[3] := (24 shl 16) or 1;
        BitmapHeader[4] := FourCC('H264');
        BitmapHeader[5] := Width * Height * 3;

        Output.WriteBuffer(BitmapHeader,
                           SizeOf(BitmapHeader));

        EndChunk(ChunkStart);
        EndChunk(StreamStart);

        StreamStart := BeginChunk('LIST');
        WriteDWord(FourCC('strl'));
        ChunkStart := BeginChunk('strh');

        FillChar(StreamHeader,
                 SizeOf(StreamHeader),
                 0);

        StreamHeader[0] := FourCC('auds');
        StreamHeader[5] := 1;
        StreamHeader[6] := Wave.nAvgBytesPerSec;
        StreamHeader[10] := DWORD(-1);
        StreamHeader[11] := 1; // Audio stream length is expressed in bytes.

        AudioLengthPosition := Output.Position + 8 * 4;

        Output.WriteBuffer(StreamHeader,
                           SizeOf(StreamHeader));

        EndChunk(ChunkStart);
        ChunkStart := BeginChunk('strf');
        Output.WriteBuffer(Wave^,
                           WaveSize);

        EndChunk(ChunkStart);
        EndChunk(StreamStart);
        EndChunk(HeaderStart);

        MoviStart := BeginChunk('LIST');
        WriteDWord(FourCC('movi'));
        VideoFrames := 0;
        AudioBytes := 0;
        VideoEnded := False;
        AudioEnded := False;

        repeat
          Sample := nil;
          CheckHR(Reader.ReadSample(MF_SOURCE_READER_ANY_STREAM,
                                    0,
                                    @StreamIndex,
                                    @Flags,
                                    @Timestamp,
                                    @Sample),
                  'Read AVI packet');

          if ((Flags and DWORD(MF_SOURCE_READERF_ENDOFSTREAM)) <> 0) then
            begin
              if (StreamIndex = VideoIndex) then
                VideoEnded := True
              else
                if (StreamIndex = AudioIndex) then
                  AudioEnded := True;

              CheckHR(Reader.SetStreamSelection(StreamIndex,
                                                False),
                      'Finish packet stream');
            end;

          if (Sample <> nil) then
            begin
              CheckHR(Sample.ConvertToContiguousBuffer(@Buffer),
                      'Get AVI packet');

              CheckHR(Buffer.Lock(Data,
                                  nil,
                                  @DataLength),
                      'Lock AVI packet');

              try
                // Classic AVI has 32-bit offsets. Fail safely before exceeding
                // 2 GiB, retaining both the original source and encoded work file.
                if Output.Position + DataLength + Index.Size + 32 >= $7FFF0000 then
                  raise Exception.Create('AVI segment exceeds 2 GiB; reduce FragmentDuration.');

                Entry.Offset := DWORD(Output.Position - MoviStart - 4);
                Entry.Size := DataLength;
                Entry.Flags := $10;

                if (StreamIndex = VideoIndex) then
                  begin
                    Entry.ChunkId := FourCC('00dc');
                    CleanPoint := 0;
                    Sample.GetUINT32(MFSampleExtension_CleanPoint,
                                     CleanPoint);

                    if (CleanPoint = 0) then
                      Entry.Flags := 0;

                    Inc(VideoFrames);
                  end
                else
                  begin
                    Entry.ChunkId := FourCC('01wb');
                    Inc(AudioBytes,
                        DataLength);
                  end;

                WriteDWord(Entry.ChunkId);
                WriteDWord(DataLength);
                Output.WriteBuffer(Data^,
                                   DataLength);

                if Odd(DataLength) then
                  Output.WriteBuffer(PaddingByte,
                                     1);
                Index.WriteBuffer(Entry,
                                  SizeOf(Entry));
              finally
                Buffer.Unlock();
              end;

            Buffer := nil;
          end;
        until VideoEnded and AudioEnded;

        if (VideoFrames = 0) or (AudioBytes = 0) then
          raise Exception.Create('The AVI recording requires both video and audio packets.');

        EndChunk(MoviStart);
        ChunkStart := BeginChunk('idx1');
        Index.Position := 0;
        Output.CopyFrom(Index,
                        Index.Size);

        EndChunk(ChunkStart);

        PatchDWord(TotalFramesPosition,
                   VideoFrames);

        PatchDWord(VideoLengthPosition,
                   VideoFrames);

        PatchDWord(AudioLengthPosition,
                   AudioBytes);
        EndChunk(RiffStart);

      finally
        Index.Free;
      end;

    finally
      Output.Free;
    end;

  finally
    CoTaskMemFree(Wave);
  end;
end;


procedure EncodeNativePackets(const AInputFile, AOutputFile: string;
                              const ASampleRate, ABitRateKbps: Integer);
var
  Resolver: IMFSourceResolver;
  SourceObject: IUnknown;
  Source: IMFMediaSource;
  Reader: IMFSourceReader;
  InputVideo: IMFMediaType;
  AudioType: IMFMediaType;
  Profile: IMFTranscodeProfile;
  Video: IMFAttributes;
  Audio: IMFAttributes;
  Container: IMFAttributes;
  SessionAttributes: IMFAttributes;
  AudioTypes: IMFCollection;
  AudioObject: IUnknown;
  Topology: IMFTopology;
  Session: IMFMediaSession;
  MediaEvent: IMFMediaEvent;
  EventType: MediaEventType;
  ObjectType: MF_OBJECT_TYPE;
  Status: HRESULT;
  StartPosition: PROPVARIANT;
  Width: DWORD;
  Height: DWORD;
  Count: DWORD;
  Channels: DWORD;
  Rate: DWORD;
  BytesPerSecond: DWORD;
  I: Integer;
  AudioFound: Boolean;

begin

  CheckHR(MFCreateSourceResolver(Resolver),
          'Create source resolver');

  CheckHR(Resolver.CreateObjectFromURL(PWideChar(AInputFile),
                                       MF_RESOLUTION_MEDIASOURCE,
                                       nil,
                                       ObjectType,
                                       SourceObject),
          'Open source MP4');

  Source := SourceObject as IMFMediaSource;

  try
    CheckHR(MFCreateSourceReaderFromURL(PWideChar(AInputFile),
                                        nil,
                                        Reader),
            'Read source format');

    CheckHR(Reader.GetNativeMediaType(MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                                      0,
                                      @InputVideo),
            'Read video format');

    CheckHR(MFGetAttributeSize(InputVideo,
                               MF_MT_FRAME_SIZE,
                               Width,
                               Height),
            'Read video dimensions');

    Reader := nil;

    CheckHR(MFCreateTranscodeProfile(Profile),
            'Create H.264/MP3 profile');

    CheckHR(MFCreateAttributes(Video,
                               8),
            'Create video attributes');

    CheckHR(Video.SetGUID(MF_MT_MAJOR_TYPE,
                          MFMediaType_Video),
            'Set video type');

    CheckHR(Video.SetGUID(MF_MT_SUBTYPE,
                          MFVideoFormat_H264),
            'Set H.264 encoding');

    CheckHR(MFSetAttributeSize(Video,
                               MF_MT_FRAME_SIZE,
                               Width,
                               Height),
            'Set dimensions');

    CheckHR(MFSetAttributeRatio(Video,
                                MF_MT_FRAME_RATE,
                                25,
                                1),
            'Set 25 fps');

    CheckHR(MFSetAttributeRatio(Video,
                                MF_MT_PIXEL_ASPECT_RATIO,
                                1,
                                1),
            'Set pixel aspect');

    CheckHR(Video.SetUINT32(MF_MT_INTERLACE_MODE,
                            2),
            'Set progressive video');

    CheckHR(Video.SetUINT32(MF_MT_AVG_BITRATE,
                            1200000),
            'Set video bitrate');

    CheckHR(Video.SetUINT32(MF_MT_MPEG2_PROFILE,
                            66),
            'Set H.264 baseline profile');

    CheckHR(Profile.SetVideoAttributes(Video),
            'Set video profile');

    // Use a complete media type advertised by the Windows MP3 encoder.
    CheckHR(MFTranscodeGetAudioOutputAvailableTypes(MFAudioFormat_MP3,
                                                    DWORD(MFT_ENUM_FLAG_SYNCMFT),
                                                    nil,
                                                    AudioTypes),
            'Enumerate Windows MP3 formats');

    CheckHR(AudioTypes.GetElementCount(Count),
            'Count MP3 formats');

    AudioFound := False;

    for I := 0 to Integer(Count) - 1 do
      begin
        CheckHR(AudioTypes.GetElement(I,
                                      AudioObject),
                'Read MP3 format');

        AudioType := AudioObject as IMFMediaType;

      if Succeeded(AudioType.GetUINT32(MF_MT_AUDIO_NUM_CHANNELS,
                                       Channels)) and
         Succeeded(AudioType.GetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND,
                                       Rate)) and
         Succeeded(AudioType.GetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND,
                                       BytesPerSecond)) and
         (Channels = 2) and
         (Rate = DWORD(ASampleRate)) and
         (BytesPerSecond = DWORD(ABitRateKbps * 1000 div 8)) then
        begin
          AudioFound := True;
          Break;
        end;
      end;

    // Windows supports this format. A missing enumeration match describes
    // this system's lookup result, not the encoder's supported formats.
    if not AudioFound then
      raise Exception.CreateFmt('Media Foundation did not enumerate stereo MP3 at %d Hz and %d kbps on this system.', [ASampleRate, ABitRateKbps]);

    CheckHR(MFCreateAttributes(Audio,
                               8),
            'Create audio attributes');

    CheckHR(AudioType.CopyAllItems(Audio),
            'Copy MP3 format');

    CheckHR(Profile.SetAudioAttributes(Audio),
            'Set audio profile');

    CheckHR(MFCreateAttributes(Container,
                               2),
            'Create container attributes');

    CheckHR(Container.SetGUID(MF_TRANSCODE_CONTAINERTYPE,
                              MFTranscodeContainerType_MPEG4),
            'Set encoded MP4 work container');

    CheckHR(Container.SetUINT32(MF_TRANSCODE_ADJUST_PROFILE,
                                DWORD(MF_TRANSCODE_ADJUST_PROFILE_DEFAULT)),
            'Set profile policy');

    CheckHR(Profile.SetContainerAttributes(Container),
            'Set container profile');

    CheckHR(MFCreateTranscodeTopology(Source,
                                      PWideChar(AOutputFile),
                                      Profile,
                                      Topology),
            'Build Windows encoder topology');

    // Run the Windows transcode pipeline on a background thread.
    CheckHR(MFCreateAttributes(SessionAttributes,
                               1),
            'Create session attributes');

    CheckHR(SessionAttributes.SetUINT32(MF_SESSION_GLOBAL_TIME,
                                        0),
            'Set transcode clock');

    CheckHR(MFCreateMediaSession(SessionAttributes,
                                 Session),
            'Create transcode session');

    try
      CheckHR(Session.SetTopology(0,
                                  Topology),
              'Set encoder topology');

      ZeroMemory(@StartPosition,
                 SizeOf(StartPosition));

      repeat
        CheckHR(Session.GetEvent(0,
                                 MediaEvent),
                'Read transcode event');

        CheckHR(MediaEvent.GetStatus(Status),
                'Read transcode status');

        CheckHR(Status,
                'AVI transcode');

        CheckHR(MediaEvent.GetType(EventType),
                'Read transcode event type');

        case EventType of
          MESessionTopologySet: CheckHR(Session.Start(GUID_NULL,
                                                      StartPosition),
                                        'Start AVI transcode');

          MESessionEnded: CheckHR(Session.Close(),
                                  'Finalize encoded packets');
        end;

        MediaEvent := nil;

      until EventType = MESessionClosed;

    finally
      Session.Shutdown();
      Session := nil;
      Topology := nil;
    end;

  finally
    Reader := nil;
    Source.Shutdown();
  end;
end;


procedure EncodeAacToMp4(const AInputFile, AOutputFile: string;
                        const ASampleRate, ABitRateKbps: Integer);
var
  Reader: IMFSourceReader;
  Writer: IMFSinkWriter;
  VideoType, PcmType, AacType, FirstType: IMFMediaType;
  Attributes: IMFAttributes;
  MajorType: TGUID;
  Sample: IMFSample;
  VideoIn, AudioIn, VideoOut, AudioOut, StreamIndex, Flags: DWORD;
  TimeStamp: Int64;
  VideoStart, AudioStart: Int64;
  VideoEnded, AudioEnded: Boolean;
begin
  CheckHR(MFCreateSourceReaderFromURL(PWideChar(AInputFile), nil, Reader),
          'Open AAC source recording');
  CheckHR(Reader.GetNativeMediaType(0, 0, @FirstType), 'Read first source stream');
  CheckHR(FirstType.GetGUID(MF_MT_MAJOR_TYPE, MajorType), 'Read source stream type');
  if IsEqualGUID(MajorType, MFMediaType_Video) then
  begin
    VideoIn := 0;
    AudioIn := 1;
  end
  else
  begin
    VideoIn := 1;
    AudioIn := 0;
  end;
  CheckHR(Reader.SetStreamSelection(MF_SOURCE_READER_ALL_STREAMS, False), 'Deselect source streams');
  CheckHR(Reader.SetStreamSelection(VideoIn, True), 'Select source video');
  CheckHR(Reader.SetStreamSelection(AudioIn, True), 'Select source audio');
  CheckHR(Reader.GetNativeMediaType(VideoIn, 0, @VideoType), 'Read H.264 source format');
  CheckHR(VideoType.GetGUID(MF_MT_SUBTYPE, MajorType), 'Read source video subtype');
  if not IsEqualGUID(MajorType, MFVideoFormat_H264) then
    raise Exception.Create('MP4-H264-AAC requires H.264 source video.');
  CheckHR(Reader.SetCurrentMediaType(VideoIn, 0, VideoType), 'Preserve H.264 source packets');

  CheckHR(MFCreateMediaType(PcmType), 'Create PCM input type');
  CheckHR(PcmType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio), 'Set PCM major type');
  CheckHR(PcmType.SetGUID(MF_MT_SUBTYPE, MFAudioFormat_PCM), 'Set PCM subtype');
  CheckHR(PcmType.SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 2), 'Set stereo PCM');
  CheckHR(PcmType.SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, ASampleRate), 'Set PCM sample rate');
  CheckHR(PcmType.SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16), 'Set 16-bit PCM');
  CheckHR(PcmType.SetUINT32(MF_MT_AUDIO_BLOCK_ALIGNMENT, 4), 'Set PCM block alignment');
  CheckHR(PcmType.SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, ASampleRate * 4), 'Set PCM byte rate');
  CheckHR(Reader.SetCurrentMediaType(AudioIn, 0, PcmType), 'Decode and resample source audio');
  CheckHR(Reader.GetCurrentMediaType(AudioIn, @PcmType), 'Read negotiated PCM type');

  CheckHR(MFCreateMediaType(AacType), 'Create AAC output type');
  CheckHR(AacType.SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Audio), 'Set AAC major type');
  CheckHR(AacType.SetGUID(MF_MT_SUBTYPE, MFAudioFormat_AAC), 'Set AAC subtype');
  CheckHR(AacType.SetUINT32(MF_MT_AUDIO_NUM_CHANNELS, 2), 'Set stereo AAC');
  CheckHR(AacType.SetUINT32(MF_MT_AUDIO_SAMPLES_PER_SECOND, ASampleRate), 'Set AAC sample rate');
  CheckHR(AacType.SetUINT32(MF_MT_AUDIO_BITS_PER_SAMPLE, 16), 'Set AAC sample format');
  CheckHR(AacType.SetUINT32(MF_MT_AUDIO_AVG_BYTES_PER_SECOND, ABitRateKbps * 1000 div 8), 'Set AAC bitrate');
  CheckHR(AacType.SetUINT32(MF_MT_AAC_PAYLOAD_TYPE, 0), 'Set raw AAC payload');

  CheckHR(MFCreateAttributes(Attributes, 2), 'Create MP4 writer attributes');
  CheckHR(Attributes.SetGUID(MF_TRANSCODE_CONTAINERTYPE, MFTranscodeContainerType_MPEG4), 'Set MP4 output');
  CheckHR(Attributes.SetUINT32(MF_SINK_WRITER_DISABLE_THROTTLING, 1), 'Disable writer throttling');
  CheckHR(MFCreateSinkWriterFromURL(PWideChar(AOutputFile), nil, Attributes, Writer), 'Create MP4 writer');
  CheckHR(Writer.AddStream(VideoType, VideoOut), 'Add H.264 copy stream');
  CheckHR(Writer.SetInputMediaType(VideoOut, VideoType, nil), 'Set H.264 copy input');
  CheckHR(Writer.AddStream(AacType, AudioOut), 'Add selected AAC stream');
  CheckHR(Writer.SetInputMediaType(AudioOut, PcmType, nil), 'Set AAC PCM input');
  CheckHR(Writer.BeginWriting(), 'Begin AAC recording');
  VideoStart := -1;
  AudioStart := -1;
  VideoEnded := False;
  AudioEnded := False;
  repeat
    Sample := nil;
    CheckHR(Reader.ReadSample(MF_SOURCE_READER_ANY_STREAM, 0, @StreamIndex,
            @Flags, @TimeStamp, @Sample), 'Read AAC conversion sample');
    if (Flags and DWORD(MF_SOURCE_READERF_ENDOFSTREAM)) <> 0 then
    begin
      if StreamIndex = VideoIn then VideoEnded := True
      else if StreamIndex = AudioIn then AudioEnded := True;
      CheckHR(Reader.SetStreamSelection(StreamIndex, False), 'Finish source stream');
    end;
    if Sample <> nil then
    begin
      if StreamIndex = VideoIn then
      begin
        if VideoStart < 0 then VideoStart := TimeStamp;
        CheckHR(Sample.SetSampleTime(TimeStamp - VideoStart), 'Rebase H.264 timestamp');
        CheckHR(Writer.WriteSample(VideoOut, Sample), 'Copy H.264 sample');
      end
      else
      begin
        if AudioStart < 0 then AudioStart := TimeStamp;
        CheckHR(Sample.SetSampleTime(TimeStamp - AudioStart), 'Rebase AAC timestamp');
        CheckHR(Writer.WriteSample(AudioOut, Sample), 'Encode AAC sample');
      end;
    end;
  until VideoEnded and AudioEnded;
  CheckHR(Writer.Finalize(), 'Finalize AAC MP4 recording');
  Writer := nil;
  Reader := nil;
end;

constructor TFxConversionThread.Create(const AInputFileName: string;
                                       const APartialFileName: string;
                                       const AFinalFileName: string;
                                       const AOutputProfile: string;
                                       const ASampleRate: Integer;
                                       const ABitRateKbps: Integer);
begin

  inherited Create(True);

  FreeOnTerminate := False;
  FInputFileName := AInputFileName;
  FPartialFileName := APartialFileName;
  FFinalFileName := AFinalFileName;
  FOutputProfile := AOutputProfile;
  FSampleRate := ASampleRate;
  FBitRateKbps := ABitRateKbps;
end;


procedure TFxConversionThread.Execute();
var
  EncodedFile: string;

begin

  FSucceeded := False;
  FErrorText := '';

  try
    CheckHR(CoInitializeEx(nil,
                           COINIT_MULTITHREADED),
            'Initialize converter COM');

    try
      CheckHR(MFStartup(),
              'Initialize Media Foundation');

      try

        // An old partial file is evidence of an interrupted conversion.
        if FileExists(FPartialFileName) or FileExists(FFinalFileName) then
          raise Exception.Create('Recording output already exists; it has been preserved.');

        EncodedFile := '';
        if SameText(FOutputProfile, 'AVI-H264-MP3') then
        begin
          if not ((FSampleRate = 32000) or (FSampleRate = 44100) or (FSampleRate = 48000)) or
             not ((FBitRateKbps = 128) or (FBitRateKbps = 160) or (FBitRateKbps = 192)) then
            raise Exception.Create('Invalid MP3 sample rate or bitrate.');
          EncodedFile := FPartialFileName + '.encoded.mp4';
          if FileExists(EncodedFile) then
            raise Exception.Create('Encoded work file already exists; it has been preserved.');
          EncodeNativePackets(FInputFileName, EncodedFile, FSampleRate, FBitRateKbps);
          MuxNativePacketsToAvi(EncodedFile, FPartialFileName);
        end
        else if SameText(FOutputProfile, 'MP4-H264-AAC') then
        begin
          if not ((FSampleRate = 44100) or (FSampleRate = 48000)) or
             not ((FBitRateKbps = 96) or (FBitRateKbps = 128) or
                  (FBitRateKbps = 160) or (FBitRateKbps = 192)) then
            raise Exception.Create('Invalid AAC sample rate or bitrate (96-192 kbps).');
          EncodeAacToMp4(FInputFileName, FPartialFileName, FSampleRate, FBitRateKbps);
        end
        else
          raise Exception.Create('Unsupported conversion profile.');

        if not FileExists(FPartialFileName) then
          raise Exception.Create('The native converter did not create an output file.');

        if not MoveFileEx(PChar(FPartialFileName),
                          PChar(FFinalFileName),
                          MOVEFILE_WRITE_THROUGH) then
          raise Exception.Create('Cannot finalize recording. ' + SysErrorMessage(GetLastError()));

        if EncodedFile <> '' then DeleteFile(PChar(EncodedFile));
        DeleteFile(PChar(FInputFileName));
        FSucceeded := True;

      finally
        MFShutdown();
      end;

    finally
      CoUninitialize();
    end;

  except
    on E: Exception do
      FErrorText := E.Message;
  end;
end;

end.