# NIX Home Manager
Sharing the nix home manager configuration for Debian accross multiple desktop machines

## 1. Linux Developer Environment

Activate crosh

* Name: torsten
* Size: 85 GB

## 2. Nix Packetmanager

Install the Nix package manager globally

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```
## 3. Home-Manager Repository

Use `gh` nix package to clone the github repository

```sh
nix-shell -p gh
```

Log into github

```sh
gh auth login
```

Clone home manager repository

```sh
gh repo clone torstenboettjer/home_manager
```

## 4. Experimental Features

Enabling experimental features by appending the following line to `/etc/nix/nix.conf`:

```sh
echo -e "experimental-features = nix-command flakes\ntrusted-users = root torsten" | sudo tee -a /etc/nix/nix.conf
```

Run functional test

```sh
nix run nixpkgs#hello
```

## 5. Home-Manager Channel

Add the appropriate channel, e.g. to follow the Nixpkgs master channel run:

```sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
```

## 6. Installation

Create the first home-manager generation

```sh
nix-shell '<home-manager>' -A install
```

Add the nix path to `.bashrc`

```sh
echo -e '. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"' >> $HOME/.profile
```

Test the installation

```sh
source $HOME/.nix-profile/etc/profile.d/hm-session-vars.sh
home-manager --version
```

Make sure that the right system is active in *~/home_manager/flake.nix*

```nix
  outputs = { nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      # system = "x86_64-linux";
      system = "aarch64-linux";
```

Configure git to push changes into the home-manager repository

```sh
git config --global user.email "torsten.boettjer@gmail.com"
git config --global user.name "Torsten Boettjer"
```

Run the Makefile

```sh
cd ~/home_manager
make
```
