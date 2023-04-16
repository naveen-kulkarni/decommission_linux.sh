

#!/bin/bash
#########################################################################################
#Name    :  decom.sh                                                                        #
#Owner   :  root                                                                        #
#Date    :  16-06-2020                                                                  #
#Version :  1                                                                           #
#Author  :  naveenvk88@gmail.com                                                     #
#Permission : 750                                                                       #
#Purpose :  Clean up process for decommissioning the servers.                                               #
#########################################################################################

                RHOSTNAME="$(uname -n|awk -F "." '{print $1}')"
                #HOSTIP=$(hostname -i)
                HOSTIP=$(ip -o addr | awk '!/^[0-9]*: ?lo|link/ {print $2" "$4}')
                NFS_EXPORT=/etc/exports
                DBSERVICES=$(ps -ef | grep -i pmon|grep -v grep|wc -l)
                DBSERVICES_PRESENT=$(ps -ef | grep -i pmon|grep -v grep|awk '{print $8}')
                #NFSHARE=$(df -Pht nfs|grep -i "$RHOSTNAME" |awk '{print $1}'|wc -l )
                SRVC_SSSD=sssd
                #STOP_SSSD=$(systemctl stop sssd)
                #DISABLE_SSSD=$(systemctl disable sssd)
                #LEAVE_SSSD=$(realm leave cenovus.com)
                SRVC_QUEST=quest
                #LEAVE_QUEST=$(opt/quest/bin/vastool -u s_unixauth unjoin)
                SUDOERSCONF=/etc/sudoers
                DBLOG=$PWD/db-$RHOSTNAME-log
                NFSLOG=$PWD/nfs-$RHOSTNAME-log
                EXPORTLOG=$PWD/exportnfs-$RHOSTNAME-log
                IPLOG=$PWD/ipaddrs-$RHOSTNAME-log
                LINUXLOG=$PWD/linuxlog-$RHOSTNAME-log
                MAILDETAILS=$PWD/maildetails-$RHOSTNAME-log
                OSCOMPLOG=$PWD/oscomp-$RHOSTNAME-log


osComponents()
{
red=`tput setaf 1`
green=`tput setaf 2`
endColor=`tput sgr0`
DATE=$(date)
hostname=$(hostname -f)
kernel=$(uname -r)
diskSpace=$(df -h)
cpuTotal=$(cat /proc/cpuinfo |grep -i processor |wc -l)
serUptime=$(uptime )
swapDisk=$(swapon -s )
memInfo=$(free -g )
IP=$(ifconfig)
NFS_EXPORTS=$(cat /etc/exports)
DBSERVICE=$(ps -ef | grep -i pmon|grep -v grep)

sosComp=("$DATE" "$hostname" "$kernel" "$diskSpace" "$cpuTotal" "$serUptime" "$swapDisk" "$memInfo" "$IP" "$NFS_EXPORTS" "$DBSERVICE")
compName=(Date HostName Kernel Disk-Space CPU-Total Uptime Swap-Disk  Memory IP-Address NFS-EXPORT DB-Instances)
osComp=("$DATE" "$hostname")
#length=${#osComp[@]}

sosComp=("${sosComp[@]}" )

for (( i = 0; i < ${#sosComp[@]} ; i++ )); do
    printf "\n**** Running: ${compName[$i]} *****\n"
   # echo "${sosComp[$i]}"
    echo "${green} ${sosComp[$i]} ${endColor}"

done
}

rhel7() {

echo "RHEL 7 is running"
 ##systemctl status sssd
############ Un-commnet below ################
                systemctl stop sssd;
                systemctl disable sssd;
                realm leave cenovus.com;

}

rhel56() {

echo "RHEL5/6 is running"

############ Un-commnet below ################
        /etc/init.d/sssd stop
        chkconfig  $SRVC_SSSD off
        realm leave cenovus.com;
}
mainfunct () {
##1. Configure server to not auto-boot (if accidentallypowered on).

        echo "================================================"
        grep -i 'id:0' /etc/inittab     &>/dev/null
        if [ $? -eq 0 ]
        then
                echo "Auto-boot already set to false:"
                grep -i 'id:0' /etc/inittab
        else
                echo "Auto-boot set to false"
                echo "id:0:initdefault:" >>/etc/inittab
                grep -i 'id:0' /etc/inittab
        fi


##2.Verify network/SAN filesystems to be removed.
        IFS=$'\n';
        echo "================================================"
        #df -Pht nfs |grep -i $RHOSTNAME|awk '{print $1}' &>/dev/null
        ###################Kindly uncommnet the commented NFSHARE variable and vice-versa for actual run#####################
        #NFSHARE=$(df -Pht nfs|grep -i "$RHOSTNAME" |awk '{print $1}'|wc -l )
        NFSHARE=$(df -Pht nfs |grep -v Filesystem|awk '{print $1}'|wc -l)
        if [ $NFSHARE > 0 ]
        then
                echo "NFS shares are:"
                #####################uncommnet the commented one and commnet the uncommneted ######################
                df -Pht nfs |grep -i "$RHOSTNAME" |awk '{print $1}'|tee -a nfs-$RHOSTNAME-log
                #df -Pht nfs |grep -v Filesystem|awk '{print $1}' |tee -a $NFSLOG
        else
                echo "No NFS shares:"
        fi


###############3.List all IP addresses to be released.
        echo "================================================"
        echo "IP address to relase--->$RHOSTNAME : $HOSTIP" |tee -a $IPLOG


#######4.Ensure no NFS shares exported from this system.
        IFS=$'\n';
        echo "================================================"
        if [ -s "NFS_EXPORT" ]
        then
                echo "Exported shares:"
                exportfs -av |tee -a $EXPORTLOG
        else
                echo "No NFS shares exported:"
        fi

##############6.Confirm any databases are stopped.
        IFS=$'\n';
        echo "================================================"
        if  [ $DBSERVICES -gt 0 ]
        then
                echo "Database instances are running:"
                echo $DBSERVICES_PRESENT |tee -a $DBLOG
        else
                echo "No databases running:"
        fi

####12.De-register server from AD

        echo "================================================"
#################For testing. Can be commneted at actual run####################
#SERVICE_TYPE=(quest sssd)
#for srvc in "${SERVICE_TYPE[@]}"
 #do

#       srvcount=$(ps -ef | grep -i $srvc |grep -v grep|wc -l)
#       if [ $srvcount -gt 0 ]
#               then
#                       echo "$srvc is running"
#                       echo "Unjoining..."
#               systemct status sssd
                #systemctl stop sssd;
                #systemctl disable sssd;
                #realm leave cenovus.com;
#       fi
#done
                ###############################Dont run now###

               SRV_SSSDCOUNT=$(ps -ef | grep -i $SRVC_SSSD |grep -v grep|wc -l)
               SRV_VASDCOUNT=$(ps -ef | grep -i $SRVC_QUEST |grep -v grep|wc -l)
               rhel=$(sed -rn 's/.*([0-9])\.[0-9].*/\1/p' /etc/redhat-release)

                if [ $SRV_SSSDCOUNT -gt 0 ]
                then
                        if [[ "$rhel" -eq 7 ]]
                        then
                         rhel7
                        echo "$SRVC_SSSD is running. Unjoining..."
                else
                        rhel56
                        fi
                fi
                #service sssd status


                ##systemctl status sssd
                #systemctl stop sssd;
                #systemctl disable sssd;
                #realm leave cenovus.com;

                #               $STOP_SSSD
                #               $DISABLE_SSSD
                #               $LEAVE_SSSD
                #fi
                #else
                #SRV_VASDCOUNT=$(ps -ef | grep -i $SRVC_QUEST |grep -v grep|wc -l)
                if [ $SRV_VASDCOUNT -gt 0 ]
                then
                echo "$SRVC_QUEST  is running. Unjoining..."
                /opt/quest/bin/vastool -u s_unixauth -w Fall2013 unjoin;
                ##/opt/quest/bin/vastool status
                #$LEAVE_QUEST
                fi


#########13.Remove host from sudoers configuration.

        #echo "================================================"
        # grep $RHOSTNAME $SUDOERSCONF &>/dev/null
         #if [ $? -eq 0 ]
         #then
        #       echo "Kindly raise a RFC to remove the $RHOSTNAME:"
        # else
        #       echo "$RHOSTNAME not exists in sudoers"
         #fi
###########################################################
}


#sh $PWD/dcom.sh |tee -a $LINUXLOG
funcmailinfo() {

if [ -f $IPLOG ]
  then
        if [ -s $IPLOG ]
        then
                #Mail to DB team
                echo "Please engage AD team release the IP"
                cat $IPLOG
        else
                echo " "
        fi
  else
        echo " "
fi



if [ -f $DBLOG ]
  then
        if [ -s $DBLOG ]
        then
                #Mail to DB team
                echo "Please engage DB team as DB instance are running"
                cat $DBLOG
        else
                echo " "
        fi
  else
        echo " "
fi

if [ -f $NFSLOG ]
  then
        if [ -s $NFSLOG ]
        then
                #Mail to storage team
                echo "Plesae engage Storage team to remove the below volumes"
                cat $NFSLOG
        else
                echo " "
        fi
  else
        echo " "
fi


if [ -f $EXPORTLOG ]
  then
        if [ -s $EXPORTLOG ]
        then
                #Mail to storage team
                echo "Please engage Storage team as below volumes are exporting "
                cat $EXPORTLOG
        else
                echo " "
        fi
  else
        echo " "
fi
}
osComponents > $OSCOMPLOG
mainfunct  |tee -a $LINUXLOG
funcmailinfo > $MAILDETAILS
mutt  naveenvk88@gmail.com -s "$1 Decomission of server $RHOSTNAME $(date +"%F")" < $MAILDETAILS


