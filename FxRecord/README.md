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

The first recording engine supports `SourceCopy` and `MP4-H264-AAC`. RDJ Pro's
published stream already contains H.264 video and AAC audio, so FxRecord keeps
the original encoded media without reducing its quality. Active recordings use
the `.mp4.partial` suffix. FxRecord renames them to `.mp4` after rotation or a
normal stop. If FxRecord finds an unfinished file after a crash, it preserves
and reports that file instead of overwriting it.

The remaining output profiles need the conversion engine. Conversion will run
only after the source recording has been safely closed.

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
