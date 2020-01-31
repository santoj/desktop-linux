# desktop-linux
Helpful scripts for setting up and managing Debian-based desktop linux systems.

All scripts are intended to be idempotent, so rerunning them won't cause any adverse issues.

Directories of interest:
- *./install/* -- manages downloading and installing all desired packages
- *./configure/* -- manages and validates system settings
- *~/.config/desktop-linux/* -- user specific settings

## Prerequisites
- APT
- GDEBI (if you have deb packages to be installed)
- FLATPAK (if you have flatpak packages to be installed)
- SNAP (Ubuntu-only and only if you have snap packages to be installed)

## Install Script

In the *install* directory you will find the script **install-software.sh** that downloads and installs various packages onto your system. Note: This script requires root access since it is installing packages.

Four package management tools are supported: *apt-get*, *dpkg* (via gdebi), *flatpak*, and *snap*.

Please add your desired packages to the following files in the directory **~/.config/desktop-linux/** (this directory will be created the first time your run the install script):

1. **apt-packages.txt**
2. **dpkg-packages.txt**
3. **flatpak-packages.txt**
3. **snap-packages.txt**

Please refer to the sample files found in the *./install/samples/* directory. You may copy and modify one or more of these files and place them in the user-specific settings directory: *~/.config/desktop-linux/*.

If you need to add PPAs (i.e., *add-apt-repository*) or GPG keys  (i.e., *apt-key add*), you should create a setup file named as follows: **setup-{package}**. For examples, please see: setup-ukuu, setup-sublime, and/or _setup-google-chrome-stable. These optional setup files should also be stored in the user-specific settings directory *~/.config/desktop-linux/*.

Please note that downloaded files are stored in the *~/.config/desktop-linux/.cache/* directory. It is safe to delete this directory to free up disk space or to force new packages to be downloaded. If packages are found in this directory, they will not be downloaded again.

## Configuration Scripts

Configuration scripts exists to setup and validate certain system settings. Please see the *./configure/* directory for:

1. **check-ports.sh**
This script will check all ports that are listening for connections and compare it against a whitelist.
You should copy and modify the **known-ports.txt** file in the *./configure/sample/* directory to the user-specific settings directory: *~/.config/desktop-linux/*.
Any unexpected open ports will be highlighted. Note: This script requires root access in order to see the open ports started by other users (e.g., root). It does not install or modify the system in any way.

2. **setup-ssh-rsa.sh**
This script will create a public/private key pair if one does not already exist.
It will also verify *~/.ssh* directory access permissions and validate that the SSH daemon configuration (i.e., sshd_config) resticts access to key-based authentication only.
Any irregularities will be highlighted, but not corrected. This script does not require root access.

3. **setup-vim-pathogen.sh**
This script will setup [Pathogen](https://github.com/tpope/vim-pathogen) to enable plug-ins to be easily added to vim.
You should copy and modify the **vim-pathogen-git.txt** file in the *./configure/sample/* directory to the user-specific settings directory: *~/.config/desktop-linux/*.
Your ~/.vimrc file will need this command:
> execute pathogen#infect()
