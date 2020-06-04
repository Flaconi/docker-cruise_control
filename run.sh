#!/usr/bin/env bash

set -e
set -u


###
### update /cc/config/capacity.json
###
if [ "${BROKER_CAPACITY:-}" != "" ]; then
	get_broker_json() {
		BROKER_NUM="$( echo "${BROKER_CAPACITY}" | grep -o ',' | grep -c ','  || true )"
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
			echo "      \"brokerId\": \"${bid}\","
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
	sed -i'' "s|^capacity.config.file=.*|capacity.config.file=config/capacity.json|g" /cc/config/cruisecontrol.properties
	grep -E '^capacity.config.file=' /cc/config/cruisecontrol.properties
fi


###
### update /cc/config/cruisecontrol.properties
###
if [ "${BOOTSTRAP_SERVERS:-}" != "" ]; then
	sed -i'' "s/^bootstrap.servers=.*/bootstrap.servers=${BOOTSTRAP_SERVERS}/g" /cc/config/cruisecontrol.properties
	grep -E '^bootstrap\.servers=' /cc/config/cruisecontrol.properties
fi
if [ "${ZOOKEEPER_CONNECT:-}" != "" ]; then
	sed -i'' "s/^zookeeper.connect=.*/zookeeper.connect=${ZOOKEEPER_CONNECT}/g" /cc/config/cruisecontrol.properties
	grep -E '^zookeeper\.connect=' /cc/config/cruisecontrol.properties
fi
if [ "${TWO_STEP_VERIFICATION:-}" = "1" ]; then
	sed -i'' "s/^two.step.verification.enabled=.*/two.step.verification.enabled=true/g" /cc/config/cruisecontrol.properties
	grep -E '^two.step\.verification\.enabled=' /cc/config/cruisecontrol.properties
fi


###
### overwrite /cc/config/clusterConfigs.json
###
if  [ "${MIN_ISR:-}" != "" ]; then
	{
		echo "{";
		echo "  \"min.insync.replicas\": ${MIN_ISR},";
		echo "  \"an.example.cluster.config\": true";
		echo "}";
	} > /cc/config/clusterConfigs.json
fi


###
### create /cc/cruisecontrol-ui/static/config.csv
###
if [ "${UI_KEY:-}" == "" ]; then
	UI_KEY="environment"
fi
if [ "${UI_VAL:-}" == "" ]; then
	UI_VAL="default"
fi
echo "${UI_KEY},${UI_VAL},/kafkacruisecontrol/" > /cc/cruise-control-ui/static/config.csv


###
### RUN
###
PORT="${1:-9090}"
exec /cc/kafka-cruise-control-start.sh /cc/config/cruisecontrol.properties "${PORT}"
