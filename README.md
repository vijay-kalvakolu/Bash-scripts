
# Bash Scripts – Day-to-Day Easy Setups

A grab-bag of practical Bash scripts to bootstrap and maintain developer/DevOps machines.
**Tested on:** Ubuntu, Amazon Linux, CentOS, and RHEL family distros.

> These scripts aim to be idempotent (safe to re-run) and loud about failures. They prefer official upstream sources and minimal assumptions.



---

## Requirements

* `bash` 4.x+
* `curl` and `sudo` available
* Internet access to vendor repositories/CDNs
* For RHEL/CentOS/Amazon Linux: your user must have `sudo` rights

---

## Quick start

Clone and list scripts:

```bash
git clone https://github.com/vijay-kalvakolu/Bash-scripts.git
cd <repo>
ls -1
```

Make a script executable (example):

```bash
chmod +x install_docker.sh
```

Run it:

```bash
./install_docker.sh
```

Run with explicit interpreter (handy for CRON or PATH quirks):

```bash
bash ./install_docker.sh
```

Use a full path (recommended for automations):

```bash
/full/path/to/repo/install_docker.sh
```

---

## Verifying installs

```bash
docker --version
kubectl version --client --short
minikube version
```

If Docker group changes just happened:

```bash
newgrp docker   # or log out & back in
docker run --rm hello-world
```

---

## Scheduling with `crontab`

Cron is simple but picky. Use **absolute paths**, set a **PATH**, and capture **logs**.

Open your crontab:

```bash
crontab -e
```

Add a PATH at the top (common for Ubuntu/Amazon/RHEL/CentOS):

```cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

### Examples

**1) Run a script daily at 03:00**

```cron
# Daily Docker health script
0 3 * * * /bin/bash /full/path/to/repo/install_docker.sh >> /var/log/install_docker.log 2>&1
```

**2) Run every Sunday at 02:15**

```cron
15 2 * * 0 /bin/bash /full/path/to/repo/install_kubectl.sh >> /var/log/install_kubectl.log 2>&1
```

**3) Run every 15 minutes**

```cron
*/15 * * * * /bin/bash /full/path/to/repo/install_minikube.sh >> /var/log/install_minikube.log 2>&1
```

**4) Run as a specific user (system-wide crontab)**

Edit `/etc/crontab` (requires sudo). Note the extra **user** field:

```cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 4 * * * root /bin/bash /full/path/to/repo/install_docker.sh >> /var/log/install_docker.log 2>&1
```

List cron jobs:

```bash
crontab -l
```

---

## Distro specifics (notes)

* **Ubuntu/Debian**: Uses `apt`. Official Docker and Kubernetes repos are configured by scripts where needed.
* **Amazon Linux**: Uses `yum`/`dnf` under the hood. Ensure `sudo` is present (`sudo yum install -y sudo` if missing).
* **RHEL/CentOS**: May require enabling extras or EPEL for some utilities. Make sure your subscription/repos are enabled.

---

## Troubleshooting

* **Permission denied**: `chmod +x script.sh` and/or run with `bash script.sh`.
* **Command not found in cron**: set `PATH` in crontab and use **absolute paths**.
* **Weird line endings**: if you edited on Windows, fix with `dos2unix script.sh`.
* **Shell linting**: run `shellcheck script.sh` for friendly pointers (`sudo apt-get install shellcheck` or `dnf install ShellCheck`).
* **Which Bash?**: cron sometimes uses `/bin/sh`. Always shebang with `#!/usr/bin/env bash` and invoke via `/bin/bash`.

---

## Contributing

* Keep scripts POSIX-ish where practical but prefer **Bash** features that improve safety/readability.
* Use `set -euo pipefail` and fail loudly.
* Validate inputs; print helpful usage with `-h|--help`.
* Lint before committing:

```bash
shellcheck **/*.sh
```

Format (optional, but nice):

```bash
shfmt -w -i 4 -ci **/*.sh
```

---

## Disclaimer

Scripts are provided **as-is**. Review before running, especially on production hosts. When in doubt, read the source—shell is wonderfully transparent.

---
