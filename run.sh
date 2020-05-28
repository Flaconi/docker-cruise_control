#!/bin/sh

set -e
set -u

PORT="${1:-8080}"
exec /cc/kafka-cruise-control-start.sh /etc/cruise-control/cruisecontrol.properties "${PORT}"
