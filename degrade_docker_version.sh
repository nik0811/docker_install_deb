#!/bin/bash 
# AUTHOR: Nikhil Kumar

set -e

DOCKER_VERSION="19.03.15~3-0"
CONTAINERD_VERSION="1.4.11-1"
DOCKER_PLUGIN_VERSION="0.7.0"
INSTALL_DOCKER=$1

function main
{
   if ((${EUID:-0} || "$(id -u)")); then
      echo "Run the script with sudo user."
   elif [[ "$INSTALL_DOCKER" == "install" ]]; then
      degrade_docker_version
   else
      verify_version
   fi
}

function verify_version 
{
	current_version=$(docker --version | awk '{printf $3}' | tr -d "," | cut -d "." -f 1)
	if [[ $current_version -lt 20 ]]; then
	    echo "Version $(docker --version | awk '{printf $3}') is already compatible, Exiting..!!!"
	else
		degrade_docker_version
	fi
}

function degrade_docker_version {
    DOCKER_CURRENT_VERSION=$(docker --version | awk '{printf $3}')

    echo "*********************************************"
    echo "* Removing Current Docker Version: $DOCKER_CURRENT_VERSION *"
    echo "*********************************************"
    apt-get purge -y docker* containerd*
    apt-get autoremove -y docker* containerd*
    rm -rf /var/lib/docker /etc/docker
    rm /etc/apparmor.d/docker
    groupdel docker
    rm -rf /var/run/docker.sock
    echo "****************************"
    echo "* Installing Docker CLI    *"
    echo "****************************"
    wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce-cli_$DOCKER_VERSION~ubuntu-focal_amd64.deb
    dpkg -i docker-ce-cli_$DOCKER_VERSION~ubuntu-focal_amd64.deb
    echo "****************************"
    echo "* Installing Containerd    *"
    echo "****************************"
    wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/containerd.io_$CONTAINERD_VERSION\_amd64.deb
    dpkg -i containerd.io_$CONTAINERD_VERSION\_amd64.deb
    echo "****************************"
    echo "* Installing Docker CE     *"
    echo "****************************"
    wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-ce_$DOCKER_VERSION~ubuntu-focal_amd64.deb
    dpkg -i docker-ce_$DOCKER_VERSION~ubuntu-focal_amd64.deb
    echo "****************************"
    echo "* Installing Scan Plugin   *"
    echo "****************************"
    wget https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/docker-scan-plugin_$DOCKER_PLUGIN_VERSION~ubuntu-focal_amd64.deb
    dpkg -i docker-scan-plugin_$DOCKER_PLUGIN_VERSION~ubuntu-focal_amd64.deb
    sudo apt-get install -y -f
    rm -rf *.deb
    echo "****************************"
    echo "* Restarting Docker Daemon *"
    echo "****************************"
    systemctl restart docker
    groupadd docker
    usermod -aG docker $USER
    newgrp docker
    echo "**************************"
    echo "* Checking Docker Status *"
    echo "**************************"
    echo "Docker service is $(systemctl show -p ActiveState --value docker.service) and $(systemctl show -p SubState --value docker.service) and New version is $(docker --version) !!!"
}

main
