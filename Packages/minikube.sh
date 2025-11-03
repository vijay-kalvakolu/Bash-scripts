
# ==============================================================================
# minikube.sh
#
# Bash script that install minikube.
# Author: Vijay Kalvakolu
# ==============================================================================

#!/usr/bin/env bash
# install_minikube.sh
# Installs the latest version of Minikube on Linux

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${YELLOW}Checking for existing Minikube installation...${NC}"

if command -v minikube &>/dev/null; then
    echo -e "${GREEN}Minikube is already installed: $(minikube version)${NC}"
    exit 0
fi

# Check Docker installation (since it’s the most common driver)
if ! command -v docker &>/dev/null; then
    echo -e "${RED}Docker not found.${NC}"
    echo -e "${YELLOW}You can install it using your docker install script first.${NC}"
    exit 1
fi

# Detect OS and Architecture
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7*) ARCH="arm" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo -e "${YELLOW}Downloading latest Minikube release...${NC}"
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}"

echo -e "${YELLOW}Installing minikube...${NC}"
sudo install minikube-linux-${ARCH} /usr/local/bin/minikube
rm -f minikube-linux-${ARCH}

echo -e "${GREEN}Minikube installed successfully!${NC}"

# Verify installation
minikube version

# Optional: enable bash completion
if command -v bash &>/dev/null && [ -d /etc/bash_completion.d ]; then
    echo -e "${YELLOW}Setting up Minikube autocompletion...${NC}"
    sudo minikube completion bash > /etc/bash_completion.d/minikube
fi

echo -e "${GREEN}Minikube setup complete.${NC}"
echo -e "${YELLOW}You can start your cluster with:${NC}"
echo -e "   ${GREEN}minikube start --driver=docker${NC}"
echo -e "${YELLOW}Then verify with:${NC} kubectl get nodes"
