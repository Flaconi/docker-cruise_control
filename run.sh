#!/usr/bin/env bash

set -e
set -u


###
### update /cc/config/capacity.json
###
if [ "${BROKER_CAPACITY:-}" != "" ]; then
	get_broker_json() {
		BROKER_NUM="$( echo "${BROKER_CAPACITY}" | grep -o ',' | grep -c ',' )"
		BROKER_NUM=$(( BROKER_NUM + 1 ))

		BROKER_CAPACITY="${BROKER_CAPACITY// /}"
		BROKER_CAPACITY="${BROKER_CAPACITY//,/ }"
		index=0

		echo "{"
		echo "  \"brokerCapacities\": ["
		for line in ${BROKER_CAPACITY}; do
			index=$(( index + 1 ))
			bid="$(    echo "${line}" | awk -F':' '{print $1}' )"
			bdisk="$(  echo "${line}" | awk -F':' '{print $2}' )"
			bcpu="$(   echo "${line}" | awk -F':' '{print $3}' )"
			bnwin="$(  echo "${line}" | awk -F':' '{print $4}' )"
			bnwout="$( echo "${line}" | awk -F':' '{print $5}' )"

			echo "    {"
			echo "      \"brokderId\": \"${bid}\","
			echo "      \"capacity\": {"
			echo "        \"DISK\":   \"${bdisk}\","
			echo "        \"CPU\":    \"${bcpu}\","
			echo "        \"NW_IN\":  \"${bnwin}\","
			echo "        \"NW_OUT\": \"${bnwout}\""
			echo "      },"
			echo "      \"doc\": \"This overrides the capacity for broker ${bid}.\""
			if [ "${index}" -eq "${BROKER_NUM}" ]; then
				echo "    }"
			else
				echo "    },"
			fi
		done
		echo "  ]"
		echo "}"
	}
	get_broker_json > /cc/config/capacity.json
	cat /cc/config/capacity.json
fi


###
### update /cc/config/cruisecontrol.properties
###
if [ "${BOOTSTRAP_SERVERS:-}" != "" ]; then
	sed -i'' "s/^bootstrap.servers=.*/bootstrap.servers==${BOOTSTRAP_SERVERS}/g" /cc/config/cruisecontrol.properties
	grep -E '^bootstrap\.servers=' /cc/config/cruisecontrol.properties
fi


###
### create /cc/cruisecontrol-ui/config.csv
###
if [ "${UI_ENV:-}" == "" ]; then
	UI_ENV="default"
fi
echo "${UI_ENV},${UI_ENV},/kafkacruisecontrol/" > /cc/cruise-control-ui/config.csv


###
### RUN
###
PORT="${1:-9090}"
exec /cc/kafka-cruise-control-start.sh /cc/config/cruisecontrol.properties "${PORT}"