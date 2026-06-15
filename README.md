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

## 🏗️ Pipeline Architecture

\`\`\`text
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
\`\`\`

## 💻 Pinned Agent Image Blueprint (`Dockerfile`)
The monitored asset was built using a custom image blueprint designed to embed security compliance sensors directly into the baseline operating system.

Dockerfile
FROM debian:bookworm-slim

# 1. Install production web application server dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    gnupg \
    procps \
    && rm -rf /var/lib/apt/lists/*

# 2. Establish the SIEM repository channel and verify GPG keys
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# 3. Deploy the endpoint sensor, strictly pinning the version for manager compatibility
RUN apt-get update && apt-get install -y wazuh-agent=4.10.0-1

# 4. Automate sensor network routing configurations to point to the central manager
RUN sed -i 's/<address>MANAGER_IP<\/address>/<address>wazuh.manager<\/address>/g' /var/ossec/etc/ossec.conf

EXPOSE 80

# 5. Initialize the endpoint runtime loop alongside the web daemon
CMD service wazuh-agent start && apache2ctl -D FOREGROUND
⚡ Attack Simulation & Telemetry Lifecycle
1. Exploit Payload Execution
A malicious web vector was simulated using a targeted HTTP request. The payload executes a Directory Traversal Attack, attempting to use relative tracking paths (../) to climb out of the web document root and access sensitive system files (/etc/passwd).

Bash
curl -G "http://localhost:8080/index.html" --data-urlencode "file=../../../../etc/passwd"
2. Log Generation & Parsing Logic
The Apache application layer committed the transactional event metadata directly to disk at /var/log/apache2/access.log. The background wazuh-agent immediately tokenized the new log string, shipped it over an encrypted TLS channel to the manager, and triggered an exact regular expression lookup match for Rule 31103:

XML
<!-- Core SIEM Engine Matching Logic -->
<rule id="31103" level="7">
  <if_sid>31101</if_sid>
  <regex>\.\./\.\./\.\./\.\./etc/passwd</regex>
  <description>Web server rules - Directory traversal attempt</description>
</rule>
🛠️ Linux Systems Engineering & Troubleshooting Victories
Building a security lab on a modern Linux workstation introduces strict platform constraints. This project successfully navigated and resolved several core system collisions:

Package Pining Resolution: Overcame an initial agent deployment failure by diagnosing an upstream version mismatch between the web repository and the cluster baseline, resolved by enforcing strict software point-release constraints (wazuh-agent=4.10.0-1).

SELinux Resource Optimization: Resolved a severe desktop resource bottleneck where Fedora's D-Bus activated setroubleshootd daemon flooded the system with GUI alerts during container database operations. Mitigated the CPU spike completely by tracking down the policy loop, updating directory contexts to container_file_t, and masking the alert service to restore system performance.

Persistent Cache Management: Fixed a transient backend API link crash caused by corrupt, half-written configuration state files within persistent Docker volumes by orchestrating a granular volume prune loop (docker compose down -v).

🚀 How to Run the Lab

1. Boot the Core SIEM Stack
Bash
cd wazuh-images/single-node
docker compose up -d

3. Spin Up the Corporate Target Asset
Bash
docker run -d \
  --name enterprise-webserver \
  --network single-node_default \
  -p 8080:80 \
  vulnerable-apache

5. Graceful Lab Teardown
Bash
docker rm -f enterprise-webserver
docker compose down
                                                           
