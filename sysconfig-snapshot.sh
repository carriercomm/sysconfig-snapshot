#!/bin/sh - 
#
# Platform : Linux
#
# Purpose : Capture the state of the system configuration for later
# troubleshooting in the event of system problems. The given data will be stored
# in the file defined in $SYSCONFIGFILE variable.
#
# Usage :
#       sysconfig-snapshot.sh [--output file] [--verbose] [--help] [--version] 
#                                       

#Variables definition

PROGRAM=$(basename $0) 
VERSION=0.1 
VERBOSE=false
CURRENTHOST=$(hostname) 
DATETIME=$(date +%m%d%y_%H%M%S) 
SYSCONFIGFILE=$HOME/snapshot.$CURRENTHOST.$DATETIME

#Functions definition 

error() 
{
   echo "$@" 1>&2 
   usage_and_exit 1 
}

usage() 
{  
   echo "Usage: $PROGRAM [--output file] [--verbose] [--help] [--version]"
         
}

usage_and_exit() 
{ 
   usage 
   exit $1 
}

version() 
{ 
   echo "$PROGRAM version $VERSION" 
}

get_os() 
{ 
   uname -rs 
}

get_distro()
{
   cat /etc/*-release | 
     grep PRETTY |
        cut -d = -f 2 |
           tr -d '"'
}

get_arch()
{
   uname -m
}

get_timezone() 
{ 
   date +'%z %Z' 
}

get_cpu_info() 
{ 
   lscpu 
}

get_real_mem() 
{ 
   free -h | 
      grep Mem |
         awk \
            '{ printf("Total : %s\nUsed : %s\nFree: %s\n", $2,$3, $4)}' 
}

get_swap() 
{ 
   free -h | 
      grep Swap |
         awk \
            '{ printf("Total : %s\nUsed : %s\nFree: %s\n", $2,$3, $4)}' 
}

get_dmi_table() 
{ 
   dmidecode -q 
}

get_pci_list() 
{ 
   lspci -v 
}

get_long_dev_list()
{
   ls -l /dev
}

get_block_dev_list()
{
   lsblk -i
}

get_partition_table()
{
   fdisk -l
}

get_fs_stats()
{
   df -k 
   echo "\n"
   mount
}

get_ifaces_list()
{
   ifconfig -s
}

get_route_table()
{
   route -n
}

get_ps_list()
{
   ps aux
}

#Report generator function

generate_report()
{
   echo "\n\n $PROGRAM ($VERSION) - $(date) \n\n"
   echo "\n###############################################################\n"
   echo "\tGENERAL:"
   echo "\n###############################################################\n"
   echo "#Hostname:\t\t$CURRENTHOST"
   echo "#Time Zone:\t\t$(get_timezone)"
   echo "#Machine Architecture:\t$(get_arch)"
   echo "#Operating System:\t$(get_os)"
   echo "#Distribution:\t\t$(get_distro)"
   echo "\n###############################################################\n"
   echo "\tHARDWARE:"
   echo "\n###############################################################\n"
   echo "#CPU:\n\n$(get_cpu_info)\n" 
   echo "#Physical Memory:\n\n$(get_real_mem)\n" 
   echo "#Swap Memory:\n\n$(get_swap)\n" 
   echo "#DMI table:\n\n$(get_dmi_table)\n" 
   echo "#PCI devices list:\n\n$(get_pci_list)\n" 
   echo "#Device directory list - /dev:\n\n$(get_long_dev_list)\n" 
   echo "\n###############################################################\n"
   echo "\tFILE SYSTEM:"
   echo "\n###############################################################\n"
   echo "#Block devices list:\n\n$(get_block_dev_list)\n" 
   echo "#Partition table:\n$(get_partition_table)\n" 
   echo "#File system stats:\n\n$(get_fs_stats)\n" 
   echo "\n###############################################################\n"
   echo "\tNETWORKING:"
   echo "\n###############################################################\n"
   echo "#Interfaces list:\n\n$(get_ifaces_list)\n" 
   echo "#IP routing table:\n\n$(get_route_table)\n" 
   echo "\n###############################################################\n"
   echo "\tPROCESSES:"
   echo "\n###############################################################\n"
   echo "#Process list:\n\n$(get_ps_list)\n" 
}

#Command-line argument parser

while test $# -gt 0 
do 
   case $1 in 
   --output | -o )
      shift
      SYSCONFIGFILE=$1 
      ;;
   --verbose | -v )
      VERBOSE=true 
      ;;
   --help | -h ) 
      usage_and_exit 0 
      ;;
   --version | -V ) 
      version 
      exit 0 
      ;; 
   -*) 
      error "Unrecognized option: $1" 
      ;; 
   *) 
      break 
      ;;
   esac 
   shift
done

#Main section

if [ $(uname -s) != 'Linux' ]
then 
   echo "\n Error : This shell script is written exclusively for Linux OS.\n"
   exit 1
fi

if [ $VERBOSE = true ] 
then
   generate_report | tee -a $SYSCONFIGFILE  
else
   generate_report > $SYSCONFIGFILE 2> /dev/null 
fi

if [ -e $SYSCONFIGFILE ]
then
   echo "\nThis report is successfully saved in : $SYSCONFIGFILE\n"
   exit 0
fi
