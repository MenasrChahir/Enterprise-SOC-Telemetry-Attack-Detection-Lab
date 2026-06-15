# Enterprise-SOC-Telemetry-Attack-Detection-Lab
This project demonstrates end-to-end security telemetry engineering: capturing raw application transactional logs, streaming them securely via an embedded endpoint sensor, parsing the data streams against programmatic signature patterns, and visualizing high-severity threats in a central SIEM interface.
## 🎯 Project Objective

The core objective of this project is to model how modern enterprise environments achieve visibility over distributed infrastructure during an active cyber attack. 

This lab fulfills four critical security engineering milestones:
* **Telemetry Generation:** Provisioning a dynamic web service application layer that generates continuous transactional access logs.
* **Sensor Decoupling:** Embedding an active endpoint monitor daemon directly inside the target asset to act as an on-host intrusion detection system (HIDS).
* **Automated Normalization:** Routing raw unstructured log strings into a centralized parsing engine that normalizes data schemas.
* **Threat Analytics & Rule Validation:** Triggering high-severity analytics alerts by matching real-time attack payloads against strict pattern-matching signatures.

---

## 🏗️ Pipeline Architecture

```text
[ Threat Actor ] 
       │ (Malicious HTTP Injection)
       ▼
[ Target Web Server (Apache) ] ──► [ Local Access Log File ]
                                             │ (Continuous Monitoring)
                                             ▼
                                  [ Wazuh Agent Sensor ]
                                             │ (TLS Encrypted Stream)
                                             ▼
                                  [ Central Wazuh Manager ] ──► [ Rule Engine Match ]
                                                                        │
                                                                        ▼
                                                             [ Indexer Database ]
                                                                        │
                                                                        ▼
                                                             [ Dashboard web UI ]


                                                           
💻 The Pinned Agent Image Blueprint (Dockerfile)
The targeted asset was compiled from a modular blueprint designed to bake security compliance agents directly into the baseline operating system.

Dockerfile
FROM debian:bookworm-slim

# 1. Install production web application server dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Cryptographically verify and establish the SIEM repository channel
RUN curl -s [https://packages.wazuh.com/key/GPG-KEY-WAZUH](https://packages.wazuh.com/key/GPG-KEY-WAZUH) | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] [https://packages.wazuh.com/4.x/apt/](https://packages.wazuh.com/4.x/apt/) stable main" | tee /etc/apt/sources.list.d/wazuh.list

# 3. Deploy the endpoint sensor, strictly pinning the package version for compatibility
RUN apt-get update && apt-get install -y wazuh-agent=4.10.0-1

# 4. Automate sensor network routing configurations to point to the central SIEM manager
RUN sed -i 's/<address>MANAGER_IP<\/address>/<address>wazuh.manager<\/address>/g' /var/ossec/etc/ossec.conf

EXPOSE 80

# 5. Initialize the endpoint runtime loop alongside the web daemon
CMD service wazuh-agent start && apache2ctl -D FOREGROUND
⚡ Attack Simulation & Telemetry Lifecycle
1. The Exploit Payload Execution
To test the detection engine, a malicious web vector was simulated using a targeted HTTP request. The payload explicitly executes a Directory Traversal Attack, attempting to climb out of the restricted web document root through relative tracking paths (../) to read sensitive configuration indices (/etc/passwd).

Bash
curl -G "http://localhost:8080/index.html" --data-urlencode "file=../../../../etc/passwd"
2. The Unstructured Log Capture
The Apache layer handled the query string and committed the raw transactional event metadata directly to the tracking disk at /var/log/apache2/access.log:

Plaintext
172.18.0.1 - - [13/Jun/2026:13:34:17 +0000] "GET /index.html?file=../../../../etc/passwd HTTP/1.1" 200 11025
3. Central Rule Engine Processing
The embedded wazuh-agent immediately read the updated log line, tokenized the attributes, and shipped it to the centralized engine. The text string passed through the analysis pipeline and triggered an exact regular expression lookup match for Rule 31103:

XML
<!-- Underlying Core Logic Evaluation -->
<rule id="31103" level="7">
  <if_sid>31101</if_sid>
  <regex>\.\./\.\./\.\./\.\./etc/passwd</regex>
  <description>Web server rules - Directory traversal attempt</description>
</rule>
🚀 How to Run the Lab
1. Bring the Core SIEM Stack Online
Bash
cd wazuh-images/single-node
docker compose up -d
2. Deploy the Monitored Corporate Target
Bash
docker run -d \
  --name enterprise-webserver \
  --network single-node_default \
  -p 8080:80 \
  vulnerable-apache
3. Verify Alert Generation
Access the UI Command Center at https://localhost:443

Execute the attack simulation curl sequence from your terminal.

Monitor real-time Level 7 true-positive detections inside the Threat Hunting -> Events portal.

4. Clean Shutdown
Bash
docker rm -f enterprise-webserver
docker compose down
