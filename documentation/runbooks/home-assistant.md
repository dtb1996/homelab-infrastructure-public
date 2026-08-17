# Home Assistant Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Home Assistant smart home platform. Home Assistant runs in its own dedicated LXC container using Docker Compose and provides the central hub for home automation, device integrations, dashboards, automations, and notifications.

## Container Information

| Property        | Value                      |
| --------------- | -------------------------- |
| Container       | Home Assistant LXC (CT140) |
| Platform        | Debian LXC                 |
| Runtime         | Docker Engine              |
| Management      | Docker Compose             |
| Compose Project | `/opt/homeassistant`       |
| Reverse Proxy   | Caddy                      |

## Responsibilities

Home Assistant is responsible for:

- Home automation
- Device and sensor integrations
- Dashboard hosting
- Automation execution
- Notification delivery
- Historical data storage
- Integration with homelab services

## Dependencies

Home Assistant depends on:

- Proxmox VE
- Docker Engine
- Docker Compose
- Local network connectivity
- AdGuard DNS
- Caddy reverse proxy
- Internet connectivity
- Smart home devices

## Important Directories

| Path                                             | Purpose                                 |
| ------------------------------------------------ | --------------------------------------- |
| `/opt/homeassistant`                             | Docker Compose project                  |
| `/opt/homeassistant/docker-compose.yml`          | Container definition                    |
| `/opt/homeassistant/config`                      | Persistent Home Assistant configuration |
| `/opt/homeassistant/config/configuration.yaml`   | Main configuration                      |
| `/opt/homeassistant/config/automations.yaml`     | Automation definitions                  |
| `/opt/homeassistant/config/scripts.yaml`         | Script definitions                      |
| `/opt/homeassistant/config/scenes.yaml`          | Scene definitions                       |
| `/opt/homeassistant/config/secrets.yaml`         | Encrypted secrets and credentials       |
| `/opt/homeassistant/config/home-assistant_v2.db` | Home Assistant database                 |

## Storage Layout

Home Assistant stores all persistent data inside the configuration directory.

```text
/opt/homeassistant
│
├── docker-compose.yml
│
└── config
    ├── configuration.yaml
    ├── automations.yaml
    ├── scripts.yaml
    ├── scenes.yaml
    ├── secrets.yaml
    ├── custom_components/
    ├── blueprints/
    └── home-assistant_v2.db
```

## Docker Stack

Home Assistant is deployed using Docker Compose.

Verify the stack directory:

```bash
/opt/homeassistant
```

Files include:

- `docker-compose.yml`
- `config/`

Verify containers:

```bash
docker ps
```

## Service Management

Navigate to the stack:

```bash
cd /opt/homeassistant
```

Start:

```bash
docker compose up -d
```

Stop:

```bash
docker compose down
```

Restart:

```bash
docker compose restart
```

View status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs --tail=100
```

## Access

Internal:

```text
http://192.0.2.42:8123
```

External:

```text
https://ha.example.com
```

Verify:

- Web interface loads
- Login succeeds
- Dashboards load correctly
- Entities update
- Automations execute

## Configuration Management

Primary configuration:

```text
/opt/homeassistant/config/configuration.yaml
```

Additional configuration files:

- `automations.yaml`
- `scripts.yaml`
- `scenes.yaml`
- `secrets.yaml`
- `custom_components/`
- `blueprints/`

After configuration changes, validate using:

```bash
docker compose exec homeassistant ha core check
```

Restart after successful validation:

```bash
docker compose restart
```

## Updating Home Assistant

Navigate to the Compose project:

```bash
cd /opt/homeassistant
```

Pull updated images:

```bash
docker compose pull
```

Deploy updates:

```bash
docker compose up -d
```

Verify:

```bash
docker compose ps
```

Review logs:

```bash
docker compose logs --tail=100
```

Confirm:

- Home Assistant starts successfully
- Integrations load
- Automations execute
- Dashboards render correctly

## Storage Verification

Verify available storage:

```bash
df -h
```

Verify configuration files:

```bash
ls -lah /opt/homeassistant/config
```

Verify Docker status:

```bash
docker ps
```

Backup

Nightly backups include:

- Docker Compose configuration:
  - `/opt/homeassistant/docker-compose.yml`
- Home Assistant configuration:
  - `/opt/homeassistant/config`

Important data protected:

- `Automations
- `Scripts
- `Scenes
- `Secrets
- `Custom integrations
- `Blueprints
- `Database history

Backup logs are stored on the Proxmox host:

```text
/srv/backups/logs
```

## Recovery Procedure

### 1. Restore the LXC

Restore the latest Home Assistant LXC backup.

Verify:

```bash
pct list
pct status 140
```

### 2. Verify Docker Engine

Confirm Docker is operational:

```bash
docker version
docker ps
```

### 3. Restore the Docker Compose Project

Restore:

```text
/opt/homeassistant
```

Verify:

```bash
ls -lah /opt/homeassistant
```

Expected contents:

- `docker-compose.yml`
- `config/`

### 4. Restore Home Assistant Configuration

Restore:

```text
/opt/homeassistant/config
```

Verify:

```bash
ls -lah /opt/homeassistant/config
```

Confirm important files exist:

- `configuration.yaml`
- `automations.yaml`
- `scripts.yaml`
- `scenes.yaml`
- `secrets.yaml`

### 5. Deploy the Stack

Navigate to the Compose project:

```bash
cd /opt/homeassistant
```

Start Home Assistant:

```bash
docker compose up -d
```

Verify:

```bash
docker compose ps
```

### 6. Validate the Service

Access:

```text
https://ha.example.com
```

Verify:

- Users can log in
- Dashboards load
- Devices appear
- Automations execute
- Notifications work
- Historical data is available

Review logs if necessary:

```bash
docker compose logs --tail=100
```

## Troubleshooting

### Container Not Running

Check status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

Restart:

```bash
docker compose restart
```

### Configuration Errors

Verify configuration:

```bash
docker compose exec homeassistant ha core check
```

Review:

```text
/opt/homeassistant/config/configuration.yaml
```

### Integration Problems

Verify:

- Network connectivity
- Device availability
- Integration credentials
- Secrets file
- DNS resolution

Restart Home Assistant after corrections.

### Reverse Proxy Issues

Verify Caddy:

```bash
systemctl status caddy
```

Confirm:

- `ha.example.com` resolves correctly
- HTTPS certificate is valid
- Caddy configuration exists

### Device Offline

Verify:

- Device power
- Network connectivity
- Integration status
- Required hubs/coordinators

## Maintenance Checklist

### Weekly

- [ ] Review Home Assistant logs
- [ ] Verify automations execute
- [ ] Check integration health
- [ ] Confirm backups complete

### Monthly

- [ ] Update Home Assistant image
- [ ] Update custom integrations
- [ ] Review failed automations
- [ ] Check database growth

### Quarterly

- [ ] Test restore procedure
- [ ] Review dashboards
- [ ] Audit integrations
- [ ] Update documentation

## Verification Checklist

After maintenance or recovery, verify:

- [ ] Home Assistant container is running
- [ ] Web UI is accessible
- [ ] Reverse proxy access works
- [ ] Dashboards load
- [ ] Devices update correctly
- [ ] Automations execute
- [ ] Notifications work
- [ ] Backups complete successfully
