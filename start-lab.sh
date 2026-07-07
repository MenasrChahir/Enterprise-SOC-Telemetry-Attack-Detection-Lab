#!/bin/bash
echo "[1/6] Setting SELinux to permissive..."
sudo setenforce 0

echo "[2/6] Starting Wazuh stack..."
cd ~/enterprise-soc-lab/wazuh-images/single-node
docker compose up -d
echo "Waiting 30s for Wazuh to initialize..."
sleep 30

echo "[3/6] Starting ecommerce lab..."
cd ~/enterprise-soc-lab/ecommerce-lab
docker compose up -d
echo "Waiting 20s for agents to register..."
sleep 20

echo "[4/6] Starting Zabbix..."
cd ~/enterprise-soc-lab/zabbix-lab
docker compose up -d

echo "[5/6] Re-adding Apache log monitoring..."
docker exec dvwa bash -c "
  grep -q 'access.log' /var/ossec/etc/ossec.conf || \
  cat >> /var/ossec/etc/ossec.conf << 'CONF'
<ossec_config>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>
</ossec_config>
CONF
  /var/ossec/bin/wazuh-control restart
" 2>/dev/null

echo "[6/6] Checking status..."
docker exec single-node-wazuh.manager-1 /var/ossec/bin/agent_control -l
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -v "^NAMES"

echo ""
echo "Lab ready."
echo "  Wazuh    : https://localhost:443  (admin / SecretPassword)"
echo "  DVWA     : http://localhost:8080  (admin / password)"
echo "  Zabbix   : http://localhost:8090  (Admin / zabbix)"
