# desktop-linux
Helpful scripts for setting up and managing Debian-based desktop linux systems.

## Prerequisites
- APT
- GDEBI (if you have deb packages to be installed)
- FLATPAK (if you have flatpak packages to be installed)
- SNAP (Ubuntu-only)

## Install Script

In the *install* directory you will find the script **install-software.sh** that downloads and installs various packages onto your system.

Three package management tools are supported: *apt-get*, *dpkg* (via gdebi), *flatpak*, and *snap*.

Please add your desired packages to the following files in the directory ~/.config/desktop-linux/ (this directory will be created the first time your run the install script):
1. **apt-packages.txt**
2. **dpkg-packages.txt**
3. **flatpak-packages.txt**
3. **snap-packages.txt**

You might find the sample files in the install/ directory helpful as there are examples for each of the package management.

If you need to add PPAs (i.e., *add-apt-repository*) or GPG keys  (i.e., *apt-key add*), you should create a setup file named as follows: **setup-{package}**. For examples, please see: setup-ukuu, setup-sublime, and/or _setup-google-chrome. These optional setup files should be stored in the directory ~/.config/desktop-linux/.

Please note that downloaded files are stored in the *.cache* directory. It is safe to delete this directory to free up disk space or to force new packages to be downloaded. If packages are found in this directory, they will not be downloaded again.
