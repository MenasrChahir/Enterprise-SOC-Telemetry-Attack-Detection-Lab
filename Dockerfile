FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg

RUN echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# PIN THE VERSION: Force apt to pull exactly version 4.10.0
RUN apt-get update && apt-get install -y wazuh-agent=4.10.0-1

RUN sed -i 's/<address>MANAGER_IP<\/address>/<address>wazuh.manager<\/address>/g' /var/ossec/etc/ossec.conf

EXPOSE 80

CMD service wazuh-agent start && apache2ctl -D FOREGROUND
