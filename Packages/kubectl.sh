# ==============================================================================
# kubectl.sh
#
# Bash script that installs kubectl utility to interact with kubernetes cluster.
# Author: Vijay Kalvakolu
# ==============================================================================

#!/usr/bin/env bash
# install_kubectl.sh
# Installs the latest stable kubectl binary and sets up autocomplete

set -euo pipefail

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${YELLOW}Checking for existing kubectl installation...${NC}"

if command -v kubectl &>/dev/null; then
    echo -e "${GREEN}kubectl is already installed: $(kubectl version --client --short)${NC}"
    exit 0
fi

echo -e "${YELLOW}Installing kubectl...${NC}"

# Detect OS and Architecture
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    armv8*|aarch64) ARCH="arm64" ;;
    armv7*) ARCH="arm" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

# Get latest version
VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# Download binary
curl -LO "https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}/kubectl"

# Verify download
echo -e "${YELLOW}Verifying checksum...${NC}"
curl -LO "https://dl.k8s.io/${VERSION}/bin/${OS}/${ARCH}/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install to /usr/local/bin
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cleanup
rm -f kubectl kubectl.sha256

# Enable bash completion
if command -v bash &>/dev/null && [ -d /etc/bash_completion.d ]; then
    echo -e "${YELLOW}Setting up kubectl autocompletion...${NC}"
    sudo kubectl completion bash > /etc/bash_completion.d/kubectl
fi

echo -e "${GREEN}kubectl ${VERSION} installed successfully!${NC}"
echo -e "${YELLOW}You can check it using:${NC} kubectl version --client"
