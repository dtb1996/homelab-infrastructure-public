## Immich Runbook

### Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Immich photo management platform. Immich runs in its own dedicated LXC container using Docker Compose and provides self-hosted photo and video management with automatic backups, search, and mobile synchronization.

## Container Information

| Property        | Value              |
| --------------- | ------------------ |
| Container       | Immich LXC (CT131) |
| Platform        | Debian LXC         |
| Runtime         | Docker Engine      |
| Management      | Docker Compose     |
| Compose Project | `/opt/immich`      |
| Reverse Proxy   | Caddy              |

## Responsibilities

Immich is responsible for:

- Photo and video storage
- Mobile device synchronization
- AI-powered search and indexing
- Metadata management
- Album management
- External HTTPS access

## Dependencies

Immich depends on:

- Proxmox VE
- Docker Engine
- Docker Compose
- PostgreSQL (Docker)
- Redis (Docker)
- External USB storage (`/mnt/backup`)
- Caddy reverse proxy
- DNS resolution

## Important Directories

| Path                                       | Purpose                                                                                        |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `/opt/immich`                              | Docker Compose project                                                                         |
| `/opt/immich/postgres`                     | PostgreSQL database files                                                                      |
| `/photos`                                  | Immich media storage (photos, uploads, thumbnails, encoded videos, backups, and user profiles) |
| `/mnt/backup/media/Photos` (Proxmox Host) | Physical Photo library                                                                         |

## Storage Layout

Immich stores its data across multiple layers.

| Layer            | Location                    |
| ---------------- | --------------------------- |
| Proxmox Host     | `/mnt/backup/media/Photos` |
| Immich LXC       | `/photos`                   |
| Docker Container | `/data`                     |
| PostgreSQL       | `/opt/immich/postgres`      |

Storage flow:

- **Proxmox Host:** /mnt/backup/media/Photos
- **Immich LXC:** /photos
- **Docker Container:** /data

## Docker Stack

Immich is deployed using Docker Compose.

Verify the stack directory:

```text
/opt/immich
```

Files include:

- `docker-compose.yml`
- `.env`
- Supporting configuration files

## Containers

The Immich stack consists of:

- immich_server
- immich_postgres
- immich_machine_learning
- immich_redis (Valkey)

Verify:

```bash
docker ps
```

## Environment File

Immich uses a `.env` file located alongside the Compose project:

```text
/opt/immich/.env
```

Important variables include:

- `UPLOAD_LOCATION`
- `DB_DATA_LOCATION`
- `IMMICH_VERSION`
- `DB_DATABASE_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`

This file should be backed up along with the Compose project.

## Service Management

Navigate to the stack:

```bash
cd /opt/immich
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

## Access

Internal:

```text
http://192.0.2.23:2283
```

External:

```text
https://photos.example.com
```

Verify:

- Web interface loads
- User authentication works
- Photos appear
- Uploads function

## Updating Immich

Navigate to the stack:

```bash
cd /opt/immich
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

## Storage Verification

Verify available storage:

```bash
df -h
```

Verify Docker volumes:

```bash
ls /photos
ls /opt/immich/postgres
docker ps
```

Confirm photo storage is mounted correctly.

## Backup

Nightly backups include:

- Docker Compose configuration (`/opt/immich`)
- PostgreSQL database (`/opt/immich/postgres`)
- Immich media storage (`/photos`)

Photo and video files are stored separately and are protected by the overall storage backup strategy.

Verify backup logs from the Proxmox host:

```text
/srv/backups/logs
```

## Recovery Procedure

### 1. Restore the LXC

Restore the Immich LXC from the latest Proxmox backup.

Verify the container is present and running:

```bash
pct list
pct status 131
```

---

### 2. Verify Docker Engine

Confirm Docker Engine is installed and operational.

```bash
docker version
docker ps
```

---

### 3. Restore the Docker Compose Project

Restore the Immich Compose project if it is not included in the LXC backup.

Verify the project directory:

```text
/opt/immich
```

Confirm the required files exist:

```bash
ls -lah /opt/immich
```

Expected contents include:

- `docker-compose.yml`
- `.env`
- `postgres/`

---

### 4. Restore the PostgreSQL Database

If restoring from a separate backup, restore the PostgreSQL data directory.

Database location:

```text
/opt/immich/postgres
```

Verify the database files:

```bash
ls -lah /opt/immich/postgres
```

Expected contents include:

- `PG_VERSION`
- `base/`
- `global/`
- `pg_wal/`

---

### 5. Verify Photo Storage

On the Proxmox host, verify the external storage is mounted:

```text
/mnt/backup/media/Photos
```

Inside the Immich LXC, confirm the bind mount is available:

```bash
mount | grep photos
df -h
ls /photos
```

The `/photos` directory should contain folders similar to:

- `backups`
- `encoded-video`
- `library`
- `profile`
- `thumbs`
- `upload`

Docker automatically bind mounts `/photos` into the Immich container as `/data`.

---

### 6. Deploy the Stack

Navigate to the Compose project:

```bash
cd /opt/immich
```

Start all services:

```bash
docker compose up -d
```

Verify the containers are running:

```bash
docker compose ps
docker ps
```

Expected containers:

- `immich_server`
- `immich_postgres`
- `immich_machine_learning`
- `immich_redis`

---

### 7. Validate the Service

Verify the web interface is accessible:

- Internal: `http://192.0.2.23:2283`
- External: `https://photos.example.com`

Confirm:

- Users can authenticate.
- Photos and videos are visible.
- Albums are intact.
- Recent uploads appear.
- AI search functions correctly.
- Thumbnails generate successfully.
- Mobile uploads complete successfully.

Review container logs if necessary:

```bash
docker compose logs --tail=100
```

The recovery is complete once all containers are healthy, the photo library is accessible, and uploads and search are functioning normally.

## Troubleshooting

### Containers Not Running

View container status:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs
```

### Database Issues

Verify the PostgreSQL container is running:

```bash
docker ps
```

Review database logs:

```bash
docker compose logs database
```

### Machine Learning Issues

Verify the Machine Learning container:

```bash
docker compose logs machine-learning
```

Confirm AI features function correctly after startup.

### Upload Failures

Verify:

- Available disk space
- File permissions
- Docker container health

Review application logs.

### Photos Missing

Verify:

- /photos is mounted
- PostgreSQL restored
- Docker containers are running
- Library paths are unchanged
- `mount | grep photos`

## Maintenance Checklist

### Weekly

- [ ] Verify all containers are healthy
- [ ] Review Docker logs
- [ ] Confirm uploads are functioning
- [ ] Verify storage utilization

### Monthly

- [ ] Update container images
- [ ] Verify database health
- [ ] Review backup logs
- [ ] Confirm mobile synchronization

### Quarterly

- [ ] Test Immich recovery
- [ ] Review storage growth
- [ ] Remove unused Docker images
- [ ] Update documentation

## Verification Checklist

After maintenance or recovery, verify:

- [ ] All containers are running.
- [ ] Users can authenticate.
- [ ] Photos and videos are accessible.
- [ ] Mobile uploads function.
- [ ] Search and AI features work.
- [ ] Reverse proxy access works.
- [ ] Nightly backups complete successfully.
