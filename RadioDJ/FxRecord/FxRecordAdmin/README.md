# FxRecord Admin

FxRecord Admin is a Delphi VCL desktop application for administering the
FactoryX FxRecord Windows service over a local Windows network. It uses
Windows' Service Control Manager and SMB file shares. No additional server
software, web endpoint, cloud account or public port forwarding is required.

## Connecting

1. Install the FxRecord Windows service on the broadcast server.
2. Share the folder containing the service's INI. For example, share
   `C:\FxRecord` as `FxRecord`. Give the administrator's Windows account
   read and write access to the configuration folder and read access to the log.
3. Run `FxRecordAdmin.exe` on the administrator's Windows PC.
4. Enter the server's LAN computer name or IPv4 address and shared INI path,
   such as `\\RADIO-SERVER\FxRecord\FxRecord.ini`. Select **Connect / reload**.

For PCHP001, use:

```text
LAN server: PCHP001
Shared INI: \\PCHP001\FxRecord\FxRecord.ini
```

The **Service INI** field shows the local filename from the registered service
command, for example `C:\FxRecord\FxRecord.ini`. The shared path must refer to
that same file. Custom INI filenames registered with `--config` are supported.
The application manages the service named `FxRecord` whose registered
executable is `FxRecord.exe`.

For administration on the server itself, enter `.` as the computer name and
a local INI filename. The connection profile is stored under the current
user's `HKCU\Software\FactoryX\FxRecordAdmin` registry key.

## Windows access and LAN firewall

The signed-in Windows account needs permission to query the service's status
and configuration, start and stop FxRecord, and access the shared directory.
Membership of the server's Administrators group is one way to grant these
permissions; access can also be delegated for this service and share.
Run the application elevated when local service permissions require it.

On the broadcast server, enable the built-in **Remote Service Management**
rules and **File and Printer Sharing (SMB-In)** rule as required. Limit them
to **Domain/Private** profiles and **Local subnet**, or specific administrator
PC addresses. Keep them disabled on the Public profile. These firewall
settings restrict access to the LAN; no router port forwarding is required.

Remote service control uses Windows RPC; configuration and log access use
SMB. Network operations run in a background worker because connection
requests may take time to return. Windows errors appear in **Admin activity**.
See Microsoft's [Service Control Manager documentation](https://learn.microsoft.com/en-us/windows/win32/services/service-control-manager)
and [RPC transport documentation](https://learn.microsoft.com/en-us/windows/win32/services/services-and-rpc-tcp).

Both connections use the Windows account's credentials. To use another
account, launch the application with **Run as different user**.
The application does not store passwords.

## Service control and recording settings

- View service state, process ID and exit codes.
- Start, stop or restart FxRecord and wait for the final service state.
- Edit recording folders, rotation, retention, polling, disk thresholds,
  live timeout, output profile and MP3/AAC sample rates and bitrates.
- **Save (stopped)** saves the configuration while the service is stopped.
- **Save & restart** stops a running service, saves the configuration and
  restarts it. A service that was already stopped remains stopped.
- View the last 128 KiB of the log, FxAlert status and admin activity.

Folder settings refer to paths on the server. Relative paths remain relative
to the server's INI. For PCHP001, the stream path is `C:\FxServe\www\Stream`
and the archive path is `F:\ComplianceRecordings`.

The output profiles and supported audio settings are described in the
[FxRecord README](../README.md). MP3 and AAC controls are available for their
matching profiles.

## Background refresh and buttons

After connecting, the application refreshes service state, logs and status
five seconds after the previous operation finishes. Refresh leaves unsaved
settings intact and keeps the service and save buttons available when the
service state permits their actions.

A command selected during refresh is queued until that read completes, then
runs once. Further clicks cannot create overlapping commands. During an
actual service command or save, controls are temporarily disabled until the
operation completes.

Save buttons remain available even when the loaded settings have no edits.
**Save (stopped)** requires a stopped service; **Save & restart** is available
when the service is running or stopped.

**Close** during background refresh hides the window immediately. The
application finishes closing when the read returns. Closing waits for an
active or queued service command or configuration save to finish.

## Configuration saves and logs

Every save preserves unknown INI settings, creates a timestamped `.bak` file
beside the INI, stages a UTF-8 temporary file and replaces the configuration.
If another program has changed the INI since it was loaded, the save is
refused. Select **Connect / reload** to load the current version.

If a save fails after stopping a running service, the application attempts
to restart the previous configuration. If the saved configuration cannot
start, **Admin activity** reports the saved settings and service error;
the backup remains available.

Stopping waits for active recordings and queued conversions to finish.
A command still pending after two minutes is reported so its status can
be refreshed before another command is attempted.

The log is beside the selected INI: `FxRecord.ini` produces `FxRecord.log`.
FxRecord writes it in desktop and service modes, including installation and
startup diagnostics. On PCHP001, the shared log is
`\\PCHP001\FxRecord\FxRecord.log`. The recording account needs write access,
and the administrator needs read access.

FxAlert status is read from `FxAlert\status.json` beside the configured
stream folder. If it lies outside the configuration share, the application
tries the corresponding Windows drive administrative share, such as `C$`.
That share may require additional permissions. A missing log or status file
does not prevent service administration.

## Building and checks

Open `FxRecordAdmin.dproj` in Delphi. The project uses VCL, Windows APIs and
the shared `FxRecord.Config` unit. The editable form is
`frmFxRecordAdmin.dfm`. Win64 and Win32 executables are built in
`Win64\Debug` and `Win32\Debug`.

`Checks\AdminChecks.dpr` verifies command parsing, connection paths,
configuration validation and round trips, native form loading, service and
save button states, command queuing, retention of unsaved edits and closing
during refresh. These checks simulate service results; they do not start or
stop a real service. A live LAN check requires a server and an account with
the permissions described above.

Project location:  
https://github.com/FactoryXCode/MfPack  
https://github.com/FactoryXCode/FactoryX-Radio-DJ
https://sourceforge.net/projects/MFPack  
 
First release date: 09/07/2023  
Final release date: 10/10/2026
 
Copyright © FactoryX. All rights reserved.
