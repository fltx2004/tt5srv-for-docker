# TeamTalk 5 Server Docker

中文

[English](README_EN.md)

适用于 **Linux AMD64（x86_64）** 的 TeamTalk 5 Server Docker 镜像，支持配置、日志及上传文件持久化。

## 镜像地址

镜像同时发布到 Docker Hub 和 GitHub Container Registry（GHCR），可按网络情况选择使用：

| 镜像仓库 | 镜像地址 |
| --- | --- |
| [Docker Hub](https://hub.docker.com/r/fltx2004/tt5srv) | `fltx2004/tt5srv` |
| [GitHub Container Registry](https://github.com/fltx2004/tt5srv-for-docker/pkgs/container/tt5srv) | `ghcr.io/fltx2004/tt5srv` |

两个镜像源均提供：

- `latest`：最新发布版本。
- 版本标签，例如 `5.22`：对应的 TeamTalk 版本。

本文示例默认使用 Docker Hub。若要使用 GHCR，将命令或 Compose 配置中的：

```text
fltx2004/tt5srv
```

替换为：

```text
ghcr.io/fltx2004/tt5srv
```

例如：

```sh
docker pull ghcr.io/fltx2004/tt5srv:latest
```

## 支持平台

- 镜像平台：`linux/amd64`
- 镜像基础环境：Ubuntu 24.04

镜像内部提供 TeamTalk 所需的 glibc，可在安装了 Docker、且满足容器运行要求的 Linux x86_64 系统上使用，例如 Ubuntu、Debian、Fedora、Rocky Linux、Arch Linux 和 OpenWrt x86_64。

> 不支持 ARM / ARM64。OpenWrt 还需具备 Docker 所需的内核功能和足够的存储空间。

## 数据持久化

容器内的数据目录为：

```text
/data
```

本文将其映射到宿主机的 `/opt/tt5srv/data`：

| 内容 | 宿主机路径 | 容器内路径 |
| --- | --- | --- |
| 配置文件 | `/opt/tt5srv/data/tt5srv.xml` | `/data/tt5srv.xml` |
| 日志文件 | `/opt/tt5srv/data/tt5srv.log` | `/data/tt5srv.log` |
| 上传文件目录 | `/opt/tt5srv/data/files` | `/data/files` |

宿主机路径可以自行修改。使用本文命令时，容器内路径请保持为 `/data`。

在 OpenWrt 上，建议将宿主机数据目录放在持久化存储中，避免使用临时目录或容量有限的存储。

创建数据目录和上传文件目录：

```sh
mkdir -p /opt/tt5srv/data/files
```

## 首次配置

首次启动服务前，运行 TeamTalk 配置向导：

```sh
docker run --rm -it \
  --network host \
  -v /opt/tt5srv/data:/data \
  fltx2004/tt5srv:latest \
  -wizard -wd /data
```

按向导提示设置服务器名称、监听端口、用户账号等信息。

如果需要文件上传功能，在向导询问文件存储目录时填写：

```text
/data/files
```

注意填写的是**容器内路径**，而不是宿主机路径。

向导生成的配置文件会保存在：

```text
/opt/tt5srv/data/tt5srv.xml
```

> 配置文件可能包含账号等敏感信息，请妥善保管，不要提交到公开仓库。

## 使用 Docker Run 启动

完成配置后，启动服务器：

```sh
docker run -d \
  --name tt5srv \
  --restart unless-stopped \
  --network host \
  -v /opt/tt5srv/data:/data \
  fltx2004/tt5srv:latest \
  -nd -wd /data -l /data/tt5srv.log -verbose
```

TeamTalk 进程在容器内以前台模式运行，Docker 容器在后台运行。服务读取 `/data/tt5srv.xml`，日志写入 `/data/tt5srv.log`。

### 使用端口映射

上述示例使用宿主机网络。如果希望使用 Docker 桥接网络，将：

```sh
--network host
```

替换为：

```sh
-p 10333:10333/tcp \
-p 10333:10333/udp
```

如果配置向导中修改了监听端口，请同步修改端口映射。TCP 和 UDP 端口若不同，应分别映射。

> 无论使用哪种网络模式，都需要在宿主机防火墙中放行实际使用的 TCP 和 UDP 端口。需要从公网访问时，还应检查路由器端口转发和云服务器安全组。

## 使用 Docker Compose 启动

创建 `/opt/tt5srv/compose.yaml`：

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

如果尚未运行配置向导，先创建数据目录，然后运行：

```sh
mkdir -p /opt/tt5srv/data/files

docker compose -f /opt/tt5srv/compose.yaml run --rm \
  tt5srv -wizard -wd /data
```

启动服务器：

```sh
docker compose -f /opt/tt5srv/compose.yaml up -d
```

### 从 Docker Run 切换到 Compose

如果已经通过 `docker run` 创建了同名容器，先删除旧容器，再启动 Compose 服务：

```sh
docker rm -f tt5srv

docker compose -f /opt/tt5srv/compose.yaml up -d
```

删除容器不会删除绑定在宿主机数据目录中的配置、日志和上传文件。

### Compose 使用端口映射

如需使用桥接网络，删除：

```yaml
network_mode: host
```

并添加：

```yaml
ports:
  - "10333:10333/tcp"
  - "10333:10333/udp"
```

端口应与 TeamTalk 配置保持一致。

> 旧版 Compose 使用 `docker-compose` 命令。本文其他示例以新版 `docker compose` 为准。

## 日常管理

### 查看容器状态

```sh
docker ps -a --filter name=tt5srv
```

### 查看日志

查看容器标准输出和标准错误：

```sh
docker logs -f tt5srv
```

本文启动参数指定了日志文件。若需要查看 TeamTalk 文件日志，运行：

```sh
tail -f /opt/tt5srv/data/tt5srv.log
```

### 重启、停止和启动

```sh
docker restart tt5srv
docker stop tt5srv
docker start tt5srv
```

### 查看 TeamTalk 完整版本

```sh
docker run --rm fltx2004/tt5srv:latest --version
```

## 升级

升级前建议备份数据目录。为获得一致的备份，建议先停止服务，备份完成后再升级或启动。

```sh
docker stop tt5srv

tar -C /opt/tt5srv -czf \
  /opt/tt5srv-backup-$(date +%Y%m%d-%H%M%S).tar.gz data
```

> 拉取新镜像不会自动更新已经创建的容器。升级需要使用新镜像重新创建容器。

### 使用 Docker Compose 升级

```sh
docker compose -f /opt/tt5srv/compose.yaml pull

docker compose -f /opt/tt5srv/compose.yaml up -d
```

旧版 Compose：

```sh
docker-compose -f /opt/tt5srv/compose.yaml pull

docker-compose -f /opt/tt5srv/compose.yaml up -d
```

### 使用 Docker Run 升级

先拉取新镜像：

```sh
docker pull fltx2004/tt5srv:latest
```

删除旧容器，并使用相同的数据目录重新创建：

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

如果修改过网络模式、端口或其他启动参数，重新创建时请保留相应设置。

## 指定版本与回滚

生产环境建议使用具体版本标签，而不是 `latest`：

```text
fltx2004/tt5srv:5.22
```

使用 GHCR 时：

```text
ghcr.io/fltx2004/tt5srv:5.22
```

Compose 中相应修改为：

```yaml
image: fltx2004/tt5srv:5.22
```

然后拉取镜像并重新创建容器：

```sh
docker compose -f /opt/tt5srv/compose.yaml pull

docker compose -f /opt/tt5srv/compose.yaml up -d
```

如果新版本出现问题，可以将镜像标签改回之前的版本，再执行上述命令。

注意：

- 旧版本镜像不一定兼容新版本修改后的配置或数据，必要时应恢复升级前的备份。
- 版本标签可能因同版本重新发布而更新。若需锁定完全相同的镜像内容，请使用镜像摘要（`@sha256:...`）。

## SELinux 系统

Fedora、Rocky Linux、RHEL 等启用 SELinux 的系统，如果遇到绑定目录访问权限问题，可以给目录挂载添加 `:Z`。

Compose：

```yaml
volumes:
  - /opt/tt5srv/data:/data:Z
```

Docker Run：

```sh
-v /opt/tt5srv/data:/data:Z
```

`:Z` 会为目录设置供该容器使用的 SELinux 标签。如果该目录需要由多个容器共享，应根据实际情况使用 `:z`。

同时请确认宿主机目录的常规文件权限允许容器访问，不建议通过关闭 SELinux 或设置 `chmod 777` 解决权限问题。
