# Paperless-ngx Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Paperless-ngx document management platform.

Paperless-ngx runs as a Docker Compose stack inside the Docker LXC (CT100). It provides self-hosted document ingestion, OCR processing, organization, tagging, and archival capabilities.

## Container Information

| Property        | Value                               |
| --------------- | ----------------------------------- |
| Container       | Docker LXC (CT100)                  |
| Platform        | Debian LXC                          |
| Runtime         | Docker Engine                       |
| Management      | Docker Compose                      |
| Compose Project | `/opt/stacks/paperless`             |
| Reverse Proxy   | Caddy                               |
| External URL    | `https://paperless.example.com` |

## Architecture

```text
Proxmox Host
└── Docker LXC (CT100)
    └── Docker Compose
        ├── paperless
        ├── paperless-db
        └── paperless-redis
```

### Request flow

1. Browser
2. Cloudflare DNS
3. Caddy Reverse Proxy
4. Docker LXC
5. Paperless Container :8010

## Responsibilities

Paperless-ngx is responsible for:

- Document ingestion
- OCR processing
- Document search
- Document tagging and organization
- Metadata management
- Document archival
- Export management

## Dependencies

Paperless depends on:

- Proxmox VE
- Docker LXC (CT100)
- Docker Engine
- Docker Compose
- PostgreSQL
- Redis
- Persistent storage mounts
- Caddy reverse proxy
- DNS resolution

## Storage Layout

Paperless stores data across multiple directories.

| Path                           | Purpose                     |
| ------------------------------ | --------------------------- |
| `/opt/stacks/paperless`        | Docker Compose project      |
| `/storage/paperless/data`      | Paperless application data  |
| `/storage/paperless/db`        | PostgreSQL database storage |
| `/documents/paperless/media`   | Document media library      |
| `/documents/paperless/export`  | Export directory            |
| `/documents/paperless/consume` | Document import directory   |

### Directory Structure

Docker LXC (CT100)

```text
/
├── opt/
│   └── stacks/
│   └── paperless/
│       ├── docker-compose.yml
│       └── .env
│
├── storage/
│   └── paperless/
│       ├── data/
│       └── db/
│
└── documents/
    └── paperless/
        ├── media/
        ├── export/
        └── consume/
```

Verify storage mounts:

```bash
df -h
```

Verify directories:

```bash
ls -lah /storage/paperless
ls -lah /documents/paperless
```

## Docker Compose Stack

The Paperless stack is managed using Docker Compose.

### Compose Location

```text
/opt/stacks/paperless
```

Files:

```text
docker-compose.yml
.env
```

Verify:

```bash
cd /opt/stacks/paperless
ls -lah
```

Validate the rendered configuration:

```bash
docker compose config
```

## Containers

The stack consists of:

| Container         | Purpose             |
| ----------------- | ------------------- |
| `paperless`       | Main application    |
| `paperless-db`    | PostgreSQL database |
| `paperless-redis` | Redis cache/queue   |

Verify containers:

```bash
docker ps --filter name=paperless
```

Expected:

```text
paperless
paperless-db
paperless-redis
```

## Environment Configuration

Paperless uses:

```text
/opt/stacks/paperless/.env
```

Important variables:

| Variable               | Purpose            |
| ---------------------- | ------------------ |
| `PAPERLESS_SECRET_KEY` | Application secret |
| `POSTGRES_PASSWORD`    | Database password  |

The environment file should be backed up. Because backups contain credentials, protect backup storage appropriately.

## Service Management

Navigate to the stack:

```bash
cd /opt/stacks/paperless
```

Start

```bash
docker compose up -d
```

Stop

```bash
docker compose down
```

Restart

```bash
docker compose restart
```

View Status

```bash
docker compose ps
```

View Logs

All services:

```bash
docker compose logs
```

Application logs:

```bash
docker compose logs paperless
```

Database logs:

```bash
docker compose logs db
```

Redis logs:

```bash
docker compose logs redis
```

## Access

Internal Access

```text
http://192.0.2.20:8010
```

External Access

```text
https://paperless.example.com
```

Verify:

- Web interface loads
- User authentication works
- Documents are searchable
- Uploads function
- OCR processing completes

## Reverse Proxy Configuration

Paperless is exposed through Caddy.

Configuration:

```text
/etc/caddy/sites/paperless.caddy
```

Current configuration:

```text
paperless.example.com {
    reverse_proxy 192.0.2.20:8010
}
```

After modifying Caddy:

Validate:

```text
caddy validate --config /etc/caddy/Caddyfile
```

Reload:

```text
systemctl reload caddy
```

## Updating Paperless

Navigate to the stack:

```bash
cd /opt/stacks/paperless
```

Pull updates:

```bash
docker compose pull
```

Deploy:

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

## Backup

Paperless backups are handled by:

```text
scripts/backup/backup-paperless.sh
```

The backup is executed through:

```text
backup-all.sh
```

### Backup Location

```text
/srv/backups/paperless
```

### Backed Up Data

The backup includes:

#### Docker Configuration

```text
/opt/stacks/paperless
```

Includes:

- `docker-compose.yml`
- `.env`

#### Application Data

```text
/storage/paperless/data
```

#### Document Storage

```text
/documents/paperless/media
/documents/paperless/export
/documents/paperless/consume
```

#### Database

A PostgreSQL logical dump is created:

```text
paperless-db-\*.sql.gz
```

### Backup Inventory

The backup process also collects:

- Docker container information
- Container logs
- Rendered Compose configuration
- Environment information

Inventory location:

```text
/srv/backups/paperless/inventories
```

## Recovery Procedure

### 1. Restore Docker LXC

Restore the Docker LXC (CT100) from the latest Proxmox backup.

Verify:

```bash
pct list
```

Start if required:

```bash
pct start 100
```

### 2. Verify Docker

Inside the Docker LXC:

```bash
docker version
```

Verify Docker Compose:

```bash
docker compose version
```

### 3. Restore Compose Configuration

Restore:

```text
/opt/stacks/paperless
```

Required files:

```text
docker-compose.yml
.env
```

Verify:

```bash
cd /opt/stacks/paperless
docker compose config
```

### 4. Restore Persistent Storage

Verify storage directories:

```bash
ls -lah /storage/paperless
ls -lah /documents/paperless
```

Expected:

```text
/storage/paperless/data
/storage/paperless/db
/documents/paperless/media
/documents/paperless/export
/documents/paperless/consume
```

### 5. Restore Database

Locate the latest database backup:

```text
/srv/backups/paperless/databases
```

Start only the database service:

```bash
docker compose up -d db
```

Restore:

```bash
gunzip -c paperless-db-latest.sql.gz | docker exec -i paperless-db psql -U paperless
```

### 6. Start Paperless Stack

Start all services:

```bash
docker compose up -d
```

Verify:

```bash
docker compose ps
```

### 7. Validate Recovery

Verify:

- Paperless container is healthy
- Database is running
- Redis is running
- Users can authenticate
- Existing documents appear
- OCR/search works
- Caddy access works

## Troubleshooting

### Containers Not Running

Check:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

### Database Issues

Verify PostgreSQL:

```bash
docker ps --filter name=paperless-db
```

Check logs:

```bash
docker compose logs db
```

### Missing Documents

Verify:

```bash
ls -lah /documents/paperless/media
```

Check permissions:

```bash
ls -lah /documents/paperless
```

### Upload Problems

Verify:

```bash
ls -lah /documents/paperless/consume
```

Check:

- Storage availability
- Directory permissions
- Container health

## Maintenance Checklist

### Weekly

- [ ] Verify containers are healthy
- [ ] Review Paperless logs
- [ ] Confirm document ingestion works
- [ ] Verify backup completion

### Monthly

- [ ] Update Paperless images
- [ ] Review storage usage
- [ ] Confirm database backups exist
- [ ] Test document restore process

### Quarterly

- [ ] Test full recovery procedure
- [ ] Review backup retention
- [ ] Remove unused Docker images
- [ ] Update documentation

## Verification Checklist

After maintenance or recovery:

- [ ] Docker containers running
- [ ] Paperless web interface accessible
- [ ] Users can authenticate
- [ ] Documents visible
- [ ] OCR processing works
- [ ] Search works
- [ ] Reverse proxy works
- [ ] Backups complete successfully
