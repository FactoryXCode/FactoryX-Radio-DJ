# FxRecord

Version: 4.0.1
  
**NOTES:**
  
- This release is updated for compiler version 17 up to 35.
- SDK version: 10.0.28000.2705 (Win 11)
- Requires Windows 10 or later.
- Minimum supported MfPack version: 4.0.0
  
---

FxRecord is the FactoryX server-side compliance recorder for RDJ Pro broadcasts.
It runs beside FxServe or Caddy and watches the local published stream folder.
It does not download the public HTTPS stream.

## When do you need a compliance recorder

When you are running a broadcast station, your government may need a copy from your 
broadcast activities for a period of time (retention days) in a specific audio/video format. 
 
## Implementations

The initial VCL application provides:

- Stream and archive folder configuration;
- Live manifest and session monitoring;
- Disk warning and critical thresholds;
- An `FxAlert/status.json` online check and warning feed;
- FxAlert warnings for phones, tablets and desktop computers;
- Crash-safe source recording to fragmented MP4;
- Clock-aligned file rotation and configurable retention;
- Active filename and recording progress in the application log;

The recording engine supports these output profiles:

- `SourceCopy` keeps RDJ Pro's H.264 video and AAC audio without re-encoding.
- `MP4-H264-AAC` preserves the H.264 video and encodes stereo AAC at the
  selected sample rate (44.1 or 48 kHz) and bitrate (96, 128, 160 or 192 kbps).
  The AAC bitrate minimum is 96 kbps and the maximum is 192 kbps.
- `AVI-H264-MP3` creates an AVI file with H.264 video at 25 fps and stereo
  MP3 at the selected sample rate (44.1, 48 or 32 kHz) and bitrate
  (128, 160 or 192 kbps). Video is converted to meet the compliance
  frame-rate minimum.

SourceCopy recordings use the `.mp4.partial` suffix. Profiles that encode
audio first record to `.avi.source.mp4.partial` or
`.mp4.source.mp4.partial`. When a source segment closes, FxRecord converts
it in the background and publishes the result as `.avi` or `.mp4`. If
conversion fails, the source MP4 is kept and an FxAlert warning is published.
Unfinished files found after a crash are preserved and reported.

The MP3 and AAC controls are enabled only for their matching output profile.
Each codec remembers its own settings. Save writes them to the INI file,
and the Windows service uses the same settings. Defaults are MP3 at
44.1 kHz/192 kbps and AAC at 44.1 kHz/160 kbps. SourceCopy ignores these values.

```ini
[Audio]
Mp3SampleRate=44100
Mp3BitRateKbps=192
AacSampleRate=44100
AacBitRateKbps=160
```

The Windows AAC encoder supports stereo AAC-LC at 44.1/48 kHz and
96-192 kbps in the listed steps; 32 kHz is available for MP3 only.
See [Microsoft's AAC encoder documentation](https://learn.microsoft.com/en-us/windows/win32/medfound/aac-encoder).

FxRecord rebases the video and audio decode timelines separately at the start
of every archive file. Each completed MP4 therefore starts at time zero even
when the RDJ Pro broadcast session has already been running for hours. This
keeps the elapsed time and seek position correct in players such as VLC.

`AVI-H264-MP3` uses the Windows Media Foundation H.264 and MP3 encoders
through MfPack, with an AVI container writer built into FxRecord. No
third-party converter is required.
The server must have the Windows Media Foundation media components installed.
Conversion uses an intermediate `.avi.partial.encoded.mp4` work file, removed
after success and preserved on failure. The AVI writer supports segments below
2 GiB; use shorter rotation intervals for larger recordings. Exceeding this
limit reports an FxAlert warning and preserves the source.

## Windows service

Copy `FxRecord.exe` and `FxRecord.ini` to a local folder on the broadcast
server, for example `C:\FxRecord`. Use
server-local paths in `FxRecord.ini`; a service running as LocalSystem should
not depend on a network share that points back to the same computer.

Open Command Prompt as administrator and run:

```bat
C:\FxRecord\Install-FxRecord.cmd
```

The installer registers `FxRecord` as a delayed automatic Windows
service and configures three restart attempts with a 60-second delay. If Windows rejects the optional delayed-start setting, the installer logs a warning and retains ordinary automatic startup. The
service starts without a signed-in user. Desktop mode, installation diagnostics
and service mode all write the log beside the selected INI: `FxRecord.ini`
produces `FxRecord.log`. The service account needs write access there.
Installation errors identify the failing Windows operation and error number.
Running the installer again repairs an existing stopped service registration;
it retains the existing service account.

For PCHP001, run the installer **on PCHP001**, elevated, from the actual local
folder behind `\\PCHP001\FxRecord`. Set `ArchivePath` to the local folder behind
`\\PCHP001\ComplianceRecordings`. Share names do not reveal their drive paths;
check the folders in Windows share properties. Use server-local paths for the
executable, INI and archive; UNC paths belong in the remote admin connection.
In FxRecordAdmin enter server `PCHP001` and INI
`\\PCHP001\FxRecord\FxRecord.ini`.

If installation or startup fails, read the new log and inspect:

```bat
sc.exe qc FxRecord
sc.exe query FxRecord
```

The registered command must contain `--service --config` and quote the local
executable and INI filenames. `--service` is used by the Windows service manager;
start the installed service with `sc.exe start FxRecord` or the Services app.

To remove only the service registration:

```bat
C:\FxRecord\Uninstall-FxRecord.cmd
```

FxRecord checks Windows every five minutes for an installed update that needs
a restart. It also asks the Windows Update Agent every six hours whether
updates are waiting for installation. Both conditions are published through
FxAlert so the administrator can choose a safe maintenance window. The update
scan runs in a separate helper process and cannot pause stream recording.

## FxAlert phone and desktop app

FxRecord writes its status to `FxAlert\status.json` below the web root that
contains the configured `Stream` folder. FxServe or Caddy can therefore serve
the same status without another TCP port or server process.

Open this address through HTTPS:

```text
https://YOUR-BROADCAST-NAME/FxAlert/
Like for instance: https://yourbroadcaststation.yourdomain.com/FxAlert/
```

Choose **Enable alerts**, allow notifications, and install the app when the
browser offers that choice. The first version checks FxRecord every five
seconds, sounds an alarm, shows a system notification while the app is active,
and warns when the FxRecord heartbeat is more than 20 seconds old. The
**Acknowledge** button silences the current warning on that device. A new
warning will sound again.

The app shell is cached for quick startup, but `status.json` is never cached.
Add `/fxalert/status.json` to FxServe's `NoStoreRoutes` setting. Caddy should
also send `Cache-Control: no-store` for this file.

When FxServe has `[Push] Enabled=True`, **Enable alerts** also creates a secure
Web Push subscription. Android and Windows devices can then receive warnings
while FxAlert is closed. On iPhone and iPad, add FxAlert to the Home Screen,
open the installed app, and enable alerts there. FxServe sends only an
authenticated wake-up; the service worker retrieves the warning directly from
`status.json` over HTTPS, so recorder details are not sent through a third-party
push service.

## LAN desktop administration

[FxRecord Admin](FxRecordAdmin/README.md) is a separate Windows desktop app for
service start/stop/restart, recorder settings, logs and status over the LAN.
It uses Windows authentication, native service control and an SMB configuration
share. See its setup instructions for access rights and LAN firewall rules.
