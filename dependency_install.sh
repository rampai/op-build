#!/bin/bash

#set -exuo pipefail #print all commands that are run

#-----------------------------------------------Define Functions---------------------------------------------
# Language Version Testing

Test_gcc_Version()
#get the current gcc version and return true if it is compatible and false if it is not
{
	current_gcc_version="$(gcc -dumpversion)" || current_gcc_version="0.0.0"
	required_gcc_version="6.2.0"
	if [ "$(printf '%s\n' "$required_gcc_version" "$current_gcc_version" | sort -V | head -n1)" = "$required_gcc_version" ]; then
		return 0
	else
		return 1
	fi
}

Test_python_Version()
#get the current python version and return true if it is compatible and false if it is not
{
	current_python_version="$(python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
	current_python2_version="$(python2 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')"
	required_python_version="2.7.0"
	if [ "$(printf '%s\n' "$required_python_version" "$current_python_version" | sort -V | head -n1)" = "$required_python_version" ] || [ "$(printf '%s\n' "$required_python_version" "$current_python2_version" | sort -V | head -n1)" = "$required_python_version" ]; then
		return 0
	else
		return 1
	fi
}

#Language Installations

Install_compatible_gcc_version()
#installs a compatible gcc version
{
	current_dir=$(pwd)
	wget https://ftp.gnu.org/gnu/gcc/gcc-9.2.0/gcc-9.2.0.tar.gz
	tar -xzf gcc-9.2.0.tar.gz
	mkdir build
	cd build
	../gcc-9.2.0/configure
	sudo make -j$allocated_cpus
	sudo make -j$allocated_cpus install
	cd $current_dir
}

Install_compatible_python_version()
#installs a compatible python version
{
	current_dir=$(pwd)
	wget https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz
	tar xzf Python-2.7.16.tgz
    cd Python-2.7.16
    ./configure --enable-optimizations
    sudo make -j$allocated_cpus altinstall
    sudo ln -s /usr/local/bin/python2.7 /usr/local/bin/python
	cd $current_dir
}

#Dependency Downloads
Download_Ubuntu_And_Debian_Dependencies()
#downloads the dependencies required by the Ubuntu and Debian distros
{
	if $Distro=="Ubuntu"; then
                #Enable Universe
                sudo apt-get install software-properties-common
                sudo add-apt-repository universe
	fi
        #Dependencies
	ubuntu_and_debian_dependences=cscope,ctags,libz-dev,libexpat-dev,python,language-pack-en,texinfo,build-essential,g++,git,bison,flex,unzip,libssl-dev,libxml-simple-perl,libxml-sax-perl,libxml-parser-perl,libxml2-dev,libxml2-utils,xsltproc,wget,bc,rsync
	for dependency in ${ubuntu_and_debian_dependences//,/ }
	do
		sudo $INSTALLATION_OPERATOR install $dependency -y
		sucessful=$(echo $?)
		if [ $sucessful  != 0 ]; then
			FOR_USER_MANUAL_INSTALL+=",$dependency"
		fi
	done

}
Download_Fedora_CentOS_And_Redhat_Dependencies()
#downloads the dependencies required by the Fedora CentOS and Redhat distros
{

	#Dependencies
	fedora_centos_and_rhel_dependencies=expat-devel,patch,zlib-devel,zlib-static,texinfo,perl-bignum,"perl(XML::Simple)","perl(YAML)","perl(XML::SAX)","perl(XML::SAX)","perl(Fatal)","perl(Thread::Queue)","perl(Env)","perl(XML::LibXML)","perl(Digest::SHA1)",which,tar,cpio,bzip2,findutils,ncurses-devel,make,vim-common,libxml2-devel,wget,unzip,bc,flex,bison,git,ctags,cscope,gmp-devel,mpfr-devel,libmpc-devel,glibc-devel,libgcc,gcc-c++,openssl-devel

	for dependency in ${fedora_centos_and_rhel_dependencies//,/ }
	do
		sudo $INSTALLATION_OPERATOR install $dependency -y
		sucessful=$(echo $?)
		if [ $sucessful  != 0 ]; then
			FOR_USER_MANUAL_INSTALL+=",$dependency"
		fi
	done
}


#-----------------------------------------------Main Program---------------------------------------------

#Make sure the program is not run as root.
if [ `whoami` = "root" ] ; then
    echo "Do not run this script as root"
    echo
    exit 1 #Exit with status 1
fi

#Allocate CPUs
total_system_cpus=$(grep ^cpu /proc/cpuinfo | wc -l) #Find the total number of cpus on the system

echo "Deending on your system configuration this program may take a long time to run. To reduce the run time, this program is able to utilize more than one of your systems cpus."
echo "Your sustem has $total_system_cpus cpus."
read -p "Enter the number of cpus you would like to allocate to this program: " allocated_cpus #User inputs the number of cpus they want the program to use

if [[ $allocated_cpus ]] && [ $allocated_cpus -eq $allocated_cpus 2>/dev/null ]; then #Check if the user input is an integer
	if [ $allocated_cpus -le $((total_system_cpus + 0)) ] && [ $allocated_cpus -gt 0 ]; then #Check if the number of cpus the user inputs is less than or equal to the total number of cpus on the system
		echo "Valid cpu allocation"

	else
		echo "The ammount of cpus you have entered exceeds the total number of cpus on your system or is less than or equal to 0 "
		exit 1
	fi
else
	echo "Please enter a valid integer"
	exit 1 #Exit with satus 1
fi

#Find System Distro
SYSTEM_DISTRO_RELEASE=$(cat /etc/os-release)

#Check if the system distro is supported
Distro="None"
SUPPORTED_DISTRO=false
for i in "Ubuntu" "ubuntu" "Debian" "debian" "CentOS" "centOS" "RHEL" "rhel" "Fedora" "fedora"
do
	if echo "$SYSTEM_DISTRO_RELEASE" | grep -q "$i"; then
		Distro="$i"
		SUPPORTED_DISTRO=true
		break
	else
		SUPPORTED_DISTRO=false
	fi
done


echo "---------------------------------------------------------------------------------------"
echo "The Machines Linux Distro is: $SUPPORTED_DISTRO"
echo "---------------------------------------------------------------------------------------"

FOR_USER_MANUAL_INSTALL=" " # packages that this program cannot download will be put into this list and reported to the user

#If the Machine's Linux Distro is not compatible add the following packages to the FOR_USER_MANUAL_INSTALL list
if [ "$SUPPORTED_DISTRO" = false ]; then
	echo "---------------------------------------------------------------------------------------"
	echo "The Linux Distro you are running is not supported by this program. To use the Ultravisor/op-Build install the packages listed at the end of this program."
	echo "---------------------------------------------------------------------------------------"
	FOR_USER_MANUAL_INSTALL+=",python 2.7"
	FOR_USER_MANUAL_INSTALL+=",gcc version 6.2 or newer"
	FOR_ISER_MANUAL_INSTALL+=",All other packages listed in the Ultravisor/op-build readme"
fi

#Find the installation operator for the system distro
INSTALLATION_OPERATOR=NONE
echo "---------------------------------------------------------------------------------------"
echo "The system Linux distro is $Distro"
echo "---------------------------------------------------------------------------------------"
if [ $Distro == "rhel" ] || [ $Distro == "CentOS" ] || [ $Distro == "Fedora" ] || [ $Distro == "RHEL" ] || [ $Distro == "centOS" ] || [ $Distro == "fedora" ]; then
	INSTALLATION_OPERATOR=yum;
elif [ $Distro == "Ubuntu" ] || [ $Distro == "Debian" ] || [ $Distro == "ubuntu" ] || [ $Distro == "debian" ]; then
	INSTALLATION_OPERATOR=apt-get;
else
	echo "---------------------------------------------------------------------------------------"
	echo "You dont have a supported distro";
	echo "---------------------------------------------------------------------------------------"
fi

echo "---------------------------------------------------------------------------------------"
echo "The installation operator for your system is $INSTALLATION_OPERATOR"
echo "---------------------------------------------------------------------------------------"

#Download Dependencies based on Linux Distro


if [ $Distro == "Ubuntu" ] || [ $Distro == "Debian" ] || [ $Distro == "ubuntu" ] || [ $Distro == "debian" ]; then
	Download_Ubuntu_And_Debian_Dependencies;
elif [ $Distro == "rhel" ] || [ $Distro == "CentOS" ] || [ $Distro == "Fedora" ] || [ $Distro == "RHEL" ] || [ $Distro == "centOS" ] || [ $Distro == "fedora" ]; then
	Download_Fedora_CentOS_And_Redhat_Dependencies;
else
	echo "---------------------------------------------------------------------------------------"
	echo "The system does not have a supported distro"
	echo "---------------------------------------------------------------------------------------"
fi

#Test gcc version and install a compatible version if nessisary

if Test_gcc_Version == 0; then
	echo "---------------------------------------------------------------------------------------"
	echo "gcc version is greater or equal to 6.2.0"
	echo "---------------------------------------------------------------------------------------"
else
	Install_compatible_gcc_version
	if Test_gcc_Version == 0; then
		FOR_USER_MANUAL_INSTALL+="gcc version 6.2 or above"
	fi
fi

#Test python version and install a compatible version if nessisary

if Test_python_Version == 0; then
	echo "---------------------------------------------------------------------------------------"
	echo "You have a compatible python version"
	echo "---------------------------------------------------------------------------------------"
else
	Install_compatible_python_version
	if Test_python_Version == 0; then
		FOR_USER_MANUAL_INSTALL+="python 2.7"
	fi
fi

#Check for ssh key
FILE=$HOME/.ssh/id_rsa.pub

echo "_________________________________________________________________________"
echo
echo "LOOKING IN $FILE FOR SSH KEY"
echo "_________________________________________________________________________"
echo
echo

if [ -f "$FILE" ]; then
	echo "**************************** SSH KEY EXISTS *****************************"
else
	echo "*********** SSH KEY DOES NOT EXIST. WE WILL CREATE ONE NOW :) ***********"
	echo
	echo "YOU CAN LOAD DEFAULTS BY PRESSING ENTER ON THE FOLLOWING PROMPTS"
	echo
	read -n 1 -s -r -p "Press any key to continue..."
	echo
	echo "_________________________________________________________________________"
	echo " "
	ssh-keygen -o
fi
echo
echo "_________________________________________________________________________"
echo
echo "SET UP GITHUB WITH THE SSH KEY ON THIS DEVICE"
echo "_________________________________________________________________________"
echo
echo "ON YOUR IBM GITHUB GO TO:"
echo "	SETTINGS -> SSH AND GPG KEYS -> NEW SSH KEY"
echo "	AND INSERT THE FOLLOWING KEY:"
echo
echo "_________________________________________________________________________"
echo
cat $FILE
echo "_________________________________________________________________________"

#List the dependencies the user will have to maunally install

echo "---------------------------------------------------------------------------------------"
echo "The user will need to download the following packages:"
for i in $(echo $FOR_USER_MANUAL_INSTALL | sed "s/,/ /g")
do
	echo "$i"
done
echo "---------------------------------------------------------------------------------------"

#Exit with status 0
exit 0
