FROM ghcr.io/digininja/dvwa:latest

RUN apt-get update -qq && \
    apt-get install -y curl gnupg && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main' > /etc/apt/sources.list.d/wazuh.list && \
    apt-get update -qq && \
    apt-get install -y wazuh-agent=4.10.0-1 && \
    sed -i 's/MANAGER_IP/WAZUH_MANAGER_PLACEHOLDER/' /var/ossec/etc/ossec.conf

COPY entrypoint-dvwa.sh /entrypoint-dvwa.sh
RUN chmod +x /entrypoint-dvwa.sh

ENTRYPOINT ["/entrypoint-dvwa.sh"]

# Add Apache log monitoring to Wazuh agent config
RUN echo '<ossec_config>\n  <localfile>\n    <log_format>apache</log_format>\n    <location>/var/log/apache2/access.log</location>\n  </localfile>\n</ossec_config>' >> /var/ossec/etc/ossec.conf

# Add Apache log monitoring to Wazuh agent config
RUN echo '<ossec_config>\n  <localfile>\n    <log_format>apache</log_format>\n    <location>/var/log/apache2/access.log</location>\n  </localfile>\n</ossec_config>' >> /var/ossec/etc/ossec.conf

# Redirect Apache logs to real files for Wazuh monitoring
RUN rm -f /var/log/apache2/access.log /var/log/apache2/error.log && \
    touch /var/log/apache2/access.log /var/log/apache2/error.log && \
    chown www-data:www-data /var/log/apache2/access.log /var/log/apache2/error.log && \
    sed -i 's|CustomLog \${APACHE_LOG_DIR}/access.log combined|CustomLog /var/log/apache2/access.log combined|g' /etc/apache2/sites-enabled/000-default.conf && \
    sed -i 's|ErrorLog \${APACHE_LOG_DIR}/error.log|ErrorLog /var/log/apache2/error.log|g' /etc/apache2/sites-enabled/000-default.conf

# Install Zabbix agent2
RUN curl -s https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian13_all.deb -o /tmp/zabbix-release.deb && \
    dpkg -i /tmp/zabbix-release.deb && \
    apt-get update -qq && \
    apt-get install -y zabbix-agent2 && \
    rm /tmp/zabbix-release.deb
