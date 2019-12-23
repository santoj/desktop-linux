# desktop-linux
Helpful scripts for setting up and managing Debian-based desktop linux systems.

## Install Script

In the *install* directory you will find the script **install-software.sh** that downloads and installs various packages onto your system.

Three package management tools are supported: *apt-get*, *dpkg* (via gdebi), and *flatpak*.

Please add your desired packages to the following files (in order of preference):
1. **apt-packages.txt**
2. **dpkg-packages.txt**
3. **flatpak-packages.txt**

If you need to add PPAs (i.e., *add-apt-repository*) or GPG keys  (i.e., *apt-key add*), you should create a setup file named as follows: **_setup-{package}**. For examples, please see: _setup-ukuu, _setup-sublime, and/or _setup-google-chrome.

Please note that downloaded files are stored in the *.cache* directory. It is safe to delete this directory to free up disk space or to force new packages to be downloaded. If packages are found in this directory, they will not be downloaded again.
