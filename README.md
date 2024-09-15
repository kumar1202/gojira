# Gojira

[![Gem Version](https://badge.fury.io/rb/gojira_apiops.svg)](https://badge.fury.io/rb/gojira_apiops)

**Maintaining order within the Kong realm** [[ref](https://en.wikipedia.org/wiki/Gojira)]

<img src="docs/gojira.png" alt="drawing" width="500"/>

## Documentation

This post on my blog was the starting point of it all: [Gojira: Building Multi-Region APIOps with Kong](https://www.kumarabhijeet.me/building-multi-region-kong-apiops)

More detailed docs about the conventions of the framework are yet to follow.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gojira'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gojira

## Usage

### Top-Level Commands
```
commands:
  gojira cluster         # Commands interacting with Kong cluster
  gojira env             # Commands interacting with Gateway env directory
  gojira help [COMMAND]  # Describe available commands or one specific command
  gojira version         # Print Gojira gem version

Options:
  [--kong-addr=KONG_ADDR]                        # Kong Host & Port
  [--config=CONFIG]                              # decK config file
  [--ca-cert-file=CA_CERT_FILE]                  # CA Cert File
  [--tls-client-key-file=TLS_CLIENT_KEY_FILE]    # TLS Client Key file
  [--tls-client-cert-file=TLS_CLIENT_CERT_FILE]  # TLS Client Cert file
  [--tls-server-name=TLS_SERVER_NAME]            # TLS Server Name
```

### Cluster commands

These commands are used to interact with the Kong Control Plane

```
Commands:
  gojira cluster diff            # diff output for kong config in a cluster
  gojira cluster dump            # takes dump of resources from a kong cluster
  gojira cluster help [COMMAND]  # Describe subcommands or one specific subcommand
  gojira cluster sync            # syncs kong config to a cluster
  gojira cluster validate        # validates kong config for a cluster

```

```
Usage:
  gojira cluster sync

Options:
  -s, [--kong-state-file=KONG_STATE_FILE]  # Kong State File
  -n, [--env-name=ENV_NAME]                # Environment identifier name
  -c, [--compliance-type=COMPLIANCE_TYPE]  # Compliance Type
                                           # Possible values: pci, non-pci
  -f, [--cluster-file=CLUSTER_FILE]        # Cluster file path
  -d, [--dc-name=DC_NAME]                  # DC Name

syncs kong config to a cluster
```

### Env Commands

These commands are used to lint and generate configurations based on environments and tags defined a/c Gojira's opinionated conventions

```
Commands:
  gojira env generate        # generates kong state for the env repo
  gojira env help [COMMAND]  # Describe subcommands or one specific subcommand
  gojira env lint            # lints env repo and validates against conventions
```

```
Usage:
  gojira env generate

Options:
  -f, [--gateway-folder=GATEWAY_FOLDER]    # Gateway configs folder path
  -n, [--env-name=ENV_NAME]                # Environment identifier name
  -f, [--cluster-file=CLUSTER_FILE]        # Path to Cluster definition file
  -c, [--compliance-type=COMPLIANCE_TYPE]  # Compliance Type(pci/non-pci)
  -d, [--dc-name=DC_NAME]                  # DC Name

generates kong state for the env repo
```

### TODO:

* Lint: 
  * Searches through env directory 
  * get list of all products/services
  * checks if their upstream info is available across all clusters of that env 
  * service level validations(PCI/NPCI service tags, no route with tags)
  * Gives out errors of each validation level in JSON

* Generate: 
  * Merge product services files into one config
  * Substitute kong upstreams for respective compliance type and DC
  * Merge all product configs into one file
  * Not to interfere and merge global conf and certs, they will be passed with -s
  * Can include local config here later
