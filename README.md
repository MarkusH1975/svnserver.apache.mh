# Docker Subversion Server with Apache http

This Docker Subversion Server offers access via http protocoll. Secure https protocoll can be used togehter with a reverse proxy on your system.

This Docker container is intended to run on **Synology DSM 7.0**, as a replacement for the SVN server package (dropped by Synology). However, it can be used on other servers as well. (maybe with small adaptions.)

---

- [Docker Subversion Server with Apache http](#docker-subversion-server-with-apache-http)
  - [Disclaimer](#disclaimer)
  - [SVN Access Methods](#svn-access-methods)
  - [Quick start for Synology DSM 7.0 users](#quick-start-for-synology-dsm-70-users)
    - [Preconditions](#preconditions)
    - [Build and Run the container](#build-and-run-the-container)
    - [Setup reverse proxy (optional)](#setup-reverse-proxy-optional)
    - [Setup iF.SVNAdmin](#setup-ifsvnadmin)
    - [Copy existing SVN repos](#copy-existing-svn-repos)
    - [Configure iF.SVNAdmin](#configure-ifsvnadmin)
    - [Password recovery iF.SVNAdmin](#password-recovery-ifsvnadmin)
    - [Browse SVN repos](#browse-svn-repos)
    - [SVN checkout](#svn-checkout)
    - [Relocation of your working copy](#relocation-of-your-working-copy)
  - [Docker connections](#docker-connections)
    - [Volumes](#volumes)
    - [Ports](#ports)
    - [URL Endpoints](#url-endpoints)
    - [Environment Variables](#environment-variables)
  - [Image Components](#image-components)
    - [Ubuntu 20.04](#ubuntu-2004)
    - [Tini-Init process](#tini-init-process)
    - [Apache2 + dav_svn](#apache2--dav_svn)
    - [iF.SVNAdmin](#ifsvnadmin)
    - [Cron](#cron)
    - [Entrypoint-Script](#entrypoint-script)
  - [Docker build (force cache invalidation)](#docker-build-force-cache-invalidation)
  - [Links](#links)

---

## Disclaimer

This docker image uses the tool [iF.SVNAdmin](https://github.com/mfreiholz/iF.SVNAdmin
), it is quite old and no more developed. In long-term consider a switch to a git service, e.g. [Gitea](https://gitea.io).

---

## SVN Access Methods

Generally a svn repository can be accessed via different protocolls:

- **http:// or https:// webdav access via apache**
- svn:// protocoll
- svn+ssh:// access method

Since **each protocoll uses different authentication methods** it is hard to combine different access protocols/methods.

See: <https://svnbook.red-bean.com/en/1.7/svn.serverconfig.choosing.html>

---

## Quick start for Synology DSM 7.0 users

Quick start instructions for users not interested in details.

### Preconditions

Following is assumed:

- You run Synology DSM 7.0 on your NAS (can be tested with 6.2 before update)
- Docker package is installed
- SVN repos are stored in `/volume1/svn/`
- Optional: Git server package is installed (for cloning from github)


### Build and Run the container

To run the svn server, first ssh into your NAS and execute:

```bash
cd /volume1/svn/
git clone https://github.com/MarkusH1975/svnserver.apache.mh.git
cd svnserver.apache.mh/
sudo ./start.sh
```

Voilà, config files are installed automatically on empty volumes. If you want to start from scratch, simply delete everything below `./volume/svnadmin/` and `./volume/svnconf/` and restart the container. (All users, passwords and access rights will be gone.)

### Setup reverse proxy (optional)

Setup Synology reverse proxy to have a ssl connection. Looks like:

- Name: svnserver.apache
- Source: `https://*:8088`
- Destination: `http://localhost:18088`

Now you can reach the apache server from your network with a secure connection on `https://serverip:8088/`.

### Setup iF.SVNAdmin

Go to `http://serverip:8087/svnadmin` or `https://serverip:8088/svnadmin` (reverse proxy with ssl). Click all "Test" buttons and save the config. Login with default user: admin, pass: admin. Change the default password.

### Copy existing SVN repos

**Create a Backup!** Copy your existing SVN-Repositories into the folder `./volume/svnrepo/`.

```bash
sudo cp -Rv /volume1/svn/myRepo1 /volume1/svn/svnserver.apache.mh/volume/svnrepo/
sudo chmod 777 -Rv /volume1/svn/svnserver.apache.mh/volume/svnrepo/
```

### Configure iF.SVNAdmin

Check the Repositories-List, all your repos should be listed here. For each repository, you need to create an Access-Path by clicking on the star in the Repositories-List.

Create your users and define access rights.

### Password recovery iF.SVNAdmin

If you forgot your admin password, change it in the file `./volume/svnconf/dav_svn.passwd` to the value
`admin:$apr1$dWDAnUYo$JTHdVyh.ad3U9TNhs15eE0`, which sets `admin` as password for the user `admin`.

### Browse SVN repos

 Check if you can browse your SVN repos on `https://serverip:8088/svn/`.

### SVN checkout

Now you can checkout your repository with 

```bash
svn co https://serverip:8088/svn/myRepo1/
```

### Relocation of your working copy

If you don't want to checkout your repository again after the move to Docker, you can relocate your working copy.

- First check actual server location with `svn info`
- Relocate with `svn relocate https://serverip:8088/svn/myRepo1`
- Check again with `svn info`

---

## Docker configurations

### Volumes

| Mountpoint | Container Folder | Description |
| - | - | - |
| `./volume/svnadmin/` | `/volume/svnadmin/` | Data folder of IF.SVNAdmin for config files. |
| `./volume/svnconf/` | `/volume/svnconf/` | Apache config files for subversion and access rights |
| `./volume/svnrepo/` | `/volume/svnrepo/` | Folder for SVN repositories. |

The content of the volume folders are automatically initialized by the entrypoint-script, if the folders are empty.

### Ports

| Host Port | Container Port | Description |
| - | - | - |
`0.0.0.0:8087 TCP` | `80 TCP` | Apache http, accessable from all hosts.
`127.0.0.1:18088 TCP` | `80 TCP` | Accessible only from localhost + use Synology reverse proxy to get secure access via https.

### URL Endpoints

| App URL     | Description |
| ----------- | ----------- |
| `http://serverip:8087/svnadmin` <br/> `https://serverip:8088/svnadmin` |  iF.SVNAdmin  |
| `http://serverip:8087/svn` <br/> `https://serverip:8088/svn` | List all repos (depending on user rights) |
| `http://serverip:8087/svn/myRepo` <br/> `https://serverip:8088/svn/myRepo` | Browse single repo |

### Environment Variables

Environment variables to control `entrypoint.sh` script. Already set by default.

| Env var | Description |
| ------- | ----------- |
| `ENABLE_APACHE=true`  |  Start Apache2  |
| `ENABLE_CRON=false`   |  Start cron, not used. Set to true if you want to set up cron jobs, e.g. for creation of regular backups. |

---

## Image Components

### Ubuntu 20.04

Was chosen as the latest Ubuntu LTS version, which offers PHP7.4. With Ubuntu 21.10 onwards, PHP8.0 is included, and iF.SVNAdmin seems not to run with it out of the box.

### Tini-Init process

Tini is added to have a valid init process, running as PID1. Read more information on the project page. <https://github.com/krallin/tini>.
Tini init process together with the provided entrypoint-script, is able to **run multiple services**, including graceful shutdown. It can be used as a template for other docker projects. If you attach to the container, the entrypoint-script offers a micro CLI. Type `help` for help.

### Apache2 + dav_svn

Apache2 to offer SVN access via webdav to your SVN repos and precondition for iF.SVNAdmin.

### iF.SVNAdmin

iF.SVNAdmin is a Web based SVN management tool. It is already an old project written for PHP5.3. Development is inactive since years, however it is running fine with PHP7.4. It is not working anymore with PHP8. See: <https://github.com/mfreiholz/iF.SVNAdmin>

### Cron

Optionally cron can be started. It is currently not used in this container and therefore by default disabled.

### Entrypoint-Script

The `entrypoint.sh` is the central bash script, which is started from tini. It can start multiple services and offers graceful shutdown of the started services. (Tini jumps in for unhandled processes.)
Furthermore the script will **initialize** the defined **volume folders**, if they are empty. In this way you do not need to think how to copy default files from the container to the volume.

Since this script is the main docker process, it cannot end and needs to run in an endless loop. To make something useful, it offers a **micro command line interface**, which can be accessed via **docker attach**. Please attach to it and type `help` for more information.

---

## Docker build (force cache invalidation)

Sometimes docker build has problems to recognize that the build cache should be invalidated at some certain point. For example, if the `entrypoint.sh` script has changed, docker build is probably still using the cache and does not add the new version of the file. To force cache invalidation at a certain point the argument `CACHE_DATE` is used. Have a look at the Dockerfile and `start.sh`, how it is used.

---

## Links

This project was inspired by different Github projects and other sources, see some links below.

<https://github.com/krallin/tini><br>
<https://github.com/phusion/baseimage-docker><br>
<https://github.com/elleFlorio/svn-docker><br>
<https://github.com/smezger/svn-server-ubuntu><br>
<https://github.com/jocor87/docker-svn-ifsvnadmin><br>
<https://github.com/MarvAmBass/docker-subversion><br>
<https://github.com/ZevenFang/docker-svn-ifsvnadmin><br>
<https://github.com/garethflowers/docker-svn-server><br>

<https://github.com/mfreiholz/iF.SVNAdmin><br>

<https://kb.synology.com/en-sg/DSM/tutorial/How_to_launch_an_SVN_server_based_on_Docker_on_your_Synology_NAS><br>
<https://goinbigdata.com/docker-run-vs-cmd-vs-entrypoint/><br>
<https://docs.docker.com/config/containers/multi-service_container/><br>
<https://github.com/docker-library/official-images#init><br>
<https://www.cyberciti.biz/faq/howto-regenerate-openssh-host-keys/><br>
<https://svnbook.red-bean.com/en/1.7/svn.serverconfig.choosing.html><br>

<https://serverfault.com/questions/156470/testing-for-a-script-that-is-waiting-on-stdin><br>
<https://stackoverflow.com/a/42599638><br>
<https://stackoverflow.com/a/39150040><br>
<https://stackoverflow.com/q/70637123><br>

<https://serverfault.com/questions/23644/how-to-use-linux-username-and-password-with-subversion><br>

<https://stackoverflow.com/a/69081169><br>
