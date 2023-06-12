#!/bin/bash

# SET HERE TFTP SERVER IP ADDRESS
TFTPSERVER="10.10.10.201"

LOCALCONFIGFILE=/etc/sonic/config_db.json
HASHALG=sha256sum
STOREDHASHFILE=/tmp/config_db.json.${HASHALG}
UPLOADPATH=/sonic/config/
FILEPREFIX="${HOSTNAME}"
FILESUFFIX="_config_gns3.json"
SAVEDCONFIGFILE=${FILEPREFIX}${FILESUFFIX}

if [ ! -f "${STOREDHASHFILE}" ]
   then
      ${HASHALG} ${LOCALCONFIGFILE} | awk '{print $1'} > ${STOREDHASHFILE}
fi

OLDHASH=`cat ${STOREDHASHFILE}`
NEWHASH=`${HASHALG} ${LOCALCONFIGFILE} | awk '{print $1'}`

if [ "${NEWHASH}" != "${OLDHASH}" ]
   then
      echo "Config has changed, need to upload new config to server."
      if curl -k --interface eth0 -T ${LOCALCONFIGFILE} tftp://${TFTPSERVER}${UPLOADPATH}${SAVEDCONFIGFILE}
	 then 
            echo ${NEWHASH} > ${STOREDHASHFILE}
	    echo "Succesfull upload"
	 else
            echo "Error uploading file"
      fi
   else
      echo "Config has not changed. Do nothing till next check."
fi

