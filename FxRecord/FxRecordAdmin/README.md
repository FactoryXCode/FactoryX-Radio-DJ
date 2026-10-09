# FxRecord Admin

FxRecord Admin is a Delphi VCL desktop application for administering the
FactoryX FxRecord Windows service on a local Windows network. It uses Windows'
Service Control Manager and SMB file shares; it needs no web endpoint, cloud
account, public port forwarding, or third-party server software.

## Connect

1. Install the existing FxRecord Windows service on the broadcast server.
2. Share the folder containing the INI used by that service, for example share
   C:\FxRecord as FxRecord. Give the administrator's Windows account read/write
   access to the INI directory and read access to the log.
3. Run FxRecordAdmin.exe on the administrator's Windows PC.
4. Enter the LAN computer name (or LAN IPv4 address), and the shared INI:
   \\RADIO-SERVER\FxRecord\FxRecord.ini. Click **Connect / reload**.

The **Service INI** field shows the server-local filename from the registered
FxRecord service command. The share must map to that same INI file.
Custom INI filenames registered with --config are supported. The app manages
only the service named FxRecord whose registered executable is FxRecord.exe.

For administration on the server itself, enter "." as the computer name and
a local INI filename. A connection profile is saved under the current user's
HKCU\Software\FactoryX\FxRecordAdmin key. Passwords are not stored.

## Windows access and LAN firewall

The signed-in Windows identity needs service query/configuration-read,
start and stop permissions on FxRecord, plus access to the shared directory.
Membership in the server's Administrators group is one way to provide these
permissions; rights may also be delegated for just this service and share.
Run the app elevated when administering a local service that requires it.

On the broadcast server, enable the built-in **Remote Service Management**
rules and the **File and Printer Sharing (SMB-In)** rule as needed. Limit the
rules to **Domain/Private** profiles and remote addresses **Local subnet**, or
the specific admin PCs. Keep them disabled on the Public profile.
No router port forwarding is required.

Remote service control uses Windows RPC, and shared INI/log access uses SMB.
If RPC or SMB is blocked, the app reports the Windows error; a remote SCM
connection can take time to time out, so network operations run in a worker.
See Microsoft's [Service Control Manager documentation](https://learn.microsoft.com/en-us/windows/win32/services/service-control-manager)
and [RPC transport documentation](https://learn.microsoft.com/en-us/windows/win32/services/services-and-rpc-tcp).

Windows account credentials are used by both SCM and SMB. For a different
account, launch the app using Windows **Run as different user**; the app has
no separate password database.

## Administration

- Query the service's state, process ID and exit codes.
- Start, stop or restart FxRecord, waiting for the actual final service state.
- Edit recording folders, rotation, retention, polling, disk thresholds, live
  timeout, output profile and the MP3/AAC sample rates and bitrates.
- **Save (stopped)** saves configuration while the service is stopped.
- **Save & restart** stops a running service, saves configuration and restarts
  it. If it was already stopped, it stays stopped.
- View the last 128 KiB of the service log, FxAlert status and admin activity.
- Refresh service state and log/status files every five seconds after connecting.

Folder values are paths on the server. Relative paths remain relative to the
server's INI, rather than being resolved on the administrator's PC.
Unknown INI settings survive edits. Every save creates a timestamped .bak
beside the INI, stages a UTF-8 temporary file, and replaces the INI.
A save is refused if another program changed the INI since it was loaded.
Reconnect to reload those changes.

Stopping waits for FxRecord to complete active recordings and queued conversions.
A command that has not completed after two minutes is reported as still pending.
The UI remains responsive and blocks overlapping commands and closing during
a service command. Auto-refresh keeps unsaved recorder settings and service buttons available. A command clicked during refresh is queued until that read finishes; duplicate clicks cannot create overlapping operations. Save buttons remain available in their valid service states, including when the loaded settings have no edits. Close during refresh hides the window immediately and completes shutdown after the read returns.
If a save fails after stopping, the app attempts to restart the prior configuration.
If starting the saved configuration fails, the activity log identifies the saved
configuration and the service error; the backup remains available.

FxAlert status is read from the server stream folder's sibling FxAlert/status.json.
If that path is outside the configuration share, the app attempts the corresponding
Windows drive administrative share (such as C$), which may need additional access.
A missing log or status file does not prevent service administration.

## Build and checks

Open FxRecordAdmin.dproj in Delphi. The project uses VCL, Windows APIs and the
shared FxRecord.Config unit. Editable form: frmFxRecordAdmin.dfm.

Win64 and Win32 executable output: Win64/Debug and Win32/Debug.
Checks/AdminChecks.dpr verifies command parsing, connection paths, configuration
validation/round trips, native form loading, service button states, refresh command queuing and retention
of unsaved edits during refresh. It does not start or stop a real service.
A live LAN test requires a server and an account with the permissions above.
