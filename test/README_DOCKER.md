# Docker Testing Setup for Gojira

This directory contains a Docker Compose setup for testing Gojira with multiple Kong instances.

## Architecture

The Docker setup creates:
- 1 PostgreSQL database
- 4 Kong instances (example setup with PCI/Non-PCI, but any compliance types can be used):
  - PCI Delhi (port 8001)
  - Non-PCI Delhi (port 8011)
  - PCI Mumbai (port 8021)
  - Non-PCI Mumbai (port 8031)
- 2 Mock backend services:
  - Delhi backend (port 9001)
  - Mumbai backend (port 9002)

Note: While this example uses PCI/Non-PCI tags, Gojira supports any custom compliance types like internal, external, dmz, public, etc.

## Getting Started

1. Start the Docker environment:
   ```bash
   docker-compose up -d
   ```

2. Wait for all services to be healthy:
   ```bash
   docker-compose ps
   ```

3. Run the test workflow:
   ```bash
   ./test/test_workflow.sh
   ```

## Testing Gojira Commands

### Lint Environment
```bash
bundle exec gojira env lint -f ./examples/configs -n dev -c ./test/clusters-docker.yaml
```

### Generate Kong Configuration
```bash
# For PCI Delhi
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c pci -d delhi

# For Non-PCI Delhi
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c non-pci -d delhi

# For PCI Mumbai
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c pci -d mumbai

# For Non-PCI Mumbai
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c non-pci -d mumbai

# For custom compliance types (if configured in clusters file)
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c internal -d delhi
bundle exec gojira env generate -g ./examples/configs -n dev -f ./test/clusters-docker.yaml -c public -d mumbai
```

### Sync to Kong
```bash
# Sync to PCI Delhi
bundle exec gojira cluster sync -s ./examples/configs/generated/kong-dev-pci-delhi.yaml -n dev -c pci -f ./test/clusters-docker.yaml -d delhi

# Validate before sync
bundle exec gojira cluster validate -s ./examples/configs/generated/kong-dev-pci-delhi.yaml
```

## Accessing Kong Admin APIs

- PCI Delhi: http://localhost:8001
- Non-PCI Delhi: http://localhost:8011
- PCI Mumbai: http://localhost:8021
- Non-PCI Mumbai: http://localhost:8031

## Cleaning Up

```bash
docker-compose down -v
```

This will stop all containers and remove the volumes.