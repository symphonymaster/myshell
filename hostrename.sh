#!/bin/bash
# --- Exit trap --- #
trap "exit 1" TERM
export TOP_PID=$$
#------------------------------------------------- Input definition for Host rename ------------------------------------------------------#
if [ "$#" -eq 2 ];then
    newhostname=$1       #new hostname to be changed
    script_dir="${2}/hostrename"        #script dir where to be executed
else
    echo "parameter missing"
    exit
fi

#----------------------------------------------- Log file Generation ---------------------------------------------------------------------#
log()
{
  echo "${functionCode}:${returnMessage}" >> "$script_dir/hostrename.log"
}

#------------------------------------------------------ Print result ---------------------------------------------------------------------#
printresult()
{
  echo  "+-----------------------------------------------------------------------------+"
  echo  "| Date/Time : $(date)" | awk '{print $0 substr("",1,78-length($0)) "|"}'
  echo  " ${functionName} - ${returnMessage}"
  echo  "+-----------------------------------------------------------------------------+"
}

#------------------------------------------- Initialize script directory -----------------------------------------------------------------#
initialize_scriptdir()
{
    functionName="Initializing Script Directory"
    functionCode="INIT_SCRIPT_DIRECTORY"
    if [ ! -d "$script_dir" ]; then
        echo " $script_dir does not exist"
        echo "creating $script_dir"
        mkdir -p "$script_dir"
        if [ $? == 0 ]; then
            returnMessage="Success"
            echo " script directory created "
            printresult functionName returnMessage
        else
            returnMessage="Failed"
            echo " Failed to create script directory "
            printresult functionName returnMessage
            kill -s TERM $TOP_PID
        fi
    else
        echo " directory exist"
        echo "removing the $script_dir"
        rm -R "$script_dir"
        echo "creating a new $script_dir"
        mkdir -p "$script_dir"
        if [ $? == 0 ]; then
            returnMessage="Success"
            printresult functionName returnMessage
            echo " Script directory created "
        else
            returnMessage="Failed"
            printresult functionName returnMessage
            echo " Error in creating script directory "

            kill -s TERM $TOP_PID
        fi
    fi
}

#----------------------------------------------------- Renaming Host ---------------------------------------------------------------------#
host_rename()
{
        functionName="Host Rename"
        functionCode="Host_rename"
        sudo hostnamectl set-hostname $newhostname
        check=$(hostname)
    if [ "${check}" == ${newhostname} ]; then
        echo " Host rename change successfull "
        returnMessage="Success"
        printresult functionName returnMessage
        log functionCode returnMessage
    else
        returnMessage="Failed"
        printresult functionName returnMessage
        log functionCode returnMessage
        echo " Host rename operation failed "
        kill -s TERM $TOP_PID
    fi
}
    #function used
        initialize_scriptdir
        host_rename
