#!/bin/bash
/var/ossec/bin/wazuh-agentd &
exec docker-entrypoint.sh "$@"
