#!/bin/bash
###########################################################################
ZTD_SERVER_IP="10.10.10.201"
TFTP_SERVER_IP="10.10.10.201"
ZTD_PATH=/tftpboot
CALLBACK=/callback
STAGING_FINISHED=/ztp_finished
ADDON_SCRIPTS_PATH=/tftpboot/sonic/postscript_addons/
SAVE_CONFIG_FILE=save_config.sh
ADMIN_HOME=/home/admin/
CGI=/cgi-bin/callback.sh
APP=http://
CRONLINE=${ADMIN_HOME}${SAVE_CONFIG_FILE}
CRONROOT=/var/spool/cron/crontabs/root
USER_NAME=admin
PASSWORD=YourPaSsWoRd
PASSWORDLIST=( "${PASSWORD}" "admin" "admin123" "Password01" "Password01!" )
MAC=`ip link show eth0 | grep ether | awk '{print $2}' | tr : _`
###########################################################################
# Request callback script at http server (cgi-script)
# This creates a file with name <ip-address> and hostname on the server
/usr/bin/curl -s ${APP}${ZTD_SERVER_IP}${CGI} && sleep 2

## Extract the ip-address that was received from dhcp server
DHCP_IP=`hostname -I | awk '{printf $1}'`

# Fetch switch hostname
SWITCHNAME=`/usr/bin/curl ${APP}${ZTD_SERVER_IP}${ZTD_PATH}${CALLBACK}/${DHCP_IP}` && sleep 2

# Check if switchname was found on webserver and received
if [ -z "${SWITCHNAME}" ] || [ "${SWITCHNAME}" = '' ]
        then
                SWITCHNAME="SONiC-ztp-miss-hostname-catch" #Callback script malfunctioning
fi

echo "Found desired hostname: $SWITCHNAME"

CURRENTHOSTNAME=`hostname`
echo "current hostname: ${CURRENTHOSTNAME}"

# set hostname via localhost REST call
for ITEM in ${PASSWORDLIST[@]}; do
        curl -s -k -X PATCH "https://localhost/restconf/data/openconfig-system:system/config/hostname" -H "accept: */*" -H "Content-Type: application/yang-data+json" -u ${USER_NAME}:${ITEM} -d "{\"openconfig-system:hostname\":\"$SWITCHNAME\"}"
done

sleep 2

# get save_config.sh addon script and add to crontab
/usr/bin/curl -s ${APP}${ZTD_SERVER_IP}${ADDON_SCRIPTS_PATH}${SAVE_CONFIG_FILE} -o ${ADMIN_HOME}${SAVE_CONFIG_FILE}
sleep 2
chmod a+x ${ADMIN_HOME}${SAVE_CONFIG_FILE}

# Check if save_config script present in crontab
if [[ ! -f "${CRONROOT}" ]]; then touch ${CRONROOT}; fi

if ! grep -q "${CRONLINE}" "${CRONROOT}"; then
   echo "* * * * * sudo $CRONLINE" >> ${CRONROOT}
fi

# Save config permanent
config save -y

#Upload ZTP staging complete file to web server
ZTPFINISHFILE=`echo ${DHCP_IP}`.ztp.finished
echo $SWITCHNAME > ${ZTPFINISHFILE}
curl -T ${ZTPFINISHFILE} tftp://${TFTP_SERVER_IP}${STAGING_FINISHED}/${ZTPFINISHFILE}

