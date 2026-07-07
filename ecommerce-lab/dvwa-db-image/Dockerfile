FROM mysql:8.0

RUN microdnf install -y curl && \
    rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH && \
    echo '[wazuh]' > /etc/yum.repos.d/wazuh.repo && \
    echo 'gpgcheck=1' >> /etc/yum.repos.d/wazuh.repo && \
    echo 'gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH' >> /etc/yum.repos.d/wazuh.repo && \
    echo 'enabled=1' >> /etc/yum.repos.d/wazuh.repo && \
    echo 'name=EL-$releasever - Wazuh' >> /etc/yum.repos.d/wazuh.repo && \
    echo 'baseurl=https://packages.wazuh.com/4.x/yum/' >> /etc/yum.repos.d/wazuh.repo && \
    echo 'protect=1' >> /etc/yum.repos.d/wazuh.repo && \
    microdnf install -y wazuh-agent-4.10.0-1

COPY entrypoint-db.sh /entrypoint-db.sh
RUN chmod +x /entrypoint-db.sh

ENTRYPOINT ["/entrypoint-db.sh"]
CMD ["mysqld"]
