# TeamTalk 5 Server Docker

English

[中文](README.md)

A TeamTalk 5 Server Docker image for **Linux AMD64 (x86_64)**, with persistent storage for configuration, logs, and uploaded files.

## Container Images

Images are published to both Docker Hub and GitHub Container Registry (GHCR). Choose whichever registry works best for your network:

| Registry | Image |
| --- | --- |
| [Docker Hub](https://hub.docker.com/r/fltx2004/tt5srv) | `fltx2004/tt5srv` |
| [GitHub Container Registry](https://github.com/fltx2004/tt5srv-for-docker/pkgs/container/tt5srv) | `ghcr.io/fltx2004/tt5srv` |

Both registries provide:

- `latest`: the latest published release.
- Version tags, such as `5.22`: the corresponding TeamTalk release.

The examples below use Docker Hub. To use GHCR, replace:

```text
fltx2004/tt5srv
```

with:

```text
ghcr.io/fltx2004/tt5srv
```

For example:

```sh
docker pull ghcr.io/fltx2004/tt5srv:latest
```

## Supported Platform

- Container platform: `linux/amd64`
- Base environment: Ubuntu 24.04

The image provides the glibc environment required by TeamTalk. It can run on Linux x86_64 systems with Docker and the necessary container support, including Ubuntu, Debian, Fedora, Rocky Linux, Arch Linux, and OpenWrt x86_64.

> ARM and ARM64 are not supported. OpenWrt also requires the kernel features needed by Docker and sufficient storage space.

## Persistent Storage

The container data directory is:

```text
/data
```

The examples in this guide map it to `/opt/tt5srv/data` on the host:

| Content | Host path | Container path |
| --- | --- | --- |
| Configuration file | `/opt/tt5srv/data/tt5srv.xml` | `/data/tt5srv.xml` |
| Log file | `/opt/tt5srv/data/tt5srv.log` | `/data/tt5srv.log` |
| Uploaded files | `/opt/tt5srv/data/files` | `/data/files` |

You can change the host path. When using the commands in this guide, keep the container path as `/data`.

On OpenWrt, place the host data directory on persistent storage. Avoid temporary directories or storage with limited capacity.

Create the data and upload directories:

```sh
mkdir -p /opt/tt5srv/data/files
```

## Initial Configuration

Before starting the server for the first time, run the TeamTalk configuration wizard:

```sh
docker run --rm -it \
  --network host \
  -v /opt/tt5srv/data:/data \
  fltx2004/tt5srv:latest \
  -wizard -wd /data
```

Follow the prompts to configure the server name, listening ports, user accounts, and other settings.

If you want to enable file uploads, enter the following when asked for the file storage directory:

```text
/data/files
```

Use the **container path**, not the host path.

The generated configuration file will be saved on the host at:

```text
/opt/tt5srv/data/tt5srv.xml
```

> The configuration file may contain sensitive account information. Keep it secure and do not commit it to a public repository.

## Start with Docker Run

After completing the configuration, start the server:

```sh
docker run -d \
  --name tt5srv \
  --restart unless-stopped \
  --network host \
  -v /opt/tt5srv/data:/data \
  fltx2004/tt5srv:latest \
  -nd -wd /data -l /data/tt5srv.log -verbose
```

The TeamTalk process runs in the foreground inside the container, while Docker runs the container in the background. The server reads `/data/tt5srv.xml` and writes logs to `/data/tt5srv.log`.

### Use Port Mapping

The example above uses host networking. To use Docker bridge networking instead, replace:

```sh
--network host
```

with:

```sh
-p 10333:10333/tcp \
-p 10333:10333/udp
```

If you changed the listening ports in the configuration wizard, update the port mappings accordingly. If the TCP and UDP ports differ, map them separately.

> With either networking mode, allow the configured TCP and UDP ports through the host firewall. For public access, also check router port forwarding and any cloud firewall or security group rules.

## Start with Docker Compose

Create `/opt/tt5srv/compose.yaml`:

```yaml
services:
  tt5srv:
    image: fltx2004/tt5srv:latest
    container_name: tt5srv
    network_mode: host
    restart: unless-stopped
    volumes:
      - /opt/tt5srv/data:/data
    command:
      - -nd
      - -wd
      - /data
      - -l
      - /data/tt5srv.log
      - -verbose
```

If you have not run the configuration wizard yet, create the data directories and run:

```sh
mkdir -p /opt/tt5srv/data/files

docker compose -f /opt/tt5srv/compose.yaml run --rm \
  tt5srv -wizard -wd /data
```

Start the server:

```sh
docker compose -f /opt/tt5srv/compose.yaml up -d
```

### Switch from Docker Run to Compose

If you previously created a container with the same name using `docker run`, remove it before starting the Compose service:

```sh
docker rm -f tt5srv

docker compose -f /opt/tt5srv/compose.yaml up -d
```

Removing the container does not delete the configuration, logs, or uploaded files stored in the bind-mounted host directory.

### Use Port Mapping with Compose

To use bridge networking, remove:

```yaml
network_mode: host
```

and add:

```yaml
ports:
  - "10333:10333/tcp"
  - "10333:10333/udp"
```

The mapped ports must match your TeamTalk configuration.

> Older Compose installations use the `docker-compose` command. The examples in this guide use the newer `docker compose` command.

## Daily Management

### Check Container Status

```sh
docker ps -a --filter name=tt5srv
```

### View Logs

View the container's standard output and standard error:

```sh
docker logs -f tt5srv
```

The startup commands in this guide also specify a log file. To follow the TeamTalk file log, run:

```sh
tail -f /opt/tt5srv/data/tt5srv.log
```

### Restart, Stop, or Start

```sh
docker restart tt5srv
docker stop tt5srv
docker start tt5srv
```

### Check the Full TeamTalk Version

```sh
docker run --rm fltx2004/tt5srv:latest --version
```

## Upgrade

Back up the data directory before upgrading. For a consistent backup, stop the server first, then upgrade or restart it after the backup is complete.

```sh
docker stop tt5srv

tar -C /opt/tt5srv -czf \
  /opt/tt5srv-backup-$(date +%Y%m%d-%H%M%S).tar.gz data
```

> Pulling a new image does not update an existing container automatically. You must recreate the container using the new image.

### Upgrade with Docker Compose

```sh
docker compose -f /opt/tt5srv/compose.yaml pull

docker compose -f /opt/tt5srv/compose.yaml up -d
```

For older Compose installations:

```sh
docker-compose -f /opt/tt5srv/compose.yaml pull

docker-compose -f /opt/tt5srv/compose.yaml up -d
```

### Upgrade with Docker Run

Pull the new image:

```sh
docker pull fltx2004/tt5srv:latest
```

Remove the old container and recreate it with the same data directory:

```sh
docker rm -f tt5srv

docker run -d \
  --name tt5srv \
  --restart unless-stopped \
  --network host \
  -v /opt/tt5srv/data:/data \
  fltx2004/tt5srv:latest \
  -nd -wd /data -l /data/tt5srv.log -verbose
```

If you customized the networking mode, ports, or other startup options, preserve those settings when recreating the container.

## Version Pinning and Rollback

For production deployments, use a specific version tag instead of `latest`:

```text
fltx2004/tt5srv:5.22
```

For GHCR:

```text
ghcr.io/fltx2004/tt5srv:5.22
```

Update the image in your Compose configuration accordingly:

```yaml
image: fltx2004/tt5srv:5.22
```

Then pull the image and recreate the container:

```sh
docker compose -f /opt/tt5srv/compose.yaml pull

docker compose -f /opt/tt5srv/compose.yaml up -d
```

If a new release causes problems, change the image tag back to the previous version and run the same commands.

Keep in mind:

- An older image may not be compatible with configuration or data modified by a newer release. Restore your pre-upgrade backup if necessary.
- A version tag may be updated when the same version is republished. To pin the exact image content, use an image digest (`@sha256:...`).

## SELinux Systems

On systems with SELinux enabled, such as Fedora, Rocky Linux, and RHEL, you may need to add `:Z` to the bind mount if the container cannot access the data directory.

For Compose:

```yaml
volumes:
  - /opt/tt5srv/data:/data:Z
```

For Docker Run:

```sh
-v /opt/tt5srv/data:/data:Z
```

The `:Z` option applies an SELinux label for private use by the container. If multiple containers need to share the directory, consider using `:z` instead, as appropriate.

Also ensure that standard host filesystem permissions allow the container to access the directory. Avoid disabling SELinux or using `chmod 777` as a workaround.