#!/bin/bash

####################################################################
# Installation script for Freightseeker admin application.
#
# Instructions:
# 1. Login to new server as root
# 2. Run installation script:
# bash -c "$(wget -O - https://raw.githubusercontent.com/Freightseeker/Scripts/master/install-admin-staging.sh)"
#
####################################################################

WEB_ROOT=/var/www
GIT_REPOSITORY=git@bitbucket.org:mjarestad/freightseekeradmin.git
GIT_BRANCH=staging

####################################################################
# INITIAL SERVER SETUP
####################################################################

# Update and install upgraded packages
apt-get update
apt-get upgrade

# Install packages to allow apt to use a repository over HTTPS:
apt-get install \
	apt-transport-https \
	ca-certificates \
	curl \
	software-properties-common

# Set correct timezone
timedatectl set-timezone Europe/Stockholm

# Install Git
apt-get install git

# Generate ssh-key
read -p "Du you want to generate a new ssh-key? [Y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	ssh-keygen
	echo "Copy this access key to Bitbucket repository:"
	echo
	cat ~/.ssh/id_rsa.pub
	echo
	read -p "Press enter to continue:"
fi

####################################################################
# INSTALL NODE JS
####################################################################

read -p "Do you want to install NVM (Node.js)? [Y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	apt-get update npm
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.9/install.sh | bash

	export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
	nvm uninstall 8.11.1
	nvm install 8.11.1
	nvm use 8.11.1
	nvm version
	node --version
fi

####################################################################
# INSTALL DOCKER CE
####################################################################

read -p "Du you want to install latest stable version of Docker CE? [Y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Uninstall old versions
	apt-get remove docker docker-engine docker.io
 	apt remove docker-desktop
	rm -r $HOME/.docker/desktop
	rm /usr/local/bin/com.docker.cli
	apt purge docker-desktop

 	# Install packages for docker repository
  	apt-get install \
    	ca-certificates \
    	curl \
    	gnupg \
    	lsb-release

     	# Add Docker’s GPG key to your system
      	mkdir -p /etc/apt/keyrings
      	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

	# Update packages
	apt-get update

	# Add Dockers official GPG key:
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

 	# Setup Docker repository
  	echo \
  	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  	$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

	# set up the Docker stable repository
	add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"

 	# Show available Docker versions
  	apt-cache madison docker-ce | awk '{ print $3 }'

 	# Install Docker version
  	VERSION_STRING=5:24.0.6-1~ubuntu.22.04~jammy
	apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-compose-plugin

	# Install Docker Compose
	curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
fi

####################################################################
# INSTALL FREIGHTSEEKER APPLICATION
####################################################################

read -p "Du you want to clone '$GIT_REPOSITORY' and checkout '$GIT_BRANCH' branch? [Y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	rm -Rf $WEB_ROOT
	mkdir -p $WEB_ROOT
	git clone $GIT_REPOSITORY $WEB_ROOT
	chown -R www-data:www-data $WEB_ROOT
	cd $WEB_ROOT
 	git config --global --add safe.directory /var/www
	git checkout . && git fetch --force && git checkout $GIT_BRANCH
fi

read -p "Du you want to build and run Freightseeker Angular application? [Y/n] " -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	cd $WEB_ROOT
	
	docker stop $(docker ps -a -q)
	docker rm $(docker ps -a -q)
	docker rmi $(docker images -q)
	
	npm run docker:run:staging
fi

exit
