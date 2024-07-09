#!/bin/bash

# Exit on error
set -e

PLTFRM=$1

# Function to strip surrounding quotes from a string
strip_quotes() {
    echo "$1" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}

# clone the default home-manager configuration
nix-shell -p gh --run "gh auth login -h github.com -s user && \
        gh api user > ${HOME}/ghacc.json && \
        gh api user/emails > ${HOME}/mails.json && \
        gh repo clone hcops/workspace"

NME=$(nix-shell -p jq --run "jq -r '.name' ${HOME}/ghacc.json")
EML=$(nix-shell -p jq --run "jq '.[] | select(.primary == true) | .email' ${HOME}/mails.json")

# Strip quotes from the mail string
EML=$(strip_quotes $EML)

# activating experimental features
echo "experimental-features = nix-command flakes\ntrusted-users = root ${USER}" | sudo tee -a /etc/nix/nix.conf

# add the home-manager package channel
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager

# updte the home manager channel
nix-channel --update

# create the first home-manager generation
nix-shell '<home-manager>' -A install

# add the nix path to `.bashrc`
echo '. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"' >> $HOME/.profile

echo "Username: ${NME}"
echo "GH eMail: ${EML}"

# override a placeholder in a configuration file with a variable
sed -i "s/_USRNAME_/${USER}/g" $HOME/workspace/home.nix 
sed -i "s/_GHBNAME_/${NME}/g" $HOME/workspace/home.nix
sed -i "s/_GHBMAIL_/${EML}/g" $HOME/workspace/home.nix 
sed -i "s/_SYSTEM_/${PLTFRM}/g" $HOME/workspace/flake.nix

# cd $HOME/workspace/ && git add . && git commit -m "update configuration files"

cd $HOME/workspace/ 

# test the installation
home-manager --version

# activate home manager
home-manager switch --flake .#$USER

# Check if the file exists
HOME_PATH="${HOME}/.config/home-manager/home.nix"
if [ -f "$HOME_PATH" ]; then
  echo "File '$HOME_PATH' exists. Replacing..."
  rm "$FILE_PATH"
  echo "File '$HOME_PATH' has been deleted."
else
  echo "File 'home.nix' does not exist, creating ..."
fi

FLAKE_PATH="${HOME}/.config/home-manager/flake.nix"
if [ -f "$FLAKE_PATH" ]; then
  echo "File '$FLAKE_PATH' exists. Replacing..."
  rm "$FILE_PATH"
  echo "File '$FLAKE_PATH' has been deleted."
else
  echo "File 'flake.nix' does not exist, creating ..."
fi

for file in home.nix flake.nix; do ln -s "${HOME}/workspace/$file" "${HOME}/.config/home-manager/$file"; done
