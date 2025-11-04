# ==============================================================================
# install_setup.sh
#
# Bash script that installs kubectl, Docker, Terraform
# Works on Amazon Linux, Debian/Ubuntu, RHEL/CentOS/Rocky/Alma, Fedora, openSUSE, Arch
#
# Author: Vijay Kalvakolu
# ==============================================================================

#!/usr/bin/env bash
set -euo pipefail

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (use sudo)." >&2
    exit 1
  fi
}

log() { printf "\n==> %s\n" "$*"; }
warn() { printf "\n[WARN] %s\n" "$*" >&2; }
die() { printf "\n[ERROR] %s\n" "$*" >&2; exit 1; }

# Detect package manager & distro info
detect_env() {
  PM=""
  if command -v apt-get >/dev/null 2>&1; then PM="apt";
  elif command -v dnf >/dev/null 2>&1; then PM="dnf";
  elif command -v yum >/dev/null 2>&1; then PM="yum";
  elif command -v zypper >/dev/null 2>&1; then PM="zypper";
  elif command -v pacman >/dev/null 2>&1; then PM="pacman";
  else
    die "Unsupported distro (no apt/dnf/yum/zypper/pacman found)."
  fi

  # /etc/os-release for extra signals
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DIST_ID="${ID:-unknown}"
    DIST_LIKE="${ID_LIKE:-}"
  else
    DIST_ID="unknown"; DIST_LIKE=""
  fi

  # Arch mapping for binaries
  KERNEL_ARCH="$(uname -m)"
  case "$KERNEL_ARCH" in
    x86_64) BIN_ARCH="amd64" ;;
    aarch64|arm64) BIN_ARCH="arm64" ;;
    armv7l) BIN_ARCH="arm" ;; # not all vendors ship armv7 bins; may fall back
    *) BIN_ARCH="amd64"; warn "Unknown arch '$KERNEL_ARCH', defaulting to amd64."; ;;
  esac
}

# Package installs for prerequisites
install_prereqs() {
  log "Installing prerequisites"
  case "$PM" in
    apt)
      apt-get update -y
      DEBIAN_FRONTEND=noninteractive apt-get install -y \
        ca-certificates curl gnupg lsb-release unzip tar
      ;;
    dnf)
      dnf install -y ca-certificates curl gnupg2 unzip tar
      ;;
    yum)
      yum install -y ca-certificates curl gnupg2 unzip tar
      ;;
    zypper)
      zypper --non-interactive refresh
      zypper --non-interactive install ca-certificates curl gpg2 unzip tar
      ;;
    pacman)
      pacman -Sy --noconfirm ca-certificates curl gnupg unzip tar
      ;;
  esac
}

# Docker via official convenience script (covers most distros cleanly)
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed: $(docker --version)"
    return
  fi

  log "Installing Docker (using get.docker.com)"
  # Some minimal deps for script on older images
  case "$PM" in
    apt) apt-get update -y && apt-get install -y curl ca-certificates ;;
    dnf) dnf install -y curl ca-certificates ;;
    yum) yum install -y curl ca-certificates ;;
    zypper) zypper --non-interactive install curl ca-certificates ;;
    pacman) pacman -Sy --noconfirm curl ca-certificates ;;
  esac

  curl -fsSL https://get.docker.com | sh

  # Enable & start
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now docker || true
  else
    service docker start || true
  fi

  # Add invoking user to docker group (so no sudo needed after re-login)
  TARGET_USER="${SUDO_USER:-$USER}"
  if getent group docker >/dev/null 2>&1; then
    usermod -aG docker "$TARGET_USER" || true
    log "Added user '$TARGET_USER' to 'docker' group. Re-login required to take effect."
  fi

  log "Docker installed: $(docker --version || echo 'version check will work after re-login')"
}

# kubectl latest stable
install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already installed: $(kubectl version --client --short || true)"
    return
  fi

  log "Installing kubectl (latest stable)"
  K8S_VER="$(curl -Ls https://dl.k8s.io/release/stable.txt)"
  if [[ -z "${K8S_VER:-}" ]]; then
    die "Could not determine latest kubectl version."
  fi

  TMP="/tmp/kubectl-${K8S_VER}"
  curl -fsSLo "${TMP}" "https://dl.k8s.io/release/${K8S_VER}/bin/linux/${BIN_ARCH}/kubectl"
  chmod +x "${TMP}"
  mv "${TMP}" /usr/local/bin/kubectl

  # Optional checksum verify
  if command -v sha256sum >/dev/null 2>&1; then
    SUM_EXPECTED="$(curl -fsSL "https://dl.k8s.io/${K8S_VER}/bin/linux/${BIN_ARCH}/kubectl.sha256")"
    SUM_ACTUAL="$(sha256sum /usr/local/bin/kubectl | awk '{print $1}')"
    if [[ "$SUM_EXPECTED" != "$SUM_ACTUAL" ]]; then
      warn "kubectl checksum mismatch (continuing)."
    fi
  fi

  log "kubectl installed: $(kubectl version --client --short)"
}

# Terraform latest using HashiCorp checkpoint API
install_terraform() {
  if command -v terraform >/dev/null 2>&1; then
    log "Terraform already installed: $(terraform version | head -n1)"
    return
  fi

  log "Installing Terraform (latest)"
  TF_JSON="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform || true)"
  TF_VER="$(printf "%s" "$TF_JSON" | sed -nE 's/.*"current_version":"([^"]+)".*/\1/p')"
  if [[ -z "${TF_VER:-}" ]]; then
    warn "Could not fetch latest Terraform version from API; falling back to a known version."
    TF_VER="1.9.8"
  fi

  TMP_ZIP="/tmp/terraform_${TF_VER}_linux_${BIN_ARCH}.zip"
  URL="https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${BIN_ARCH}.zip"

  curl -fsSLo "$TMP_ZIP" "$URL" || die "Failed to download Terraform $TF_VER"
  unzip -o "$TMP_ZIP" -d /usr/local/bin >/dev/null
  chmod +x /usr/local/bin/terraform
  rm -f "$TMP_ZIP"

  log "Terraform installed: $(terraform version | head -n1)"
}

# Friendly summary
summary() {
  echo
  echo "---------------------------------------------"
  echo " Installed binaries:"
  command -v docker >/dev/null 2>&1 && docker --version || echo "Docker: installed (version will show after re-login if group changed)"
  command -v kubectl >/dev/null 2>&1 && kubectl version --client --short || true
  command -v terraform >/dev/null 2>&1 && terraform version | head -n1 || true
  echo "---------------------------------------------"
  echo "Tip: Log out/in (or run 'newgrp docker') so your user can run 'docker' without sudo."
}

main() {
  require_root
  detect_env
  install_prereqs
  install_docker
  install_kubectl
  install_terraform
  summary
}

main "$@"
