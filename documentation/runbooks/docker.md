# Docker LXC Runbook

## Overview

This runbook documents the operation, maintenance, backup, and recovery procedures for the Docker LXC (CT100). The Docker LXC hosts containerized services that share common storage, networking, and reverse proxy infrastructure.

## Container Information

| Property   | Value          |
| ---------- | -------------- |
| Container  | Docker (CT100) |
| Platform   | Debian LXC     |
| Runtime    | Docker Engine  |
| Management | Docker Compose |
| GUI        | Portainer      |

## Hosted Services

The Docker LXC currently hosts:

- Homepage
- Portainer
- Paperless NGX
- Samba

Additional services may be deployed in the future using Docker Compose.

## Responsibilities

The Docker LXC is responsible for:

- Running Docker containers
- Hosting Docker Compose stacks
- Providing container networking
- Hosting shared application data
- Managing Docker volumes
- Providing SMB file sharing
- Hosting the primary homelab dashboard

## Important Directories

| Path                      | Purpose                     |
| ------------------------- | --------------------------- |
| `/opt/stacks`             | Docker Compose projects     |
| `/storage`                | Persistent application data |
| `/var/lib/docker`         | Docker runtime data         |
| `/var/lib/docker/volumes` | Docker volumes              |

## Docker Compose Stacks

Each application is deployed using its own Compose project.

Example layout:

```text
/opt/stacks
├── homepage/
├── paperless/
├── portainer/
└── samba/
```

Each stack contains:

- `docker-compose.yml`
- Environment files (if required)
- Stack-specific documentation (optional)

## Daily Health Checks

Verify Docker is running:

```bash
systemctl status docker
```

List running containers:

```bash
docker ps
```

Review container status:

```bash
docker ps -a
```

Review Docker resource usage:

```bash
docker stats
```

## Deploying a Stack

Navigate to the stack directory:

```bash
cd /root/stacks/<stack>
```

Start the stack:

```bash
docker compose up -d
```

Verify:

```bash
docker ps
```

## Updating Containers

Navigate to the stack directory:

```bash
cd /root/stacks/<stack>
```

Pull updated images:

```bash
docker compose pull
```

Recreate containers:

```bash
docker compose up -d
```

Remove unused images:

```bash
docker image prune
```

## Container Management

List containers:

```bash
docker ps
```

Stop a container:

```bash
docker stop <container>
```

Start a container:

```bash
docker start <container>
```

Restart a container:

```bash
docker restart <container>
```

Remove a container:

```bash
docker rm <container>
```

## Viewing Logs

Container logs:

```bash
docker logs <container>
```

Follow logs:

```bash
docker logs -f <container>
```

Recent logs:

```bash
docker logs --tail=100 <container>
```

## Docker Compose Management

View running Compose projects:

```bash
docker compose ls
```

View Compose configuration:

```bash
docker compose config
```

Stop a stack:

```bash
docker compose down
```

Restart a stack:

```bash
docker compose restart
```

## Storage Verification

Verify mounted storage:

```bash
df -h
```

Review Docker storage:

```bash
docker system df
```

Review volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume>
```

## Backup Verification

The nightly backup process includes:

- Docker Compose files
- Persistent application data
- Configuration files

Verify backup logs on the Proxmox host:

```text
/srv/backups/logs
```

## Recovery Procedure

### 1. Restore Docker

Install Docker Engine.

Verify:

```bash
docker version
```

### 2. Restore Compose Projects

Restore:

```
/opt/stacks
```

### 3. Restore Persistent Data

Restore application data to:

```text
/storage
```

### 4. Restore Docker Volumes

Restore required Docker volumes.

Verify:

```bash
docker volume ls
```

### 5. Deploy Stacks

For each application:

```bash
docker compose up -d
```

### 6. Verify Services

Verify:

- Homepage
- Portainer
- Paperless
- Samba

Confirm each service is reachable through Caddy.

#### Portainer

Verify container:

```bash
docker ps | grep portainer
```

Access:

```text
https://portainer.example.com
```

Verify:

- Running containers
- Compose stacks
- Docker environment

#### Homepage

Verify container:

```bash
docker ps | grep homepage
```

Access:

```text
https://homepage.example.com
```

Verify:

- Dashboard loads
- Service links function
- Widgets display correctly

#### Paperless

Verify container:

```bash
docker ps | grep paperless
```

Access:

```text
https://paperless.example.com
```

Verify:

- Documents accessible
- OCR functioning
- Metadata intact

#### Samba

Verify container:

```bash
docker ps | grep samba
```

Verify SMB shares are accessible from client machines.

## Troubleshooting

### Docker Service

```bash
systemctl status docker
```

### Containers

```bash
docker ps -a
```

### Compose Configuration

```bash
docker compose config
```

### Images

```bash
docker image ls
```

### Volumes

```bash
docker volume ls
```

### Networks

```bash
docker network ls
```

Inspect a network:

```bash
docker network inspect <network>
```

## Maintenance Checklist

### Weekly

- [ ] Update container images
- [ ] Remove unused images
- [ ] Verify container health
- [ ] Review Docker logs

### Monthly

- [ ] Review Docker storage usage
- [ ] Remove unused volumes (if appropriate)
- [ ] Verify backups
- [ ] Review Compose files for updates

### Quarterly

- [ ] Test restoration of a Compose stack
- [ ] Audit running containers
- [ ] Remove unused stacks
- [ ] Review documentation
