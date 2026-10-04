# FxRecord

FxRecord is the FactoryX server-side compliance recorder for RDJ Pro broadcasts.
It runs beside FxServe or Caddy and watches the local published stream folder.
It does not download the public HTTPS stream.

## Current milestone

The initial VCL application provides:

- stream and archive folder configuration;
- live manifest and session monitoring;
- disk warning and critical thresholds;
- an atomic `FxAlert/status.json` heartbeat and warning feed;
- FxAlert warnings for phones, tablets and desktop computers;
- crash-safe source recording to fragmented MP4;
- clock-aligned file rotation and configurable retention;
- active filename and recording progress in the application log;
- an editable Delphi VCL form.

The recording engine supports these output profiles:

- `SourceCopy` and `MP4-H264-AAC` keep RDJ Pro's H.264 video and AAC audio
  without reducing their quality.
- `AVI-H264-MP3` creates a real AVI file with H.264 video at 25 fps and MP3
  stereo audio at 44.1 kHz and 192 kbps. Video is converted to meet the
  compliance frame-rate minimum.

Active MP4 recordings use the `.mp4.partial` suffix. AVI recording first uses
a safe `.avi.source.mp4.partial` file. When the source segment closes, FxRecord
converts it in the background and publishes the result as `.avi`. If conversion
fails, the source MP4 is kept and the administrator receives an FxAlert warning.
If FxRecord finds an unfinished file after a crash, it preserves and reports
that file instead of overwriting it.

FxRecord rebases the video and audio decode timelines separately at the start
of every archive file. Each completed MP4 therefore starts at time zero even
when the RDJ Pro broadcast session has already been running for hours. This
keeps the elapsed time and seek position correct in players such as VLC.

`AVI-H264-MP3` uses FFmpeg. Place `ffmpeg.exe` beside `FxRecord.exe` on the
server. The MfPack development tree also finds the copy used by the
`MfCastPlayer II` sample. Check the FFmpeg build's licence before distributing
it with a product.

## Windows service

Copy `FxRecord.exe`, `FxRecord.ini`, and—when AVI output is used—`ffmpeg.exe`
to a local folder on the broadcast server, for example `C:\FxRecord`. Use
server-local paths in `FxRecord.ini`; a service running as LocalSystem should
not depend on a network share that points back to the same computer.

Open Command Prompt as administrator and run:

```bat
C:\FxRecord\Install-FxRecord.cmd
```

The installer registers `FactoryX FxRecord` as a delayed automatic Windows
service and configures three restart attempts with a 60-second delay. The
service starts without a signed-in user and writes `FxRecord.log` beside its
INI file.

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

This first version must remain open for reliable monitoring. Secure Web Push
will be added next so Android, Apple and Windows devices can receive warnings
while the app is closed.
