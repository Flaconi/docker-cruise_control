# -------------------------------------------------------------------------------------------------
# BUILDER IMAGE
# -------------------------------------------------------------------------------------------------
FROM openjdk:8-jdk-alpine as builder
ARG VERSION="latest"

###
### Dependencies
###
RUN apk add --no-cache \
	curl \
	git

###
### Download
###
RUN set -eux \
	&& if [ "${VERSION}" = "latest" ]; then \
			DATA="$( \
				curl -sS https://github.com/linkedin/cruise-control/releases \
				| tac \
				| tac \
				| grep -Eo 'href=".+[.0-9]+\.tar.gz"' \
				| awk -F'"' '{print $2}' \
				| sort -u \
				| tail -1 \
			)"; \
			echo "${DATA}"; \
			VERSION="$( echo "${DATA}" | grep -Eo '[.0-9]+[0-9]' )"; \
		fi \
	&& echo "${VERSION}" \
	&& echo "${VERSION}" > /VERSION \
	&& curl -sSL "https://github.com/linkedin/cruise-control/archive/${VERSION}.tar.gz" > /tmp/cc.tar.gz

###
### Extract
###
RUN set -eux \
	&& cd /tmp \
	&& tar xzvf cc.tar.gz \
	&& mv /tmp/cruise-control-* /tmp/cruise-control

###
### Setup git user and init repo
###
RUN set -eux \
	&& cd /tmp/cruise-control \
	&& git config --global user.email root@localhost \
	&& git config --global user.name root \
	&& git init \
	&& git add . \
	&& git commit -m "Init local repo." \
	&& git tag -a ${VERSION} -m "Init local version."

###
### Install dependencies
###
RUN set -eux \
	&& cd /tmp/cruise-control \
	&& ./gradlew jar \
	&& ./gradlew jar copyDependantLibs

###
### Download UI
###
RUN set -eux \
	&& UI="$( \
		curl -sSL https://github.com/linkedin/cruise-control-ui/releases/latest \
			| grep -Eo '".+cruise-control-ui-[.0-9]+.tar.gz"'\
			| sed 's/"//g' \
		)" \
	&& curl -sL "https://github.com${UI}" > /tmp/cc-ui.tar.gz \
	&& cd /tmp \
	&& tar xvfz cc-ui.tar.gz

###
### Setup dist
###
RUN set -eux \
	&& mkdir -p /cc/cruise-control/build \
	&& mkdir -p /cc/cruise-control-core/build \
	&& cp -a /tmp/cruise-control/cruise-control/build/dependant-libs /cc/cruise-control/build/ \
	&& cp -a /tmp/cruise-control/cruise-control/build/libs /cc/cruise-control/build/ \
	&& cp -a /tmp/cruise-control/cruise-control-core/build/libs /cc/cruise-control-core/build/ \
	&& cp -a /tmp/cruise-control/config /cc/ \
	&& cp -a /tmp/cruise-control/kafka-cruise-control-start.sh /cc/ \
	&& cp -a /tmp/cruise-control-ui/dist /cc/cruise-control-ui \
	&& find /cc/ -name '*.csv' -print0 | xargs -0 -n1 rm -f \
	&& find /cc/ -name '*.txt' -print0 | xargs -0 -n1 rm -f

###
### Copy out Kafka CruiseControlMetricsReporter
###
### This will be extracted to the git repository (outside the docker container)
### to be used with Kafka. See Makefile for how the actual build is done.
###
#RUN set -eux \
#	&& VERSION="$( cat /VERSION )" \
#	&& ls -lap /tmp/cruise-control/cruise-control-metrics-reporter/build/libs/ \
#	&& cp /tmp/cruise-control/cruise-control-metrics-reporter/build/libs/cruise-control-metrics-reporter-${VERSION}.jar /


# -------------------------------------------------------------------------------------------------
# PRODUCTION IMAGE
# -------------------------------------------------------------------------------------------------
FROM openjdk:8-jdk-alpine as production

###
### Install requirements
###
RUN set -eux && apk add --no-cache bash

###
### Copy files
###
COPY --from=builder /cc /cc
COPY --from=builder /VERSION /VERSION
COPY run.sh /run.sh

###
### Adjust paths
###
RUN set -eux \
	&&	sed -i'' \
		's|^webserver.ui.diskpath=|webserver.ui.diskpath=/cc/cruise-control-ui/|g' \
		/cc/config/cruisecontrol.properties

###
### Startup
###
CMD ["/run.sh"]
