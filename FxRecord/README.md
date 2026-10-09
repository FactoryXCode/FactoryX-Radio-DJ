# FxRecord

Version: 4.0.1

**Notes:**

- Updated for compiler versions 17 to 35.
- SDK version: 10.0.28000.2705 (Windows 11).
- Requires Windows 10 or later.
- Minimum supported MfPack version: 4.0.0.

FxRecord is the FactoryX compliance recorder for RDJ Pro broadcasts. It runs
on the broadcast server beside FxServe or Caddy and monitors the local
published stream folder. Please check your local laws for public broadcasting.

## Recording and monitoring

A compliance recorder keeps an archive of broadcasts for a configured
retention period. FxRecord provides a Windows service for unattended recording
and a VCL desktop application for local configuration and monitoring.

Its features include:

- Stream and archive folder configuration.
- Live manifest and broadcast session monitoring.
- Disk space warning and critical thresholds.
- Crash-safe recording to fragmented MP4.
- Clock-aligned file rotation and configurable retention.
- Recording progress and active filenames in the log.
- An `FxAlert/status.json` status feed and warnings for phones, tablets and PCs.

Normal desktop startup waits for the administrator to press **Start**.
The Windows service starts recording without a signed-in user and enables
recording regardless of the INI's desktop `Enabled` value.

## Output profiles and audio settings

- `SourceCopy` preserves RDJ Pro's H.264 video and AAC audio without re-encoding.
- `MP4-H264-AAC` preserves the H.264 video and encodes stereo AAC at the selected
  sample rate (44.1 or 48 kHz) and bitrate (96, 128, 160 or 192 kbps).
- `AVI-H264-MP3` creates an AVI file with H.264 video at 25 fps and stereo MP3
  at the selected sample rate (44.1, 48 or 32 kHz) and bitrate
  (128, 160 or 192 kbps).

The MP3 and AAC controls are enabled for their matching output profiles.
Each codec retains its own settings. **Save** writes them to the INI, which
is also used by the Windows service. Defaults are MP3 at 44.1 kHz/192 kbps
and AAC at 44.1 kHz/160 kbps. `SourceCopy` preserves the source audio settings.

```ini
[Audio]
Mp3SampleRate=44100
Mp3BitRateKbps=192
AacSampleRate=44100
AacBitRateKbps=160
```

The supported stereo AAC-LC settings range from 96 to 192 kbps in the steps
listed above, at 44.1 or 48 kHz. The 32 kHz option is available for MP3.
See Microsoft's [AAC encoder documentation](https://learn.microsoft.com/en-us/windows/win32/medfound/aac-encoder)
and [MP3 encoder documentation](https://learn.microsoft.com/en-us/windows/win32/medfound/mp3-audio-encoder).

`SourceCopy` recordings use the `.mp4.partial` suffix. Profiles that encode
audio first record to `.avi.source.mp4.partial` or `.mp4.source.mp4.partial`.
When a source segment closes, FxRecord converts it in the background and
publishes the result as `.avi` or `.mp4`. If conversion fails, the source MP4
is preserved and an FxAlert warning is published. Unfinished files found
after a crash are preserved and reported.

FxRecord rebases video and audio decode timelines separately at the start
of each archive file. Completed MP4 files start at time zero, keeping elapsed
time and seeking correct even after a long broadcast session.

`AVI-H264-MP3` uses the Windows Media Foundation H.264 and MP3 encoders through
MfPack, with an AVI container writer built into FxRecord. No third-party
converter is required. The server needs the Windows Media Foundation
media components.

Conversion uses an intermediate `.avi.partial.encoded.mp4` file, removed
on success and preserved on failure. The AVI writer supports segments below
2 GiB. Use shorter rotation intervals for larger recordings; exceeding the
limit produces an FxAlert warning and preserves the source.

## Windows service installation

Copy `FxRecord.exe`, `FxRecord.ini`, `Install-FxRecord.cmd` and
`Uninstall-FxRecord.cmd` to a local folder on the broadcast server, such as
`C:\FxRecord`. Use local drive paths for the executable, INI, stream and
archive folders. The default LocalSystem account should not rely on a network
share pointing back to the same server.

On the broadcast server, open Command Prompt as administrator and run:

```bat
C:\FxRecord\Install-FxRecord.cmd
```

The installer registers the service as `FxRecord`, enables delayed automatic
startup and configures three restart attempts with a 60-second delay. If
Windows rejects delayed startup, installation continues with ordinary
automatic startup and records a warning in the log.

Running the installer again repairs an existing stopped service registration
and preserves its service account. Stop a running service before repairing
its registration. Uninstalling first is unnecessary.

For the PCHP001 installation, the local folders are `C:\FxRecord` and
`F:\ComplianceRecordings`. Its recorder settings include:

```ini
[Recorder]
StreamPath=C:\FxServe\www\Stream
ArchivePath=F:\ComplianceRecordings
```

Remote administration uses server `PCHP001` and the shared INI
`\\PCHP001\FxRecord\FxRecord.ini`. The archive share is
`\\PCHP001\ComplianceRecordings`; the recorder itself uses the local path.

To remove the service registration while retaining its files:

```bat
C:\FxRecord\Uninstall-FxRecord.cmd
```

## Logging and troubleshooting

Desktop mode, service mode and installation diagnostics write to the log
beside the selected INI. `C:\FxRecord\FxRecord.ini` produces
`C:\FxRecord\FxRecord.log`. The desktop user and service account need write
access to that folder; remote administrators need read access to the log.
A custom INI can be selected with `--config "C:\Path\Recorder.ini"`.

Installation errors identify the failing Windows operation and error number.
If installation or startup fails, read the log and inspect the registration
and current state:

```bat
sc.exe qc FxRecord
sc.exe query FxRecord
```

The registered command has this form:

```text
"C:\FxRecord\FxRecord.exe" --service --config "C:\FxRecord\FxRecord.ini"
```

Windows' service manager uses `--service`. Start the installed service through
Services, FxRecord Admin or `sc.exe start FxRecord`.

The installer passes the Windows Boolean value `1` for delayed startup and
failure recovery. Older builds passed Delphi's `LongBool` value `-1`, which
caused Windows error 87 when configuring delayed automatic startup. Replace
an affected executable with the corrected build and rerun the installer.

## Windows update monitoring

FxRecord checks every five minutes for an installed Windows update requiring
a restart. Every six hours, it asks Windows Update Agent whether updates are
waiting for installation. Both conditions are published through FxAlert so
the administrator can choose a maintenance window. The update scan runs in
a separate helper process and does not pause recording.

## FxAlert phone and desktop application

FxRecord writes `FxAlert\status.json` below the web root containing the configured
`Stream` folder. FxServe or Caddy can serve it without another TCP port or
server process.

Open the application through HTTPS, for example:

```text
https://yourbroadcaststation.yourdomain.com/FxAlert/
```

Choose **Enable alerts**, allow notifications and install the application when
the browser offers that option. It checks FxRecord every five seconds, sounds
an alarm, shows a notification while active and warns when the heartbeat is
more than 20 seconds old. **Acknowledge** silences the current warning on that
device; a new warning sounds again.

The application shell is cached, but `status.json` must remain uncached.
Add `/fxalert/status.json` to FxServe's `NoStoreRoutes` setting. Caddy should
send `Cache-Control: no-store` for this file.

With FxServe's `[Push] Enabled=True`, **Enable alerts** also creates a secure
Web Push subscription. Android and Windows devices can receive warnings
while FxAlert is closed. On iPhone and iPad, add FxAlert to the Home Screen,
open the installed application and enable alerts there. FxServe sends an
authenticated wake-up; the service worker retrieves warning details directly
from `status.json` over HTTPS.

## LAN desktop administration

[FxRecord Admin](FxRecordAdmin/README.md) is a separate Windows desktop
application for service control, recorder settings, logs and status over
the LAN. It uses Windows authentication, native service control and an SMB
configuration share. Its README describes access rights, firewall rules,
background refresh, saving and closing.

Project: Media Foundation - MFPack - Samples
 
Project location:  
https://github.com/FactoryXCode/MfPack  
https://github.com/FactoryXCode/FactoryX-Radio-DJ
https://sourceforge.net/projects/MFPack  
 
First release date: 09/07/2023  
Final release date: 10/10/2026
 
Copyright © FactoryX. All rights reserved.
