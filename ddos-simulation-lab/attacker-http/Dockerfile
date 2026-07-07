attacker-http:
    image: williamyeh/wrk
    container_name: attacker-http
    networks:
      - wazuh-network
    cpus: "0.25"
    mem_limit: 128m
    entrypoint: ["sleep"]
    command: ["999999999"]
