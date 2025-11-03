
# ==============================================================================
# docker.sh
#
# Bash script that installs Docker on a Linux system (tested on Ubuntu/Debian) and adds the current user to the docker group so Docker can be run without sudo. It also checks whether Docker is already installed and ensures the group assignment takes effect cleanly.
#
# Author: Vijay Kalvakolu
# ==============================================================================

#! /bin/bash

set -e  # Exit on error
set -u  # Treat unset variables as errors
set -o pipefail

# Colors for pretty output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo -e "${YELLOW}Checking for existing Docker installation...${NC}"

if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed: $(docker --version)${NC}"
else
    echo -e "${YELLOW}Installing Docker...${NC}"
    # Update package index
    sudo apt-get update -y

    # Install dependencies
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker’s official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${GREEN}Docker installed successfully!${NC}"
fi

# Add current user to docker group
CURRENT_USER=$(whoami)

echo -e "${YELLOW}Adding user '${CURRENT_USER}' to the docker group...${NC}"
sudo usermod -aG docker "$CURRENT_USER"

echo -e "${GREEN}User added. To apply changes, log out and log back in, or run:${NC}"
echo -e "   ${YELLOW}newgrp docker${NC}"

# Test Docker
echo -e "${YELLOW}Testing Docker access...${NC}"
if newgrp docker <<EOF
docker run --rm hello-world
EOF
then
    echo -e "${GREEN}Docker is working without sudo!${NC}"
else
    echo -e "${YELLOW}You might need to re-login for group changes to take effect.${NC}"
fi
