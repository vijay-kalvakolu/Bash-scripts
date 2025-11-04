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

# Silent install script for Docker, kubectl, and Terraform
# Works on Amazon Linux, Ubuntu/Debian, CentOS/RHEL/Rocky, Fedora

detect_pm() {
  if command -v apt-get &>/dev/null; then echo apt
  elif command -v dnf &>/dev/null; then echo dnf
  elif command -v yum &>/dev/null; then echo yum
  elif command -v zypper &>/dev/null; then echo zypper
  else echo "unsupported"
  fi
}

PM=$(detect_pm)
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
[[ "$ARCH" == "aarch64" ]] && ARCH="arm64"

install_prereqs() {
  case "$PM" in
    apt) apt-get update -qq && apt-get install -y -qq curl unzip ca-certificates gnupg lsb-release >/dev/null ;;
    dnf) dnf install -y -q curl unzip ca-certificates gnupg2 >/dev/null ;;
    yum) yum install -y -q curl unzip ca-certificates gnupg2 >/dev/null ;;
    zypper) zypper --non-interactive install -y curl unzip ca-certificates gpg2 >/dev/null ;;
  esac
}

install_docker() {
  if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
    systemctl enable --now docker >/dev/null 2>&1 || service docker start >/dev/null 2>&1
    usermod -aG docker "${SUDO_USER:-$USER}" || true
  fi
}

install_kubectl() {
  if ! command -v kubectl &>/dev/null; then
    VER=$(curl -sL https://dl.k8s.io/release/stable.txt)
    curl -sLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${VER}/bin/linux/${ARCH}/kubectl"
    chmod +x /usr/local/bin/kubectl
  fi
}

install_terraform() {
  if ! command -v terraform &>/dev/null; then
    VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | grep -oP '"current_version":"\K[^"]+')
    curl -sLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${VER}/terraform_${VER}_linux_${ARCH}.zip"
    unzip -q -o /tmp/terraform.zip -d /usr/local/bin && rm -f /tmp/terraform.zip
    chmod +x /usr/local/bin/terraform
  fi
}

install_prereqs
install_docker
install_kubectl
install_terraform

echo "---------------------------------------------"
echo -n "Docker:    "; command -v docker >/dev/null && echo "Installed ($(docker --version 2>/dev/null | head -n1))" || echo "Not installed"
echo -n "kubectl:   "; command -v kubectl >/dev/null && echo "Installed ($(kubectl version --client --short 2>/dev/null))" || echo "Not installed"
echo -n "Terraform: "; command -v terraform >/dev/null && echo "Installed ($(terraform version 2>/dev/null | head -n1))" || echo "Not installed"
echo "---------------------------------------------"



# chmod +x install_devops_tools_silent.sh
# sudo ./install_devops_tools_silent.sh
