# Docker Cruise Control

[![Build Status](https://travis-ci.com/Flaconi/docker-cruise_control.svg?branch=master)](https://travis-ci.com/Flaconi/docker-cruise_control)


> Docker image for [Cruise Control](https://github.com/linkedin/cruise-control)

[![Docker hub](http://dockeri.co/image/flaconi/cruise_control?&kill_cache=1)](https://hub.docker.com/r/flaconi/cruise_control)


## Available images tags

### Rolling releases

| Docker tag        | Cruise Control version   |
|-------------------|--------------------------|
| `latest-latest`   | Latest available release |
| `2.4.2-latest`    | Cruise control v2.4.2    |
| `2.0.105-latest`  | Cruise control v2.0.105  |

### Git tagged releases

| Git tag  | Docker tag        | Cruise Control version   |
|----------|-------------------|--------------------------|
| `<gtag>` | `latest-<gtag>`   | Latest available release |
| `<gtag>` | `2.4.2-<gtag>`    | Cruise control v2.4.2    |
| `<gtag>` | `2.0.105-<gtag>`  | Cruise control v2.0.105  |

```bash
docker pull flaconi/cruise_control
```


## Build `metrics-reporter.jar`

This file is used for Kafka broker.
```bash
# Will build and copy file to dist/ in current git repo
make artifact
```


## Build and test
```bash
# Build and test latest version
make build
make test

# Build and test specific version
make build VERSION=2.0.105
make test VERSION=2.0.105

# Rebuild (--no-cache)
make rebuild
make rebuild VERSION=2.0.105
```


## Configuration files

| file | info |
|------|------|
| `/cc/config/capacity.json` | Holds capacity info and can be mounted or created with env vars. |
| `/cc/config/cruisecontrol.properties` | Full configuration. Currently only bootstrap servers can be adjusted with env vars. If you need more granular configuration, mount this file yourself. |
| `/cc/cruise-control-ui/config.csv` | Environment display version for the web ui. Can only be adjusted via env vars. |


## Environment variables

You can either use environment variables or mount the configuration files yourself.

### PORT

At what port Cruise Control web ui should listen internally. Defaults to `9090` if not set.


### BROKER_CAPACITY
If set, will override values in `/cc/config/capacity.json`

* Format: `<id>:<disk>:<cpu>:<nw_in>:<nw_out>[,<id>:<disk>:<cpu>:<nw_in>:<nw_out>]`

```bash
# Creates capacities for broker 0 and broker 1
BROKER_CAPACITY=0:5000,100:500:500,1:5000,100:500:500
```

### BOOTSTRAP_SERVERS
If set, will adjust `bootstrap.servers` value in `/cc/config/cruisecontrol.properties`

* Format: `<broker1>:<port1>[,<broker2>:<port2>]`

```bash
# Adds two bootstrap servers
BOOTSTRAP_SERVERS=broker1.example.com:9092,broker1.example.com:9092
```

### UI_ENV

Used for the web interface. Defaults to `default` if not set.
Will create `/cc/cruise-control-ui/config.csv`
```bash
# Changes env name to dev
UI_ENV=dev
```


## License

[MIT License](LICENSE.md)

Copyright (c) 2020 Flaconi GmbH
