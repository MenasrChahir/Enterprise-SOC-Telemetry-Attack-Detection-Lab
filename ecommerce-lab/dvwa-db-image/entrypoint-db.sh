#!/bin/bash
# Replace placeholder with actual manager IP
sed -i "s/MANAGER_IP/${WAZUH_MANAGER:-172.19.0.10}/" /var/ossec/etc/ossec.conf 2>/dev/null || true

# Register with manager if not already registered
rm -f /var/ossec/etc/client.keys
if true; then
    /var/ossec/bin/agent-auth -m ${WAZUH_MANAGER:-172.19.0.10} -A dvwa-db 2>/dev/null || true
fi

# Start Wazuh agent in background
/var/ossec/bin/wazuh-agentd -f &

# Start original MySQL entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"
