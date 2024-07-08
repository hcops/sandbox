#!/bin/bash

# Exit on error
set -e

# create log file
touch ./setup.log

# clone the default home-manager configuration 
nix-shell -p gh --run "gh api user > $HOME/ghacc.json"
nix-shell -p gh --run "gh repo clone hcops/workspace"

# activating experimental features
echo -e "experimental-features = nix-command flakes\ntrusted-users = root ${USER}" | sudo tee -a /etc/nix/nix.conf

# add the home-manager package channel
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

# updte the home manager channel
nix-channel --update

# create the first home-manager generation
nix-shell '<home-manager>' -A install

# add the nix path to `.bashrc`
echo -e '. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"' >> $HOME/.profile

# test the installation
source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh && home-manager --version

# activate home manager
home-manager switch --flake .#$USER