#!/bin/bash

# Script to find bad ram according to ECC errors in the system logfiles and generate appropriate memmap arguments to give to the kernel at boot time
# Copyright Colin Sauze/Aberystwyth University 2018
# This software is licensed under the MIT License, see the attached file LICENSE for full terms.


#get the list of bad addresses from the logs, sort the numerically
sudo cat /var/log/messages* | grep "CE ERROR_ADDRESS" | cut -b 69- | sort | uniq > /tmp/bad_addr 

last_addr=0 
i=0
j=-1

#loop through all the bad addresses
for line in `cat bad_addr` ; do 
    addr=$((16#$line)) #convert to decimal
    megaddr=$[$addr/1048576] #convert to megabytes

    #only output when its been 100M since the last error
    if [ "$addr" -gt "$[$last_addr+100000000]" ] ; then 

        #store the ending address of the previous block
        if [ "$last_addr" -ne "0" ] ; then 
            end[j]=$[$last_addr/1048576]
        fi

        #store the starting address
        start[i]=$megaddr
        i=$[$i+1]
        j=$[$j+1]
    fi
    last_addr=$addr
done
end[j]=$[$last_addr/1048576]


#produce output in the format needed by the kernel, add this as a boot parameter to grub/syslinux
for k in `seq 0 $[$i-1]` ; do


    e=${end[$k]}
    s=${start[$k]}
    len=$[($e-$s)+1]
    echo "memmap=$len\$$s"

done
