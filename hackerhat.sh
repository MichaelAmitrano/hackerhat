#!/bin/bash

### Created:     8/24/2022         ###
### Last Edited: 9/23/2022         ###
### Made By:     Michael Amitrano  ###


# Asking the user if they are ready to start their installation.
function run {
	echo -e "It is recommended that you run this file in your working directory and on a fresh installation. \nThis installation will require about 6gb of space. "
	read -n1 -p "Are you ready to continue? (y/n) " userinput

	case $userinput in 
		y|Y) echo -e "\n\n#########################\nMade by: Michael Amitrano\n#########################\n";;
		n|N) echo -e "\nExiting..." && exit;;

	esac
}


# Prepares the system for everything else to be installed.
function prepare_system {
	echo "Preparing system:"

	# Optimizing DNF to make installation faster and more efficient.
	echo -e "\n# Edit for speed: \nfastestmirror=True \nmax_parallel_downloads=10 \ndefaultyes=True \nkeepcache=True \n\n# run 'sudo dnf clean dbcache' to clear the dnf cache." >> /etc/dnf/dnf.conf
	dnf update -y 
	dnf upgrade -y

	# Making some Dirs to be used later.
	mkdir Scripts && mkdir Scripts/SecLists && mkdir Scripts/PrivEsc

	echo "Done preparing system."
}


# Gives the user the option to install additional desktop environments. 
function add_optional_DEs {
	echo -e "\nHacker-hat gives you the option to install additional Desktop Environments.\nHere are your options:\n1: Do nothing\n2: Install KDE\n3: Install Cinnamon\n4: Install Deepin\n"
	read -n1 -p "Choose a number from one of the options above: " userinput

	case $userinput in
		1) echo -e "\n\nSkipping.";;

		2) echo -e "\n\nInstalling KDE..." && dnf grouplist -v
		dnf install -y @kde-desktop-environment;;

		3) echo -e "\n\nInstalling Cinnamon..." && dnf grouplist -v
		dnf install -y @cinnamon-desktop-environment;; # My personal favorite.

		4) echo -e "\n\nInstalling Deepin..." && dnf grouplist -v
		dnf install -y @deepin-desktop-environment;;

	esac
}


# Installs some quality of life software.
function add_system_packages {
	echo -e "\nInstalling system packages:\nInstalling RPM Fusion..."
	dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	dnf -y groupupdate core

	echo -e "\nEnabling Flatpacks..."
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

	echo -e "\nInstalling media codecs for better audio..."
	dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
	dnf -y groupupdate sound-and-video

	echo -e "\nInstalling htop..."
	dnf install -y htop 
	echo -e "\nInstalling pip..."
	dnf install -y pip 
	echo -e "\nInstalling gedit..."
	dnf install -y gedit

	echo "Done installing system packages."
}


# The three functions below should all be self explanatory.
function add_vscode {
	echo -e "\nInstalling VS Code..."
	rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
	dnf install -y code
}


function add_sublime {
echo -e "\nInstalling Sublime..."
	rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
	dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
	dnf install -y sublime-text
}


function add_metasploit {
	echo -e "\nInstalling Metasploit..."
	curl "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" > msfinstall 
	chmod 755 msfinstall
	./msfinstall 
	rm msfinstall
}


# This adds the main pen-testing software.
function add_sec_packages {
	echo -e "\nInstalling sec packages:\nInstalling ZAP..."
	flatpak -y install zaproxy

	add_vscode
	add_sublime
	add_metasploit

	echo -e "\nInstalling terminator..."
	dnf install -y terminator 
	echo -e "\nInstalling Nmap..."
	dnf install -y nmap 
	echo -e "\nInstalling nikto..."
	dnf install -y nikto
	echo -e "\nInstalling hashcat..."
	dnf install -y hashcat 

	echo -e "\nInstalling ImPacket..."
	python3 -m pip install impacket

	echo "Done installing security packages."
}


# I put the scripts in their own function for neater code.
function add_sec_scripts {
	echo -e "\nInstalling sec scripts:\nInstalling SecLists..." && git clone https://github.com/danielmiessler/SecLists.git Scripts/SecLists

	echo -e "\nInstalling Responder..." && curl -L "https://raw.githubusercontent.com/lgandx/Responder/master/Responder.py" > Scripts/Responder.py 

	# The script uses chmod in case the user wants to go ahead and test some of these scripts on their own system.
	echo -e "\nInstalling scripts for privileg escalation..." && curl -L "https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh" > Scripts/PrivEsc/linpeas.sh 
	chmod 777 Scripts/PrivEsc/linpeas.sh
	curl -L "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany_ofs.exe" > Scripts/PrivEsc/winpeas.exe 
	curl -L "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" > Scripts/PrivEsc/linenum.sh 
	chmod 777 Scripts/PrivEsc/linenum.sh
	curl -L "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh -O les.sh" > Scripts/PrivEsc/linux-exploit-suggester.sh 
	chmod 777 Scripts/PrivEsc/linux-exploit-suggester.sh 
	curl -L "https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1" > Scripts/PrivEsc/PrivescCheck.ps1

	echo "Done installing scripts."
}


# Gives the user the option to reboot so they can use the DE they installed.
function optional_reboot {
	echo -e "\nAll installations finished! \nIf you installed any additional desktop enviroments it is recommended that you reboot your device now in order for everything to take effect, and then you'll be all done.\n"
	read -n1 -p "Would you like to reboot now? (y/n) " userinput

	case $userinput in 
		y|Y) echo -e "\nRebooting now." && reboot;;
		n|N) echo -e "\nAll done!";;

	esac
}


function main {
	# Checking to see if the user is running this script as root.
	if [ "$EUID" -ne 0 ] 
	then
		echo "Script must be run as root."

	else
		# Calling the functions.
		run
		prepare_system 	
		add_optional_DEs
		add_system_packages
		add_sec_packages
		add_sec_scripts
		optional_reboot

	fi
}

main
