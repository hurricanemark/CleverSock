#! /bin/bash
#-------------------------------------------------------
# Applied Expert Systems, Inc.
#-------------------------------------------------------
# Main installation script provided for installing
# CleverView for TCP/IP on Linux targeting SLES 
#-------------------------------------------------------
# DO NOT MODIFY!  DO NOT MODIFY!  DO NOT MODIFY!  
#-------------------------------------------------------

function getdversion
{
   # Determine the Linux distribution and version that is being run.
   #
   # Check for GNU/Linux distributions
   if [ -f /etc/SuSE-release ]; then
       DISTRIBUTION="suse"
   elif [ -f /etc/UnitedLinux-release ]; then
       DISTRIBUTION="united"
  elif [ -f /etc/debian_version ]; then
      DISTRIBUTION="debian"
  elif [ -f /etc/redhat-release ]; then
      a=`grep -i 'red.*hat.*enterprise.*linux' /etc/redhat-release`
      if test $? = 0; then
         DISTRIBUTION=rhel
      else
         a=`grep -i 'red.*hat.*linux' /etc/redhat-release`
         if test $? = 0; then
             DISTRIBUTION=rh
         else
             a=`grep -i 'cern.*e.*linux' /etc/redhat-release`
             if test $? = 0; then
                DISTRIBUTION=cel
             else
                a=`grep -i 'scientific linux cern' /etc/redhat-release`
                if test $? = 0; then
                   DISTRIBUTION=slc
                else
                   DISTRIBUTION="unknown"
                fi
             fi
         fi
      fi
  else
     DISTRIBUTION="unknown"
  fi

  # VERSION=`rpm -q redhat-release | sed -e 's#redhat[-]release[-]##'`

  case ${DISTRIBUTION} in
  rh|cel|rhel)
      VERSION=`cat /etc/redhat-release | sed -e 's#[^0-9]##g' -e 's#7[0-2]#73#'`
      ;;
  slc)
      VERSION=`cat /etc/redhat-release | sed -e 's#[^0-9]##g' | cut -c1`
      ;;
  debian)
      VERSION=`cat /etc/debian_version`
      if [ ${VERSION} = "testing/unstable" ]; then
          # The debian testing/unstable version must be translated into
          # a numeric version number, but no number makes sense so just
          # remove the version all together.
          VERSION=""
      fi
      ;;
  suse)
      VERSION=`cat /etc/SuSE-release | grep 'VERSION' | sed  -e 's#[^0-9]##g'`
      ;;
  united)
      VERSION=`cat /etc/UnitedLinux-release`
      ;;
  *)
      VERSION='00'
      ;;
  esac;
  echo "${DISTRIBUTION}${VERSION}"
}

function getIPaddress()
{
#    OUTPUT=`/sbin/ip -4 addr | grep 'inet' | grep -v 'inet6' | grep -v '127.0.0.1' | sed 's/inet*//g' | awk '// {print $1}' | head -c-4`
    OUTPUT=`/sbin/ifconfig -a | grep 'inet' | grep -v 'inet6' | grep -v '127.0.0.1' | sed 's/://g' | sed 's/inet//g' | sed 's/addr//g' | awk '{print $1}'`
    if [[  ${#OUTPUT[@]} -eq 0 ]]; then
        echo "We could not find any IPv4 address for this system.  Installation aborted."
        exit 1;
    else
        IDX=1;
        for item in ${OUTPUT[@]}; do
            IFS=' ';
            _IPS[$IDX]=$item;
            let IDX=(IDX+1);
        done

        if [[ $IDX -gt 2 ]]; then
            index=1
            for item in ${_IPS[@]} ; do
               echo "$index)  $item"
               index=$(expr $index + 1)
            done
            echo -n "Select index of ip address to be used as licensed monitor IP: "
            read ItemIndex
            #echo "You selected ${_IPS[@]:$ItemIndex:1}"
            MYIPADDR=${_IPS[@]:$ItemIndex:1}
        else
            MYIPADDR=${_IPS[@]:0:1}
        fi
        unset _IPS;
        unset OUTPUT;
    fi
}
export -f getIPaddress




CURDIR=`pwd`
INSTALLDIR="/usr/share/cv4linux"
RELOCATE=0
TMPDIR="/tmp/tmpcv-retro"
MYIPADDR=`/sbin/ip -4 addr | awk '/inet/ && !/127.0.0/ {print $2}' | rev | cut -c4- | rev`
PRECONDITION=`rpm -q cv4tcpipl`
TARGET="x86_64"
FILENAME="cv4tcpipl-3.0-1.0.$TARGET.SLES.rpm"
#cv4tcpipl-3.0-1.0.x86_64.SLES.rpm

#getIPaddress

ARCHITECTURE=`arch`
if [ "$ARCHITECTURE" = "$TARGET" ]; then
    echo
    echo "Welcome to CleverView(R) for TCP/IP on Linux"
    echo
else
    echo
    echo "W A R N I N G"
    echo "Incorrect package for intended SLES x86_64 architecture."
    echo "This system is not a 64-bit machine."
    echo
    echo "`lsb_release -a`"
    echo
    echo "Please contact software publisher (support@aesclever.com) for correct installation package."
    echo "Or check online availability at http://www.aesclever.com/aftp/.linux3.0/RPM/SLES/x86_64/"
    echo
    echo "Installation terminated."
    exit 1;
fi


INSTALLDIR="/usr/share"
echo
echo "Install target directory is set to: $INSTALLDIR"

#
# setenv (root) for cv4tcpipl package
#
touch ~/.bash_profile >> /dev/null 2>&1
if test -e i~/.bash_profile; then
  echo "CV4_HOME=$INSTALLDIR" >> ~/.bash_profile
  echo "export CV4_HOME" >> ~/.bash_profile
  echo "PATH=$PATH:$INSTALLDIR" ~/.bash_profile
  echo "export PATH" >> ~/.bash_profile
fi
#
# setenv bash (root) for cv4tcpipl package
#
touch /etc/bash.bashrc >> /dev/null 2>&1
if test -e /etc/profile.local; then
  echo "CV4_HOME=$INSTALLDIR" >> /etc/bash.bashrc
  echo "export CV4_HOME" >> /etc/bash.bashrc
  echo "PATH=$PATH:$INSTALLDIR" >> /etc/bash.bashrc
  echo "export PATH" >> /etc/bash.bashrc
fi
ldconfig >> /dev/null 2>&1

echo
echo
echo "-------- A U T O M A T I C   I N S T A L L A T I O N ---------"
echo " This installation package will only work for SLES.x $TARGET. "
echo
echo 
echo "** M A K I N G   D E P O S I T O R Y **"
echo -n "1.  Creating a temporary depository at "
if [ -d $TMPDIR ]; then
   rm -rf $TMPDIR
   mkdir $TMPDIR
else
   mkdir $TMPDIR
fi

echo
echo
# check error 
if [ -e $FILENAME ]; then
    echo
    echo "Welcome to CleverView for TCP/IP on Linux."
    echo "This setup will attempt to install and configure the said"
    echo "software on your `uname -n`."
    echo
else
    echo "Error installing the package.  Script terminated."
    echo "Expected install package ($FILENAME) is not found in current directory $(pwd)."
    echo "Setup aborted."
    exit 0;
fi
echo
echo
echo "** P R E C H E C K S **"
echo -n "1. Verifying for system compatibility... "
if [ $? -ne 0 ]; then
   uname -a
fi
echo
echo -n "2. Preserve existing license and external configuration if any... "
if [ -e /etc/cv4env.conf ]; then
    LAST_INSTALLDIR=`cat /etc/cv4env.conf`
   
    if [ -e $LAST_INSTALLDIR/cv4linux/license.txt ]; then
        cp $LAST_INSTALLDIR/cv4linux/license.txt $TMPDIR/license.txt
    fi
    if [ -e $LAST_INSTALLDIR/cv4linux/xfilters.cfg ]; then
        cp $LAST_INSTALLDIR/cv4linux/xfilters.cfg $TMPDIR/xfilters.cfg
    fi
    if [ -e $LAST_INSTALLDIR/cv4linux/notification.cfg ]; then
        cp $LAST_INSTALLDIR/cv4linux/notification.cfg $TMPDIR/notification.cfg
    fi
    if [ -e $LAST_INSTALLDIR/cv4linux/mobile.cfg ]; then
        cp $LAST_INSTALLDIR/cv4linux/mobile.cfg $TMPDIR/mobile.cfg
    fi
fi
echo "Done."
echo -n "3.  Attempting to uninstall cv4tcpipl package, if any...:"
rpm -e cv4tcpipl >> /dev/null 2>&1
sleep 1
echo "... Done."
echo "4.  Installing new cv4tcpipl package:"
DVER=`getdversion`
#if [ "$DVER" = "rhel60" -o "$DVER" = "rhel61" -o "$DVER" = "rhel62" -o "$DVER" = "rhel63" -o "$DVER" = "rhel64"]; then
case "$DVER" in
    "rhel60"|"rhel61"|"rhel63"|"rhel64")
        rpm -ivh --nodeps $FILENAME
        # Update contents of /etc/cv4env.conf
        INSTALLDIR="/usr/share"
        echo "Sorry.  Due to environment restriction on x64 $DVER, package relocation is not possible."
        echo "Your package will be installed onto $INSTALLDIR instead."
        echo "/usr/share/cv4linux" > /etc/cv4env.conf

        #cp -f $INSTALLDIR/cv4linux/cv4rtdaemon-el6 /usr/sbin/cv4rtdaemon
        #cp -f $INSTALLDIR/cv4linux/cv4monwrapper-el6 /usr/sbin/cv4monwrapper
    ;;
    *)
        if [ "$RELOCATE" = "1" -a getdversion != "rhel60" ]; then
            rpm -ivh --nodeps --relocate /usr/share=$INSTALLDIR $FILENAME
        else
            rpm -ivh --nodeps $FILENAME
        fi
        # Update contents of /etc/cv4env.conf
        echo "$INSTALLDIR/cv4linux" > /etc/cv4env.conf
    ;;
esac
sleep 1
echo
echo
echo "** C O N F I G U R E  **"
echo "5.  Configuring cv4tcpipl..."
PATH=$PATH:$INSTALLDIR
export PATH
sync

# Attempt to wake up neccessary services
/sbin/service mysqld restart >> /dev/null 2>&1
/sbin/service snmpd restart >> /dev/null 2>&1
/sbin/service postfix restart >> /dev/null 2>&1
/sbin/iptables -I INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT >> /dev/null 2>&1
/sbin/iptables -I INPUT -i eth0 -p tcp --dport 6680 -j ACCEPT >> /dev/null 2>&1
/sbin/iptables -I INPUT -i eth0 -p tcp --dport 6688 -j ACCEPT >> /dev/null 2>&1
/sbin/iptables -I INPUT -i eth0 -p tcp --dport 6689 -j ACCEPT >> /dev/null 2>&1
/sbin/iptables -I INPUT -i eth0 -p tcp --dport 3306 -j ACCEPT >> /dev/null 2>&1

source ~/.bash_profile >> /dev/null 2>&1

# Restore found license
if [ -e $TMPDIR/license.txt ]; then
    cp $TMPDIR/license.txt $INSTALLDIR/cv4linux/license.txt
fi
if [ -e $TMPDIR/notification.cfg ]; then
    yes | cp -f $TMPDIR/notification.cfg $INSTALLDIR/cv4linux/notification.cfg
fi
if [ -e $TMPDIR/mobile.cfg ]; then
    yes | cp -f $TMPDIR/mobile.cfg $INSTALLDIR/cv4linux/mobile.cfg
fi
if [ -e $TMPDIR/xfilters.cfg ]; then
    yes | cp -f $TMPDIR/xfilters.cfg $INSTALLDIR/cv4linux/xfilters.cfg
else
    echo "5;$MYIPADDR;mysqld;master;snmpd;init" >> $INSTALLDIR/cv4linux/xfilters.cfg
fi

bash $(cat /etc/cv4env.conf)/configure.sh

cd $CURRDIR
rm -rf $TMPDIR >> /dev/null 2>&1

echo
echo
echo "------------------------------------------------------------------"
echo "Configuration complete."
echo
echo "To start using CleverView for TCP/IP on Linux - Web Report, just point"
echo "your web browser to http://$MYIPADDR:8080/TcpipLinux"
echo 
echo "Please consult the user guide for more information"
echo
echo
echo "To verify if your Tomcat server is active, point your web browser to"
echo "http://$MYIPADDR:8080"
echo
echo
echo "Thank you for choosing CleverView for TCP/IP on Linux"
echo

exit 0
