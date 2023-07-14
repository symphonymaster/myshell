#!/bin/bash

##=======================================================================================================================================================================
##---Begin of Input Parameters---------#
##=======================================================================================================================================================================
trap "exit 1" TERM
export TOP_PID=$$
if [ "$#" -eq 28 ]; then
      run_prep_cluster=${1} ## preparation or cluster as drop down
      run_cluster_prep=${2}  ## yes or no if run_prep_custer is cluster, else pass as none
      reset_cluster_pass=${3} ## yes or no if run_cluster_prep is yes, else pass as none
      clusterpass=${4} ## password for the user hacluster, pass as none if reset_cluster_pass is no
      #### Start Below variables pass as none if run_prep_cluster is selected as preparation
      initcluster=${5} ## yes or no
      advancedmode=${6} ## yes or no
      ## Start below variables none if adavnced mode is no
      scs_fs_rsc=${7}
      ers_fs_rsc=${8}
      scs_hlth_rsc=${9}
      ers_hlth_rsc=${10}
      scs_vip_rsc=${11}
      ers_vip_rsc=${12}
      ## End above variables none if adavnced mode is no
      scs_ip_addr=${13}
      ers_ip_addr=${14}
      clustername=${15} ## Name of the cluster ex: ascsCluster or scscluster
      primaryvm=${16} ## VM Hostname
      secondaryvm=${17} ## VM Hostname
      primaryvm_vmname=${18}  #Instance ID of Node 1 
      secondaryvm_vmname=${19} #Instance ID of Node 2
      aws_region=${20} ## AWS region
      sid=${21}
      is_node1=${22} ## yes or no
      azfsurl=${23} ## EFS Endpoint URL
      cstype=${24} ## Drop down ASCS or SCS
      transdir=${25}
      ascs_inst_no=${26}
      ers_inst_no=${27}
      routing_table=${28}

else
        echo "Parameter missing"
        exit
fi   


sid=$(echo "$sid" | tr '[:upper:]' '[:lower:]')
cstype=$(echo "$cstype" | tr '[:upper:]' '[:lower:]')
CStype=$(echo "$cstype" | tr '[:lower:]' '[:upper:]')
SID=$(echo "$sid" | tr '[:lower:]' '[:upper:]')
ssh_enabled=$(echo "$ssh_enabled" | tr '[:upper:]' '[:lower:]')
advancedmode=$(echo "$advancedmode" | tr '[:upper:]' '[:lower:]')
hanasecondaryreadonly=$(echo "$hanasecondaryreadonly" | tr '[:upper:]' '[:lower:]')
initcluster=$(echo "$initcluster" | tr '[:upper:]' '[:lower:]')
run_prep_cluster=$(echo "$run_prep_cluster" | tr '[:upper:]' '[:lower:]')
run_cluster_prep=$(echo "$run_cluster_prep" | tr '[:upper:]' '[:lower:]')
reset_cluster_pass=$(echo "$reset_cluster_pass" | tr '[:upper:]' '[:lower:]')
is_node1=$(echo "$is_node1" | tr '[:upper:]' '[:lower:]')

if [[ "${advancedmode}" == "no" ]]; then
        #fencing_rsc_name_primary_vm="fencing_rsc_${primary_vm_name}" ## Fencing resource name in Primary vm ex: fencing_rsc_vm1 
        #fencing_rsc_name_secondary_vm="fencing_rsc_${secondary_vm_name}" ## Fencing resource name in secondary vm ex: fencing_rsc_vm2
        #fencing_location_name_primary_vm="fencing_rsc_lc_${primary_vm_name}" #ex: fencing_rsc_lc_vm1
        #fencing_location_name_secondary_vm="fencing_rsc_lc_${secondary_vm_name}" #ex: fencing_rsc_lc_vm2
        scs_file_system_rsc_name="${sid}_scs_fs_rsc_name" #ex: sid_scs_fs_rsc_name
        ers_file_system_rsc_name="${sid}_ers_fs_rsc_name" #ex: sid_ers_fs_rsc_name
        scs_health_check_rsc_name="${sid}_scs_hc_rsc_name"  #ex: sid_scs_hc_rsc_name
        ers_health_check_rsc_name="${sid}_ers_hc_rsc_name" #ex: sid_ers_hc_rsc_name
        scs_vip_rsc_name="${sid}_scs_vip_rsc_name"
        ers_vip_rsc_name="${sid}_ers_vip_rsc_name"
else
        scs_file_system_rsc_name="$scs_fs_rsc" #ex: sid_scs_fs_rsc_name, fs_$SID_ASCS --> Central service Fule system Resource name
        ers_file_system_rsc_name="$ers_fs_rsc" #ex: sid_ers_fs_rsc_name, fs_$SID_ERS --> Replication service File system Resource name
        scs_health_check_rsc_name="$scs_hlth_rsc"  #ex: sid_scs_hc_rsc_name, Central --> service Health Check Resource name
        ers_health_check_rsc_name="$ers_hlth_rsc" #ex: sid_ers_hc_rsc_name --> Replication service Health Check Resource name
        scs_vip_rsc_name="$scs_vip_rsc"  #ex:vip_  -->Central service Virtual IP Resource name
        ers_vip_rsc_name="$ers_vip_rsc"  ##  --> Replication service Virtual IP Resource name
fi

prep()
{
      ### Start of node 1 only
      # mount temporarily the volume
      if [[ "${is_node1}" == "yes" ]]; then
            if [ ! -d /sapmtmp ]; then
                  mkdir -p /saptmp
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p /saptmp, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi
            mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport "${azfsurl}":/ /saptmp
            if [ $? != 0 ]; then
                  echo " Error in mount -t nfs ${azfsurl}:/ /saptmp -o vers=4,minorversion=1,sec=sys, exiting"
                  kill -s TERM $TOP_PID
            fi
            # create the SAP directories
            
            cd /saptmp
            if [ ! -d sapmnt"${SID}" ]; then
                  mkdir -p sapmnt"${SID}"
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p sapmnt${SID}, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi
            if [  ! -d usrsap"${SID}""${cstype}" ]; then
                  mkdir -p usrsap"${SID}""${cstype}"
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p usrsap${SID}${cstype}, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi

            if [  ! -d usrsaptrans ]; then
                  mkdir -p usrsaptrans
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p usrsaptrans, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi
            if [  ! -d usrsap"${SID}"ers ]; then
                  mkdir -p usrsap"${SID}"ers
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p usrsap${SID}ers, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi
            if [  ! -d usrsap"${SID}"sys ]; then
                  mkdir -p usrsap"${SID}"sys
                  if [ $? != 0 ]; then
                        echo " Error in mkdir -p usrsap${SID}sys, exiting"
                        kill -s TERM $TOP_PID
                  fi
            fi

            # unmount the volume and delete the temporary directory
            cd ..
            umount /saptmp
            if [ $? != 0 ]; then
                  echo " Error in umount /saptmp, exiting"
                  kill -s TERM $TOP_PID
            fi
            rmdir /saptmp
            if [ $? != 0 ]; then
                  echo " Error in rmdir /saptmp, exiting"
                  kill -s TERM $TOP_PID
            fi

            ip address add "${scs_ip_addr}" dev eth0
      else
            
            ip address add "${ers_ip_addr}" dev eth0
      fi
      ### End of node 1 only

      ### Start of both nodes

      if [ ! -d /sapmnt/"${SID}" ]; then
            mkdir -p /sapmnt/"${SID}"
            if [ $? != 0 ]; then
                  echo " Error in mkdir /sapmnt/${SID}, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi
      chmod 777 /sapmnt/"${SID}"
      
      if [ ! -d "${transdir}" ]; then
            mkdir -p "${transdir}"
            if [ $? != 0 ]; then
                  echo " Error in mkdir ${transdir}, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi
      chmod 777 "${transdir}" 

      if [ ! -d /usr/sap/"${SID}"/SYS ]; then
            mkdir -p /usr/sap/"${SID}"/SYS
            if [ $? != 0 ]; then
                  echo " Error in mkdir /usr/sap/${SID}/SYS, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi
      chmod 777 /usr/sap/"${SID}"/SYS

      if [ ! -d /usr/sap/"${SID}"/"${CStype}""${ascs_inst_no}" ]; then
            mkdir -p /usr/sap/"${SID}"/"${CStype}""${ascs_inst_no}"
            if [ $? != 0 ]; then
                  echo " Error in mkdir /usr/sap/${SID}/${CStype}${ascs_inst_no}, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi
      chmod 777 /usr/sap/"${SID}"/"${CStype}""${ascs_inst_no}"
      if [ ! -d /usr/sap/"${SID}"/ERS"${ers_inst_no}" ]; then
            mkdir -p /usr/sap/"${SID}"/ERS"${ers_inst_no}"
            if [ $? != 0 ]; then
                  echo " Error in mkdir /usr/sap/${SID}/ERS${ers_inst_no}, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi
      chmod 777 /usr/sap/"${SID}"/ERS"${ers_inst_no}"
      
      chattr +i /sapmnt/"${SID}"
      if [ $? != 0 ]; then
            echo " Error in chattr +i /sapmnt/${SID}, exiting"
            kill -s TERM $TOP_PID
      fi
      chattr +i "${transdir}"
      if [ $? != 0 ]; then
            echo " Error in chattr +i ${transdir}, exiting"
            kill -s TERM $TOP_PID
      fi
      chattr +i /usr/sap/"${SID}"/SYS
      if [ $? != 0 ]; then
            echo " Error in chattr +i /usr/sap/${SID}/SYS, exiting"
            kill -s TERM $TOP_PID
      fi
      
      chattr +i /usr/sap/"${SID}"/"${CStype}""${ascs_inst_no}"
      if [ $? != 0 ]; then
            echo " Error in chattr +i /usr/sap/${SID}/${CStype}${ascs_inst_no}, exiting"
            kill -s TERM $TOP_PID
      fi
      chattr +i /usr/sap/"${SID}"/ERS"${ers_inst_no}"
      if [ $? != 0 ]; then
            echo " Error in chattr +i /usr/sap/${SID}/ERS${ers_inst_no}, exiting"
            kill -s TERM $TOP_PID
      fi


      cp /etc/fstab /etc/fstab_clu_bkp
      if [ $? != 0 ]; then
            echo " Error in backing up /etc/fstab, exiting"
            kill -s TERM $TOP_PID
      fi
      # Add the following lines to fstab, save and exit
      ret1=$(cat /etc/fstab |grep "${azfsurl}":/usrsaptrans)
      if [ -z "${ret1}" ]; then
            echo "${azfsurl}:/usrsaptrans ${transdir}  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
      else
            ret2=$(cat /etc/fstab |grep "${azfsurl}":/usrsaptrans |grep "${transdir}")
            if [ -z "${ret2}" ]; then
                  echo "${azfsurl}:/usrsaptrans ${transdir}  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
            else
                  ret_chk1=$(cat /etc/fstab |grep "${azfsurl}":/usrsaptrans |awk '{print $2}')
                  if [[ "${ret_chk1}" != "${transdir}" ]]; then
                        echo "File share ${azfsurl}:/usrsaptrans mounted for some other mount point other than ${transdir}. So exiting. Verify it manually"
                        kill -s TERM $TOP_PID
                  fi
                  
            fi
      fi
      ret3=$(cat /etc/fstab |grep "${azfsurl}":/sapmnt"${SID}")
      if [ -z "${ret3}" ]; then
            echo "${azfsurl}:/sapmnt${SID} /sapmnt/${SID}  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
      else
            ret4=$(cat /etc/fstab |grep "${azfsurl}":/sapmnt"${SID}" |grep /sapmnt/"${SID}")
            if [ -z "${ret4}" ]; then
                  echo "${azfsurl}:/sapmnt${SID} /sapmnt/${SID}  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
            else
                  ret_chk2=$(cat /etc/fstab |grep "${azfsurl}":/sapmnt"${SID}" |awk '{print $2}')
                  if [[ "${ret_chk2}" != "/sapmnt/${SID}" ]]; then
                        echo "File share ${azfsurl}:/sapmnt${SID} mounted for some other mount point other than /sapmnt/${SID}. So exiting. Verify it manually"
                        kill -s TERM $TOP_PID
                  fi
            fi
      fi

      ret5=$(cat /etc/fstab |grep "${azfsurl}":/usrsap"${SID}"sys)
      if [ -z "${ret5}" ]; then
            echo "${azfsurl}:/usrsap${SID}sys /usr/sap/${SID}/SYS  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
      else
            ret6=$(cat /etc/fstab |grep "${azfsurl}":/usrsap"${SID}"sys |grep /usr/sap/"${SID}"/SYS)
            if [ -z "${ret6}" ]; then
                  echo "${azfsurl}:/usrsap${SID}sys /usr/sap/${SID}/SYS  nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,sec=sys  0  0" >> /etc/fstab
            else
                  ret_chk3=$(cat /etc/fstab |grep "${azfsurl}":/usrsap"${SID}"sys |awk '{print $2}')
                  if [[ "${ret_chk3}" != "/usr/sap/${SID}/SYS" ]]; then
                        echo "File share ${azfsurl}:/usrsap${SID}sys mounted for some other mount point other than /usr/sap/${SID}/SYS. So exiting. Verify it manually"
                        kill -s TERM $TOP_PID
                  fi
            fi
      fi

      # Mount the file systems
      mount -a
      if [ $? == 0 ]; then
            echo "Preparation for cluster setup Finished"
      else
            echo " Error in mount -a, exiting"
            kill -s TERM $TOP_PID
      fi
}

cluster_prep()
{
      #sed -i '/ResourceDisk.EnableSwap=/c\ResourceDisk.EnableSwap=y' /etc/waagent.conf

      #sed -i '/ResourceDisk.SwapSizeMB=/c\ResourceDisk.SwapSizeMB=2000' /etc/waagent.conf

      if [[ "${reset_cluster_pass}" == "yes" ]]; then
            echo -e "${clusterpass}\n${clusterpass}" | passwd hacluster
            if [ $? != 0 ]; then
                  echo " Error in setting password for hacluster, exiting"
                  kill -s TERM $TOP_PID
            fi
      fi

      systemctl start pcsd.service
      if [ $? != 0 ]; then
            echo " Error in step17, exiting"
            kill -s TERM $TOP_PID
      fi
      systemctl enable pcsd.service
      if [ $? != 0 ]; then
            echo " Error in step18, exiting"
            kill -s TERM $TOP_PID
      fi
      systemctl status pcsd.service
      if [ $? != 0 ]; then
            echo " Error in step19, exiting"
            kill -s TERM $TOP_PID
      else
            echo "Cluster Preparation Finished"
      fi
      

      #service waagent restart
      #if [ $? != 0 ]; then
            #echo " Error in restarting waagent, exiting"
            #kill -s TERM $TOP_PID
      #fi

      
      ### End of both nodes

}

create_ascs_ers_resources_before_install()
{
      pcs resource create "${scs_file_system_rsc_name}" Filesystem device="${azfsurl}:/usrsap"${SID}""${cstype}"" \
      directory="/usr/sap/${SID}/${CStype}${ascs_inst_no}" fstype='nfs4' options='nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' force_unmount=safe \
      op start interval=0 timeout=60 op stop interval=0 timeout=60 op monitor interval=200 timeout=40 
      if [ $? != 0 ]; then
            echo " Error in creating resource ${scs_file_system_rsc_name}, exiting"
            kill -s TERM $TOP_PID
      fi

      pcs resource create "${scs_vip_rsc_name}" aws-vpc-move-ip ip="${scs_ip_addr}" interface=eth0 routing_table="${routing_table}"
      if [ $? != 0 ]; then
            echo " Error in creating resource ${scs_vip_rsc_name}, exiting"
            kill -s TERM $TOP_PID
      fi


      #pcs resource create "${scs_health_check_rsc_name}" azure-lb port="${scs_lb_port}" 
      #if [ $? != 0 ]; then
      #      echo " Error in creating resource ${scs_health_check_rsc_name}, exiting"
      #      kill -s TERM $TOP_PID
      #fi

      pcs resource group add g-"${SID}"_"${CStype}" "${scs_file_system_rsc_name}" "${scs_vip_rsc_name}" #"${scs_health_check_rsc_name}"
      if [ $? != 0 ]; then
            echo " Error in creating group g-${SID}_${CStype}, exiting"
            kill -s TERM $TOP_PID
      fi


      pcs resource create "${ers_file_system_rsc_name}" Filesystem device="${azfsurl}:/usrsap"${SID}"ers" \
      directory="/usr/sap/${SID}/ERS${ers_inst_no}" fstype='nfs4' options='nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' force_unmount=safe \
      op start interval=0 timeout=60 op stop interval=0 timeout=60 op monitor interval=200 timeout=40
      if [ $? != 0 ]; then
            echo " Error in creating resource ${ers_file_system_rsc_name}, exiting"
            kill -s TERM $TOP_PID
      fi

      pcs resource create "${ers_vip_rsc_name}" aws-vpc-move-ip ip="${ers_ip_addr}" interface=eth0 routing_table="${routing_table}"
      if [ $? != 0 ]; then
            echo " Error in creating resource ${ers_vip_rsc_name}, exiting"
            kill -s TERM $TOP_PID
      fi

      #pcs resource create "${ers_health_check_rsc_name}" azure-lb port="${ers_lb_port}"
      #if [ $? != 0 ]; then
      #      echo " Error in creating resource ${ers_health_check_rsc_name}, exiting"
      #      kill -s TERM $TOP_PID
      #fi

      pcs resource group add g-"${SID}"_ERS "${ers_file_system_rsc_name}" "${ers_vip_rsc_name}" #"${ers_health_check_rsc_name}"
      if [ $? != 0 ]; then
            echo " Error in creating group g-${SID}_ERS, exiting"
            kill -s TERM $TOP_PID
      fi


      val=$(pcs status |grep "${scs_file_system_rsc_name}" |awk '{print $5}' )
        if [ "${val}" != "${primaryvm}" ]; then
                if ! pcs resource move "${scs_file_system_rsc_name}" "${primaryvm}"; then
                        echo "Error in pcs resource move ${scs_file_system_rsc_name} ${primaryvm}"
                        kill -s TERM $TOP_PID
                fi
        fi


        #val=$(pcs status |grep "${scs_health_check_rsc_name}" |awk '{print $5}' )
        #if [ "${val}" != "${primaryvm}" ]; then
                #if ! pcs resource move "${scs_health_check_rsc_name}" "${primaryvm}"; then
                        #echo "Error in pcs resource move ${scs_health_check_rsc_name} ${primaryvm}"
                        #kill -s TERM $TOP_PID
                #fi
        #fi
      sleep 15
      val=$(pcs status |grep "${scs_vip_rsc_name}" |awk '{print $5}' )
        if [ "${val}" != "${primaryvm}" ]; then
                if ! pcs resource move "${scs_vip_rsc_name}" "${primaryvm}"; then
                        echo "Error in pcs resource move ${scs_vip_rsc_name} ${primaryvm}"
                        kill -s TERM $TOP_PID
                fi
        fi
      sleep 15  
      val=$(pcs status |grep "${ers_file_system_rsc_name}" |awk '{print $5}' )
        if [ "${val}" != "${secondaryvm}" ]; then
                if ! pcs resource move "${ers_file_system_rsc_name}" "${secondaryvm}"; then
                        echo "Error in pcs resource move ${ers_file_system_rsc_name} ${secondaryvm}"
                        kill -s TERM $TOP_PID
                fi
        fi

        #val=$(pcs status |grep "${ers_health_check_rsc_name}" |awk '{print $5}' )
        #if [ "${val}" != "${secondaryvm}" ]; then
                #if ! pcs resource move "${ers_health_check_rsc_name}" "${secondaryvm}"; then
                        #echo "Error in pcs resource move ${ers_health_check_rsc_name} ${secondaryvm}"
                        #kill -s TERM $TOP_PID
                #fi
        #fi
        sleep 15
        val=$(pcs status |grep "${ers_vip_rsc_name}" |awk '{print $5}' )
        if [ "${val}" != "${secondaryvm}" ]; then
                if ! pcs resource move "${ers_vip_rsc_name}" "${secondaryvm}"; then
                        echo "Error in pcs resource move ${ers_vip_rsc_name} ${secondaryvm}"
                        kill -s TERM $TOP_PID
                else
                        echo "cluster Initialization Finished"
                fi
      else
            echo "cluster Initialization Finished"
      fi 

}

enable_firewall()
{
      ## Start of Both Nodes

      
      firewall-cmd --add-service=high-availability --permanent
      if [ $? != 0 ]; then
            echo " Error in step3, exiting"
            kill -s TERM $TOP_PID
      fi
      firewall-cmd --permanent --add-service=high-availability
      if [ $? != 0 ]; then
            echo " Error in step4, exiting"
            kill -s TERM $TOP_PID
      fi
      firewall-cmd --reload
      if [ $? != 0 ]; then
            echo " Error in step5, exiting"
            kill -s TERM $TOP_PID
      fi
}

initalize_cluster()
{
      
      
            
      ## End of Both Nodes


      ## Start of Node 1
      if [[ "${is_node1}" == "yes" ]]; then      
            major_rel8=$(cat /etc/redhat-release |awk '{print $6}' | awk -F "." '{print $1}')
            major_rel7=$(cat /etc/redhat-release |awk '{print $7}' | awk -F "." '{print $1}')
            if [ "${major_rel8}" -eq 8 ]; then
                  echo -e "hacluster\n${clusterpass}" | pcs host auth "${primaryvm}" "${secondaryvm}"
                  if [ $? != 0 ]; then
                        echo " Error in step28, exiting"
                        kill -s TERM $TOP_PID
                  fi
                  pcs cluster setup "${clustername}" "${primaryvm}" "${secondaryvm}" totem token=30000 --force
                  if [ $? != 0 ]; then
                        echo " Error in step29, exiting"
                        kill -s TERM $TOP_PID
                  fi
            elif [ "${major_rel7}" -eq 7 ]; then
                  echo -e "hacluster\n${clusterpass}" | pcs cluster auth "${primaryvm}" "${secondaryvm}"
                  if [ $? != 0 ]; then
                        echo " Error in step28, exiting"
                        kill -s TERM $TOP_PID
                  fi
                  pcs cluster setup --name "${clustername}" "${primaryvm}" "${secondaryvm}" --token=30000 --force
                  if [ $? != 0 ]; then
                        echo " Error in step29, exiting"
                        kill -s TERM $TOP_PID
                  fi
            else
                  echo " This script is only for RHEL 7 or 8, exiting"
                  kill -s TERM $TOP_PID

            fi
            sleep 10
            pcs cluster start --all
            if [ $? != 0 ]; then
                  echo " Error in step30, exiting"
                  kill -s TERM $TOP_PID
            fi


            sleep 60
            
            pcs quorum expected-votes 2

            pcs property set concurrent-fencing=true
            if [ $? != 0 ]; then
                  echo " Error in step31, exiting"
                  kill -s TERM $TOP_PID
            fi

            ##$primaryvm is hostname of node1 & primaryvm_vmname is the vmname of the primary vm in azure portal
            pcs stonith create rsc_st_aws fence_aws region="${aws_region}" \
            pcmk_host_map="${primaryvm}:${primaryvm_vmname};${secondaryvm}:${secondaryvm_vmname}" \
            power_timeout=240 pcmk_reboot_timeout=480 pcmk_reboot_retries=4 
            if [ $? != 0 ]; then
                  echo " Error in step32, exiting"
                  kill -s TERM $TOP_PID
            fi

            pcs property set stonith-enabled="true"
            if [ $? != 0 ]; then
                  echo " Error in step33, exiting"
                  kill -s TERM $TOP_PID
            fi
            pcs property set stonith-timeout=600
            if [ $? != 0 ]; then
                  echo " Error in step34, exiting"
                  kill -s TERM $TOP_PID
            fi

            pcs resource defaults resource-stickiness=1

            pcs resource defaults migration-threshold=3

            ## End of Node 1
      fi
     
}

if [[ "${run_prep_cluster}" == "preparation" ]]; then
      prep
elif [[ "${run_prep_cluster}" == "cluster" ]]; then
      if [[ "${run_cluster_prep}" == "yes" ]]; then
            cluster_prep
      else
            #enable_firewall
            if [[ "${initcluster}" == "yes" ]]; then
                  initalize_cluster
            fi
            create_ascs_ers_resources_before_install
      fi
fi