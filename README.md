# Gojira

[![Gem Version](https://badge.fury.io/rb/gojira_apiops.svg)](https://badge.fury.io/rb/gojira_apiops)

**Maintaining order within the Kong realm** [[ref](https://en.wikipedia.org/wiki/Gojira)]

<img src="docs/gojira.png" alt="drawing" width="500"/>

## Documentation

This post on my blog was the starting point of it all: [Gojira: Building Multi-Region APIOps with Kong](https://www.kumarabhijeet.me/building-multi-region-kong-apiops)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gojira_apiops'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gojira_apiops

## Quick Start

### Basic Commands

#### 1. Validate Environment Configuration
```bash
gojira env lint -f ./configs -n production -c ./clusters.yaml
```

#### 2. Generate Kong Configuration
```bash
# Generate for PCI Delhi
gojira env generate -g ./configs -n production -f ./clusters.yaml -c pci -d delhi

# Generate for Non-PCI Mumbai
gojira env generate -g ./configs -n production -f ./clusters.yaml -c non-pci -d mumbai

# Generate for custom compliance types
gojira env generate -g ./configs -n production -f ./clusters.yaml -c internal -d delhi
gojira env generate -g ./configs -n production -f ./clusters.yaml -c public -d delhi
```

#### 3. Sync to Kong
```bash
# Validate before sync
gojira cluster validate -s ./configs/generated/kong-production-pci-delhi.yaml

# Sync to Kong
gojira cluster sync -s ./configs/generated/kong-production-pci-delhi.yaml -n production -c pci -f ./clusters.yaml -d delhi
```

## Directory Structure

```
configs/
├── production/
│   └── my-product/
│       ├── service1.yaml     # Service definitions
│       ├── service2.yaml
│       └── upstreams.yaml    # Upstream targets
├── uat/
│   └── my-product/
│       ├── service1.yaml
│       └── upstreams.yaml
└── generated/                # Generated Kong configs
    ├── kong-production-pci-delhi.yaml
    └── kong-production-non-pci-mumbai.yaml
```

## Configuration Examples

### Service Configuration (service1.yaml)
```yaml
services:
  - name: my-api
    host: my-api.upstream
    port: 443
    protocol: https
    connect_timeout: 60000
    tags:
      - pci  # Can be any tag: pci, non-pci, internal, public, etc.
    routes:
      - name: my-api-route
        hosts:
          - api.example.com
        paths:
          - /v1
        methods:
          - GET
          - POST
```

### Service with Custom Tags
```yaml
services:
  - name: internal-api
    host: internal.upstream
    port: 443
    protocol: https
    tags:
      - internal    # Custom compliance tag
      - monitoring  # Additional tags for categorization
    routes:
      - name: internal-route
        hosts:
          - internal.example.com
        paths:
          - /internal
```

### Upstream Configuration (upstreams.yaml)
```yaml
my-api.upstream:
  - delhi:
      - host: api-1.delhi.internal
        weight: 50
      - host: api-2.delhi.internal
        weight: 50
  - mumbai:
      - host: api.mumbai.internal
        weight: 100
```

### Cluster Configuration (clusters.yaml)
```yaml
production:
  dc:
    - delhi
    - mumbai
  control_plane:
    - compliance_type: pci
      dc: delhi
      address: https://kong-pci.delhi.example.com:8001
    - compliance_type: non-pci
      dc: delhi
      address: https://kong-nonpci.delhi.example.com:8001
    - compliance_type: pci
      dc: mumbai
      address: https://kong-pci.mumbai.example.com:8001
    - compliance_type: non-pci
      dc: mumbai
      address: https://kong-nonpci.mumbai.example.com:8001
```

## Command Reference

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

### Cluster Commands

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
  -c, [--compliance-type=COMPLIANCE_TYPE]  # Compliance Type (e.g., pci, non-pci, internal, external)
  -f, [--cluster-file=CLUSTER_FILE]        # Cluster file path
  -d, [--dc-name=DC_NAME]                  # DC Name

syncs kong config to a cluster
```

### Env Commands

These commands are used to lint and generate configurations based on environments and tags defined according to Gojira's conventions. Services can be tagged with any compliance type (pci, non-pci, internal, external, etc.) to segregate them into different Kong instances

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
  -g, [--gateway-folder=GATEWAY_FOLDER]    # Gateway configs folder path
  -n, [--env-name=ENV_NAME]                # Environment identifier name
  -f, [--cluster-file=CLUSTER_FILE]        # Path to Cluster definition file
  -c, [--compliance-type=COMPLIANCE_TYPE]  # Compliance Type (e.g., pci, non-pci, internal, external)
  -d, [--dc-name=DC_NAME]                  # DC Name

generates kong state for the env repo
```

## Testing with Docker

1. Start the test environment:
```bash
docker-compose up -d
```

2. Run the test workflow:
```bash
./test/test_workflow.sh
```

3. Access Kong Admin APIs:
- PCI Delhi: http://localhost:8001
- Non-PCI Delhi: http://localhost:8011
- PCI Mumbai: http://localhost:8021
- Non-PCI Mumbai: http://localhost:8031

## Common Workflows

### Add a New Service
1. Create service definition in `configs/{env}/{product}/new-service.yaml`
2. Add upstream configuration to `configs/{env}/{product}/upstreams.yaml`
3. Run `gojira env lint` to validate
4. Run `gojira env generate` for each DC/compliance combination
5. Run `gojira cluster sync` to deploy

### Update Service Configuration
1. Modify the service YAML file
2. Run `gojira env lint` to validate changes
3. Run `gojira env generate` to regenerate configs
4. Run `gojira cluster diff` to see changes
5. Run `gojira cluster sync` to apply changes

## Troubleshooting

### Validation Errors
- Ensure all services have at least one tag
- Check that upstream weights sum to 100 for each DC
- Verify all service hosts have corresponding upstream definitions

### Sync Errors
- Ensure Kong admin API is accessible
- Check that the cluster file has correct control plane addresses
- Verify deck CLI is installed and accessible

## Features

### Implemented Features

#### Lint Command
- Searches through env directory and lists all products/services
- Validates upstream information availability across all clusters
- Service level validations:
  - Services must have at least one tag
  - Routes should not have tags
- Comprehensive error reporting

#### Generate Command
- Merges product service files into one config
- Substitutes Kong upstreams for respective compliance type and DC
- Merges all product configs into one file per DC/compliance combination
- Generates deck-compatible Kong configuration files

### Architecture Principles
- GitOps-based declarative configuration
- Multi-region support with DC-specific upstream targets
- Compliance-based segregation using tags
- Service discovery through directory conventions
- Automated validation and generation workflows