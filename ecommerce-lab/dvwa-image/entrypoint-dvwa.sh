#!/bin/bash
# Replace placeholder with actual manager IP at runtime
sed -i "s/WAZUH_MANAGER_PLACEHOLDER/${WAZUH_MANAGER:-172.19.0.10}/" /var/ossec/etc/ossec.conf

# Register with manager if not already registered
rm -f /var/ossec/etc/client.keys
if true; then
    /var/ossec/bin/agent-auth -m ${WAZUH_MANAGER:-172.19.0.10} -A dvwa-web
fi

# Start Zabbix agent
sed -i "s/^Server=127.0.0.1/Server=172.19.0.6/" /etc/zabbix/zabbix_agent2.conf
sed -i "s/^ServerActive=127.0.0.1/ServerActive=172.19.0.6/" /etc/zabbix/zabbix_agent2.conf
sed -i "s/^Hostname=Zabbix server/Hostname=dvwa-web/" /etc/zabbix/zabbix_agent2.conf
mkdir -p /run/zabbix && chown zabbix:zabbix /run/zabbix && zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf &

# Start Wazuh agent
/var/ossec/bin/wazuh-control start

# Start original DVWA entrypoint
exec docker-php-entrypoint apache2-foreground
