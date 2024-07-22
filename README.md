# Operator Sandbox

The operator sandbox provides an development and execution environment for operation engineers, migrating applications to a hybrid cloud. It introduces an alternative approach towards infrastructure automation that is not determined by the use of "infrastructure as code (IaC)" tools to meet enterprise requirements. Usually, cloud engineers employ a combination of applications like Terraform, Ansible and Kubernetes to automate system configurations, topology designs and container deployments. Yet configuration management systems, provisioning tools and container platforms overlap significantly in functionality. Designed for deployment, these tools integrate with orchestrators to automate resource provisioning from a shared infrastructure pool, rather than enabling ongoing management and centralizing control functions. This approach simplifies cloud-native application management but introduces complexity for operators handling a mix of third-party applications with different requirements. Cloud automation tools combine system definitions and execution instructions in a common code base, which leads to a fragmentation of design decisions. The lack of control makes it difficult to ensure the integrity of business-critical data and to meet technical, commercial, or regulatory requirements with appropriate operation procedures. Sandboxes provide a safe environment for running code by isolating instructions and relying on external definitions. This ensures security and control. Functions leverage both dedicated and distributed systems, using open standards for a unified approach. Control interfaces, managed by orchestration tools or the resources themselves, decouple service launch from service definition. This prioritizes regulatory compliance, security policies, and justification for service decisions before deployment.

## Host System

Declarative package managers like [Guix](https://guix.gnu.org/) or [Nix](https://github.com/NixOS/nix) provide programmability on operating system level. Operators define a desired system state in configuration files that isolate the dependencies for software packages and ensure clean and reproducible systems without wrapping application runtimes into virtual machines or container. Executable templates define purpose build systems in a functional programming language. The foundation is a strip down version of the linux operating system that only covers the most essential components communicating with the hardware. The packet manager triggers changes to the operating system with templates that match the runtime requirements and the topology design without depending on orchestrator capabilities packaging mechanisms or specific communication patterns. This enables operation teams to centralize system designs without owning the configuration and to track and to roll back system configurations in a similar way like immutable artifacts without abstraction of the runtime environment, network- and storage interfaces.

### Installation

The layered architecture of the sandbox enables system engineers to develop service blueprints without prescribing an infrastructure platform or an operating model. Development tools are employed independently from platform components and service configurations. Application developers retain the freedom to employ system software, while service operator regain full control over the technology platform - even if it is partially outsourced to a cloud provider. The service design avoids implicit dependencies on orchestrators and/or packaging mechansims. While the development process is decentralized, configuration templates are shared via git repositories. External services can be integrated, sharing dotfiles which enables administrators to provide accounts and secrets in a controled fashion. 

![Technology Stack](./img/techStack.drawio.svg)

Code contributors only need access to a Linux environment, a subsystem provided by [Windows](https://learn.microsoft.com/en-us/windows/wsl/about) or [ChromeOS](https://chromeos.dev/en/linux) is sufficient. The virtual maschine requires enough space to cache the platform components of a project though. A minimum size of *80 to 120GB* is recommended - however, this really depends on the number and the complexity of the service blueprints that are being developed. The setup script contains a default toolset with VS-Code, gh and jq already and uses Github for code sharing. The github client is also used to load default parameter into the configuration. 

```sh
curl -L https://raw.githubusercontent.com/hcops/sandbox/main/setup | sh -s
```

The script installs the [Lix](https://lix.systems/)  package manager, a fork from the original nix package manager. System configurations are written in the nix language that allows engineers to manage dependencies on operating system level and trigger provisioning processes dedicated server or produce virtual artifacts. Storing declaration files in a repository together with the application code fosters the development of consistent blueprints and provides similar advantages like immutable infrastructure without introducing the same limitations. Nix was introduced in 2003 by [Eelco Dolstra](https://en.wikipedia.org/wiki/Nix_(package_manager)) to create a reliable system for software deployments. Managing packets programmatically ensures reproducibility, isolation, and atomic upgrades with consistent package deployments through specification of package dependencies and build instructions. To activate the package manager after installation, the shell session requires a restart. 

```sh
exec bash && source ~/.bashrc
```

MacOS users cannot rely on the convenience of an isolated subsystem but refer to the [nix-darwin](https://github.com/LnL7/nix-darwin) project and arrive at the same point. Alternatively, a virtual maschine on a hypervisor can be considered. 

### Development Tools

A standard toolset in system engineering is an enabler for long term quality and maintainability of the infrastructure code. In the sandbox it is deployed using **[Home-manager](https://nix-community.github.io/home-manager/)**, a nix extension that configures user environments through the `home.nix` file. Home manager supports two ways of deploying applications, programs and the packages. For a develoment environment `programs` are the prefered method, it refers to modules that install the software and configure system wide features when applicable. The home manager [option search](https://home-manager-options.extranix.com/) provides an overview of available programs.
```ǹix
  programs = {
    direnv.enable = true; # https://direnv.net/

    vscode = {
      enable = true; # https://code.visualstudio.com/
      package = pkgs.vscodium;
      enableUpdateCheck = false;
    };

    jq.enable = true;     # https://jqlang.github.io/jq/
    fzf.enable = true;    # https://github.com/junegunn/fzf
    gh.enable = true;     # https://cli.github.com/manual/
  };
```

Referencing a application in the `home.packages` also installs additional software packages but lacks configuration options. Nix packages are published in a [package directory](https://search.nixos.org/packages). The command `nix-env -qaP` lists packages incl. the available attributes at the command line. `Override` and `overrideAttrs` functions enable engineers to build packages from source by processing attributes like `src`, `buildInputs`, `makeFlags`, etc.. Some packages use overrides for fine-tuning like a [fonts package](https://search.nixos.org/packages?channel=unstable&show=nerdfonts&from=0&size=50&sort=relevance&type=packages&query=nerdfonts) that allows to adjust the default list of fonts. 


```ǹix
  home.packages = with pkgs; [
    devenv       # https://devenv.sh/
    gnumake      # https://www.gnu.org/software/make/manual/make.html
    # lunarvim   # https://www.lunarvim.org/
    # zed-editor # https://zed.dev/

    # Override example
    # (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    (writeShellScriptBin "create_project" ''
      # capture the project name with a first argument
      PROJECT=$1

      # Check whether sync repo already exist
      if [ $(gh api repos/${gituser}/$PROJECT --silent --include 2>&1 | grep -Eo 'HTTP/[0-9\.]+ [0-9]{3}' | awk '{print $2}') -eq 200 ]; then
        echo "project $PROJECT already exists!"
      else
        # Create the new remote repository on GitHub
        gh repo create "${gituser}/$PROJECT" --private
  
        # Check if the repository was created successfully
        if [ $? -ne 0 ]; then
            echo "Failed to create the remote repository on GitHub."
            exit 1
        fi
  
        # create projects directory if it doesn't exist
        mkdir -p ${projectdir} && cd ${projectdir}
  
        # Clone the project repository with gh
        gh repo clone ${gituser}/$PROJECT
  
        # Verify the new remote setup
        cd ${projectdir}/$PROJECT && git remote -v
  
        echo "The $PROJECT repository has been created."
        echo "Remote repository: https://github.com/${gituser}/$PROJECT.git"
    fi
    '')
  ];
```

The package section also allows to enhance the shell with small scripts. E.g. a "project \<name\>" pulls the code from a project repository, which allows DevOps team to rely on the version control system for the onboarding of new members. It should be mentioned though that home manager is not the only option to define a default set of development tools and services with nix, e.g. [Flakey](https://github.com/lf-/flakey-profile), which provides less automation but more control.


### Platform Components

A service delivery platform acts as the building block for service operation. It provides the necessary resources, like application runtimes, databases, and development tools on-demand. This allows application owners to provision the resources they need, deploy applications on managed infrastructure, while retaining control of resources through a self-service portal. For developers a platform goes beyond resource allocation. It automates tasks like configuration management, continuous integration/continuous delivery (CI/CD), and monitoring. This frees up valuable time and effort. This eliminates reliance on other teams. Service operator are required to offer a standardized set of services with a well-defined API for provisioning. DevOps engineers benefit from such a unified interface that simplifies the process of deploying tools and accessing the services they need. Cloud provider provide provisioning API through an orchestrator, dedicated systems rely on configuration files for service deployments. The declarative package manager is an important enabler for end to end automation. It separates the definition of the host system from individual applications (using "flakes" files). This allows operators to expose system configurations as blueprints and make reusable configurations accessible through an API. Custom systems tailored to specific needs without pre-defining the entire operating model provides consistency over the entire application lifecycle. This streamlined approach fosters collaboration and efficiency. Even on local desktops, a simple script executes the setup process for an entire platform. And engineers can quickly get up and running on projects pulling the configuration from a version control system. The same command sets up a new project in the project directory and replicates an initial configuration to a GitHub repository. New projects are based on a [default template](https://github.com/hcops/template/tree/main) that includes a [PostgreSQL](https://www.postgresql.org/) server and the [Rust toolchain](https://www.rust-lang.org/).

```sh
project name
```

The development of system templates is simplified using **[direnv](https://direnv.net/)**, a shell extension that loads and unloads system configurations moving in and out a directory. One of the biggest hurdles for DevOps in large organizations is managing rapid iteration cycles with combined application and operations teams. System management is a horizontal function, and joining multiple Scrum teams can leave operators overloaded, hindering their ability to complete daily tasks. Direnv offers a solution by empowering engineers to provision environments through configuration files. This frees system specialists from attending meetings where their input is limited. Additionally, Direnv provides a convenient way to share platform configurations using a Git service. These configuration files ensure isolation of dependencies between software packages, promoting stability. Direnv utilizes .envrc files to reference configurations that automatically trigger a provisioning process. A streamlined approach reduces the burden on system specialists and allows developers to fulfill their core tasks.

```sh
direnv allow
```

Entering a directory for the first time, a flag needs to be set, that allows direnv to monitor chnages in the configuration and to load the defined tools automatically. It checks for the existence of a .envrc file and if the file exists, the defined variables are captured and made available in the current shell. Nix supports multiple concepts of separating environment definitions, and direnv only requires a rerference to the configuration file in .envrc. Developing services, engineers need the freedom determine a platform configuration together with the system configuration. Therefore `devenv.nix` file combines platform configurations and system definitions in a single file. 

```sh
echo "use flake" >> .envrc
```
Once the templates are complete and the configuration is tested, platform components can be moved into a flake and *.envrc* is extended, e.g. to store the configuration without development tools in a service catalog and to prepare the deployment on a production system. Flakes are still classified as experimental feature, a respective flag is appended to `/etc/nix/nix.conf` during the installation process. 

### Service Configuration

**[Devenv.sh](https://devenv.sh/)** is a configuration tool that allows engineers to define development environments declaratively by toggling basic options for nix and process-compose. Devenv leverages Nix to create reproducible development environments, it is an extension of the Nix ecosystem, tailored for development workflows. A development environment is defined by creating a directory, setting up a git repository, and sharing the repository with other developers via Github.

```sh
devenv init
```

Will create the following files in a given repository: `.envrc, devenv.nix, devenv.yaml, .gitignore`. The nix file contains the system software and platform components, required to build an applications. Because the configuration is declarative, the entire system configuration is replicated over git repositories, which allows match the lifecycle and the technical requirements of the application code or binaries. Instantiation is triggered through "actions", configurations are shared across teams.

## Contribution
This is merely a setup script that helps operators to launch a nix based sandbox. The aim is to ease the adoption of a technology that resolves issues,  system administrators experience, migrating enterprise applications to a cloud provider. Any contribution is highly welcome, e.g.:
* *Add features* If you have an idea for a new feature, please [open an issue](https://github.com/hcops/sandbox/issues/new) to discuss it before creating a pull request.
* *Report bugs* If you find a bug, please [open an issue](https://github.com/hcops/sandbox/issues/new) with a clear description of the problem.
* *Fix bugs* If you know how to fix a bug, submit a [pull request](https://github.com/hcops/sandbox/pull/new) with your changes.
* *Improve documentation* If you find the documentation lacking, you can contribute improvements by editing the relevant files.
