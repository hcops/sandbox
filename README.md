# Engineering Sandbox

Building cloud services for enterprises starts with an environment that enables system engineers to develop, maintain and execute system configurations without creating dependencies on specific programming languages, frameworks or platform services. Other than most cloud service operator, enterprise service operator need to be able, to provision purpose build systems that accomodate technical requirements of third party applications. While cloud operators have moved from runbook automation to infrastructure-as-code (IaC) and employ provisioning tools like Terraform to automate service deployments with immutable artifacts, enterprise operator need tools that also help them to manage the uptime, security and performance of mutable hosts. And while IaC tools work under the assumption, that applications are deployed through a cloud controller that orchestrates workloads on infrastructure pools, the scope of a service delivery platform in enterprise IT compromises applications that don't adhere to a micro-service design. Translating system definitions into api calls is not sufficient, declarative package manager and and process composer are required, with the ability to utilize configuration files that trigger system changes and match the lifecycle stage of an application, not the other way around.

## Technology Stack

Adopting functional deployments for applications that run on dedicated hosts demands for declarative configurations that do not abstract the runtime environment, network and storage interface. The nix package manager solves this problem for Linux systems. Nix was introduced in [2003 by Eelco Dolstra](https://en.wikipedia.org/wiki/Nix_(package_manager)) to create a reliable system for software deployments. The nix package manager allows engineers to compose purpose build operating systems and store the configuratons in a git repository to centralize management tasks, to track and roll back system configurations. Sharing configurations in a repository fosters the development of platforms with advanced compliance and security requirements without burdening application owners or development teams. Using these files for development, test and production enables the development of consistent blueprints that provide similar advantages like immutable infrastructure without introducing the same limitations. A local development environment compromises the following tools:

* **[Linux OS](https://chromeos.dev/en/linux)**: Debian VM or Container that allows developers to run Linux apps for development alongside the usual desktop and applications.
* **[Nix Package Manager](https://nixos.org/)**: A Linux configuration manager that enables reproducible and declarative builds for virtual machines.
* **[Process-compose](https://f1bonacc1.github.io/process-compose/)**: Command-line utility to facilitate the management of processes without further abstraction.
* **[Devenv](https://devenv.sh/)**: Configuration tool to define development environment declaratively by toggling basic options for nix and process-compose.
* **[Direnv](https://direnv.net/)**: Shell extension to load and unload devenv environments automatically moving in and out of a directory.

## Getting Started

Setting up a sandbox engineers need access to a git repository and a Linux VM or container. The typical desktop systems like [Windows](https://learn.microsoft.com/en-us/windows/wsl/about) or [ChromeOS](https://chromeos.dev/en/linux) let developers to run a Linux environment without installing a second operating system. MacOS can use the Nix package manager directly and refer to  [nix-darwin](https://github.com/LnL7/nix-darwin) community project. The default recommendation for a new development environment is an avialable disk size of *80 to 120GB*, however, the size really varies from use case to use case. The package mananger is installed via command line interface. 

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon --yes
```

Nix enables functional deployments and provides features like reproducibility, isolation, and atomic upgrades. Key features is ensuring a consitent package deployments through precise specification of dependencies and build instructions. To activate the package manager, a reference is added to the shell configuration (e.g. ~/.bashrc), hence after the installation, the shell session requires a restart.

```sh
exec bash && source ./.bashrc
```

With nix being active, building a sandbox becomes a three step process: 

### Step 1: Common Tools and Services

A standard toolset in system engineering is key for long term quality and maintainability for system administrators. The [Home-Manager](https://nix-community.github.io/home-manager/) defines user environments that provide the look and feel for an engineers accross Linux machines. Administrators rely on homogenous set of tools, regardless where they login. Sharing a default home configuration through git enables central departments like purchasing, compliance and technology operation to provide shared services. The example [setup script](./setup) deploys a toolset on wither `x86_64-linux` or `aarch64-linux` based Chromebooks. 

```sh
curl -L https://raw.githubusercontent.com/hcops/sandbox/main/setup | sh -s -- <x86_64-linux or aarch64-linux>
```

The home configuration is defined with the [home.nix](./home.nix) file. The github client is used to load a default configuration and ensures the use of a homogenous toolset accross of development and production environments in a team. The system configuration in the [flake.nix](./flake.nix). Flakes are still classified as experimental feature in Nix, a respective flag is appended to `/etc/nix/nix.conf`. 

### Step 2: Platform Composition

One of the complexity driver in the development of cloud services is the divergent structure in application development and serrvice operation. While development teams are organized around solutions to focus on the delivery of business functionality, operation teams are organized around services for efficient management and maintenance of system software. 

Activating direnv, an environment switcher for the shell that automatically loads and unloads environment variables, when the directory is changed

```sh
echo -e 'eval "$(direnv hook bash)"' >> $HOME/.bashrc
```

### Step 3: Service Configuration

Devenv is a tool that leverages Nix to create reproducible development environments, it is an extension of the Nix ecosystem, tailored for development workflows. A development environment is defined by creating a directory, setting up a git repository, and sharing the repository with other developers via Github.

```sh
devenv init
```

Will create the following files in a given repository: `.envrc, devenv.nix, devenv.yaml, .gitignore`. The nix file contains the system software and platform components, required to build an applications.
