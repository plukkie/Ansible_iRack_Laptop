#!/bin/bash

##########################################################################
# This script enables all interfaces.
# LLDP will discover all neighbors and endpoints connected to the switch
##########################################################################

intstart="0"
intstop="47"
intstep="1"
intprefix="Ethernet"

# BEGIN CONSTANTS
username='admin'
password='YourPaSsWoRd'
scriptname="enable_interfaces.sh"
host="localhost"
# END CONSTANTS

for pid in $(pidof -x $scriptname);
  do
    if [ $pid != $$ ];
      then
        echo "[$(date)] : $scriptname : Process is already running with PID $pid"
        exit 1
    fi
done

# construct authentication credentials json
json="{ \"username\" : \"$username\", \"password\" : \"$password\" }"
# Authenticate to SONiC and receive JWT token
resp=`curl -s -k -X POST https://$host/authenticate -d "$json"`
# Substract access_token key value
token=`echo $resp |jq -r '.access_token'`

if [ ! -z "$token" ] #If there is a token received and thus not zero
  then

     authstring="Authorization: Bearer $token" # Construct json string for token auth
     json="{ \"openconfig-interfaces:config\" : { \"enabled\": true } }"

     for number in $(seq $intstart $intstop);
       do
         interface=$intprefix$number
         echo "* Enable interface $interface.."
         curl -s -k -X POST "https://$host/restconf/data/openconfig-interfaces:interfaces/interface=$interface" -H "accept: */*" -H "Content-Type: application/yang-data+json" -H "$authstring" -d "$json"
         sleep 0.3
      done
  else # API access to device failed
     echo -e "\nCan not get API access to $host\n"
fi

