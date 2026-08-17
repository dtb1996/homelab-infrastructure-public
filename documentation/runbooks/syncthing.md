# Syncthing Runbook

## Overview

This runbook documents the installation, operation, maintenance, backup, and recovery procedures for Syncthing.

Syncthing runs in a dedicated unprivileged LXC container and provides continuous file synchronization between trusted devices.

The current deployment is primarily used to synchronize Dusklight game data between the Windows RetroBat system, Android device, and the Syncthing LXC.

## Container Information

| Property         | Value                           |
| ---------------- | ------------------------------- |
| Container        | Syncthing LXC (CT121)           |
| Service          | Syncthing                       |
| Purpose          | Continuous file synchronization |
| Operating System | Debian                          |
| Container Type   | Unprivileged LXC                |
| CPU              | 1 core                          |
| Memory           | 512 MiB                         |
| Root Disk        | 8 GB                            |
| Data Storage     | USB Storage                     |
| Internal IP      | `192.0.2.41`                 |
| GUI              | `http://192.0.2.41:8384`     |
| External Access  | `https://sync.example.com`  |

## Responsibilities

Syncthing is responsible for:

- Continuous file synchronization
- Synchronizing trusted devices
- Maintaining synchronized folder state
- Detecting file changes
- Handling synchronization conflicts
- Providing device discovery
- Providing the Syncthing web interface

Syncthing is **not** the primary backup system. Synchronized data is still protected by the homelab's storage backup strategy.

## Dependencies

Syncthing depends on:

- Proxmox VE
- USB Storage
- Network connectivity
- AdGuard DNS
- Caddy for external HTTPS access

## Storage Layout

The Syncthing LXC uses a bind mount from the Proxmox USB storage.

### Proxmox Host

```text
/mnt/backup/shared/syncthing/
└── dusklight/
    ├── achievements.json
    ├── EUR/
    ├── texture_replacements/
    └── USA/
        └── Card A/
            └── 01-GZ2E-gczelda2.gci
```

### LXC

The host directory is mounted into CT121 as:

```text
/mnt/backup/shared/syncthing
        ↓
/data
```

Therefore:

```text
/data/
└── dusklight/
```

contains the synchronized Dusklight data.

### LXC Configuration

The mount is defined in the Proxmox container configuration:

```text
mp0: /mnt/backup/shared/syncthing,mp=/data
```

The container is unprivileged:

```text
unprivileged: 1
```

## Configuration Layout

Syncthing 2.x stores its configuration under the user's XDG state directory.

For CT121, the Syncthing service runs as the `syncthing` system user with:

```text
/var/lib/syncthing
```

as its home directory.

Configuration is stored under:

```text
/var/lib/syncthing/.local/state/syncthing/
```

Current files include:

```text
/var/lib/syncthing/.local/state/syncthing/
├── config.xml
├── config.xml.v0
├── cert.pem
├── https-cert.pem
├── key.pem
├── https-key.pem
└── syncthing.lock
```

## Important Files

| Path                                                       | Purpose                             |
| ---------------------------------------------------------- | ----------------------------------- |
| `/var/lib/syncthing/.local/state/syncthing/config.xml`     | Syncthing configuration             |
| `/var/lib/syncthing/.local/state/syncthing/cert.pem`       | Device identity certificate         |
| `/var/lib/syncthing/.local/state/syncthing/key.pem`        | Device identity key                 |
| `/var/lib/syncthing/.local/state/syncthing/https-cert.pem` | HTTPS certificate for GUI           |
| `/var/lib/syncthing/.local/state/syncthing/https-key.pem`  | HTTPS private key                   |
| `/data`                                                    | Syncthing bind-mounted data storage |

## Service Management

Syncthing runs as a systemd template service using the `syncthing` user.

### Check Status

```bash
systemctl status syncthing@syncthing.service
```

### Start

```bash
systemctl start syncthing@syncthing.service
```

### Stop

```bash
systemctl stop syncthing@syncthing.service
```

### Restart

```bash
systemctl restart syncthing@syncthing.service
```

### Enable at Boot

```bash
systemctl enable syncthing@syncthing.service
```

### Enable and Start

```bash
systemctl enable --now syncthing@syncthing.service
```

## Health Checks

### Verify Service

```bash
systemctl status syncthing@syncthing.service
```

Confirm the service is:

```text
Active: active (running)
```

### Verify Process

```bash
ps aux | grep '[s]yncthing'
```

### Verify Storage

```bash
ls -la /data
```

Verify the expected synchronized folders are present.

### Verify Syncthing Version

```bash
syncthing --version
```

### Verify GUI

The Syncthing GUI is available internally at:

```text
http://192.0.2.41:8384
```

External access is provided through:

```text
https://sync.example.com
```

## Device Configuration

Syncthing uses device identities to establish trusted synchronization relationships.

The current deployment includes:

- Syncthing LXC
- Windows desktop / RetroBat system
- Android device

Each device must be explicitly added and accepted before synchronization can occur.

### Adding a Device

1. Open the Syncthing GUI.
2. Select **Add Remote Device**.
3. Enter the remote device ID.
4. Assign a descriptive device name.
5. Save the configuration.
6. Accept the device on the remote system.
7. Verify that the device becomes connected.

### Device Verification

Verify:

- Device is listed as connected.
- Device ID is correct.
- Recent connection time is displayed.
- No synchronization errors are reported.

## Folder Configuration

The primary synchronized folder is the Dusklight `data` directory.

The folder is mounted as:

```text
/data/dusklight
```

The same logical folder should be configured on the Windows and Android devices so that the required files maintain the same relative paths.

## Dusklight Synchronization

The current synchronization target contains selected Dusklight data.

Files intended to synchronize include:

```text
achievements.json
USA/Card A/01-GZ2E-gczelda2.gci
```

The `USA/Card A` directory structure is intentionally preserved so that the GameCube memory card save remains in the expected location.

Platform-specific files are excluded using Syncthing ignore patterns.

Current ignore patterns include:

```text
/texture_replacements/
/EUR/
config.json
imgui.ini
*.dat
*.controller
```

The `EUR` and `texture_replacements` directories may still appear as empty directories on some devices. This is expected and does not indicate that their contents are being synchronized.

## Ignore Pattern Management

Ignore patterns should be configured consistently across devices where possible.

To modify ignore patterns:

1. Open the Syncthing GUI.
2. Open the synchronized folder.
3. Select **Edit**.
4. Open the **Ignore Patterns** section.
5. Add or modify the required patterns.
6. Save the configuration.
7. Verify synchronization status on all connected devices.

After changing ignore patterns, verify that:

- Intended files continue to synchronize.
- Ignored files are not transferred.
- Existing files are handled as expected.
- No unexpected deletion occurs.

Avoid deleting synchronized directories manually until ignore patterns have been configured on all participating devices.

## Permissions

The Syncthing service runs under the dedicated system account:

```text
syncthing
```

Verify:

```bash
id syncthing
```

Expected output includes a dedicated Syncthing UID/GID.

The mounted data must be writable by this user.

Test write access with:

```bash
runuser -u syncthing -- touch /data/dusklight/test.txt
```

Remove the test file after verification:

```bash
rm /data/dusklight/test.txt
```

If permission is denied, verify ownership and permissions on the mounted directory.

```bash
ls -ld /data
ls -ld /data/dusklight
```

For an unprivileged LXC, numeric ownership is important because host and container UIDs are mapped.

## Backup

Syncthing is protected through the existing Proxmox LXC backup strategy.

### LXC Configuration

The following Syncthing configuration is included in the CT121 LXC backup:

```text
/var/lib/syncthing/.local/state/syncthing/
```

This includes:

- Folder definitions
- Device configuration
- Device identities
- Syncthing certificates
- Syncthing service state

### Synchronized Data

The synchronized data is stored separately from the LXC root filesystem:

```text
/mnt/backup/shared/syncthing
```

This directory is bind-mounted into CT121 and is therefore **not stored inside the LXC root disk**.

The data is protected separately by the homelab storage backup strategy.

## Recovery Procedure

### 1. Restore the LXC

Restore CT121 from the latest Proxmox backup.

Verify:

```bash
pct list
```

### 2. Verify the Bind Mount

On the Proxmox host:

```bash
pct config 121
```

Confirm:

```text
mp0: /mnt/backup/shared/syncthing,mp=/data
```

Verify the source directory exists:

```bash
ls -la /mnt/backup/shared/syncthing
```

### 3. Verify the Mount Inside the LXC

Enter the container:

```bash
pct enter 121
```

Verify:

```bash
ls -la /data
```

Confirm the expected synchronized folders are present.

### 4. Verify Syncthing Configuration

```bash
ls -la /var/lib/syncthing/.local/state/syncthing
```

Confirm that `config.xml` and the device identity files exist.

### 5. Start Syncthing

```bash
systemctl enable --now syncthing@syncthing.service
```

Verify:

```bash
systemctl status syncthing@syncthing.service
```

### 6. Verify Devices

Open the Syncthing GUI and confirm:

- Windows device is connected.
- Android device is connected.
- Device IDs are correct.
- Shared folder is present.
- No synchronization errors are reported.

### 7. Verify Data

Confirm the expected files exist:

```bash
find /data/dusklight -maxdepth 4 -type f
```

Verify:

```text
achievements.json
USA/Card A/01-GZ2E-gczelda2.gci
```

### 8. Test Synchronization

Create a temporary test file from one participating device and verify that it appears on the other devices.

Remove the test file afterward.

## Troubleshooting

### Service Won't Start

Check:

```bash
systemctl status syncthing@syncthing.service
```

View logs:

```bash
journalctl -u syncthing@syncthing.service -f
```

### Syncthing GUI Is Unavailable

Verify the service:

```bash
systemctl status syncthing@syncthing.service
```

Verify the listener:

```bash
ss -lntp | grep 8384
```

The GUI normally listens on:

```text
127.0.0.1:8384
```

If external access through Caddy is required, verify the Caddy configuration and proxy routing.

### Devices Won't Connect

Verify:

- Both devices are online.
- Device IDs are correct.
- Devices have been accepted.
- Network connectivity is available.
- Syncthing is running on both devices.

Check Syncthing logs:

```bash
journalctl -u syncthing@syncthing.service
```

### Folder Is Not Synchronizing

Check:

- Folder is shared with the remote device.
- Folder paths are correct.
- Remote device is connected.
- Ignore patterns are not excluding the desired files.
- Permissions allow Syncthing to read and write the folder.

Verify:

```bash
ls -la /data/dusklight
```

### Permission Denied

Check:

```bash
ls -ldn /data
ls -ldn /data/dusklight
```

Test:

```bash
runuser -u syncthing -- touch /data/dusklight/test.txt
```

If necessary, correct ownership on the host storage.

### Unexpected File Deletion

Stop synchronization before investigating if important data may be at risk.

Review:

- Syncthing folder history
- Ignore patterns
- Remote device status
- Recent changes on each device

Do not manually delete files from the synchronized directory until the source of the deletion has been identified.

### Ignored Directories Appear

Empty directories such as:

```text
EUR/
texture_replacements/
```

may still appear on a device even when their contents are ignored.

This is not necessarily a synchronization failure.

Verify that ignored contents are not being transferred rather than relying solely on directory presence.

## Updating Syncthing

Check the installed version:

```bash
syncthing --version
```

Update package information:

```bash
apt-get update
```

Upgrade Syncthing:

```bash
apt-get install --only-upgrade syncthing
```

Restart the service if necessary:

```bash
systemctl restart syncthing@syncthing.service
```

Verify:

```bash
syncthing --version
systemctl status syncthing@syncthing.service
```

## Configuration Management

Syncthing configuration is stored locally in:

```text
/var/lib/syncthing/.local/state/syncthing/
```

The configuration contains device identities and synchronization settings and should be treated as infrastructure configuration.

Relevant configuration changes should be documented in this repository when they affect the overall homelab architecture.

Do not commit private device keys or other sensitive Syncthing identity material to Git.

## Maintenance Checklist

### Weekly

- [ ] Verify Syncthing service is running.
- [ ] Verify all expected devices are connected.
- [ ] Check for synchronization errors.
- [ ] Confirm expected folders are synchronized.

### Monthly

- [ ] Review Syncthing logs.
- [ ] Review connected devices.
- [ ] Review shared folders.
- [ ] Review ignore patterns.
- [ ] Verify LXC backup completion.
- [ ] Verify synchronized data exists on USB storage.

### Quarterly

- [ ] Test Syncthing recovery.
- [ ] Verify device identities and trusted devices.
- [ ] Review unused devices and folders.
- [ ] Review storage utilization.
- [ ] Verify backup and restore procedures.
- [ ] Update documentation if the synchronization architecture changes.

## Verification Checklist

After maintenance or recovery, verify:

- [ ] CT121 is running.
- [ ] Syncthing service is enabled.
- [ ] Syncthing service is running.
- [ ] Syncthing GUI is accessible internally.
- [ ] Caddy provides external HTTPS access.
- [ ] USB storage is mounted.
- [ ] `/data` is accessible.
- [ ] Syncthing has write access to `/data`.
- [ ] Windows device is connected.
- [ ] Android device is connected.
- [ ] Dusklight folder is synchronized.
- [ ] `achievements.json` synchronizes correctly.
- [ ] `USA/Card A` save data synchronizes correctly.
- [ ] Ignored files are not synchronized.
- [ ] Proxmox backup of CT121 completes successfully.
- [ ] Synchronized data remains protected by the storage backup strategy.
