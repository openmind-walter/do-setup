# Adding Domains to App Platform

The domain configuration has been moved to standalone bash scripts to avoid `jq` parsing errors in Terraform.

## Quick Start

After running `terraform apply`, add domains using:

```bash
cd 02-frontend
./add-domains-from-terraform.sh
```

This script automatically:
1. Gets the app ID from Terraform outputs
2. Extracts domains from your `dev.frontend.tfvars` file
3. Adds them to the App Platform app

## Manual Usage

### Option 1: Using Terraform Outputs (Recommended)

```bash
cd 02-frontend
export DO_TOKEN=your_digitalocean_token
./add-domains-from-terraform.sh
```

### Option 2: Direct Script Usage

```bash
cd 02-frontend
./add-domains.sh <APP_ID> <DO_TOKEN> --from-tfvars ../00-Env/dev.frontend.tfvars
```

### Option 3: With JSON Domains

```bash
./add-domains.sh <APP_ID> <DO_TOKEN> '[{"domain":"dev-mobile.openmindsolutions.sg","type":"PRIMARY"}]'
```

## Scripts

- **`add-domains.sh`**: Main script that adds domains to an App Platform app
- **`add-domains-from-terraform.sh`**: Helper script that extracts app ID and domains from Terraform

## Requirements

- `jq` installed (`brew install jq` on macOS)
- `curl` installed (usually pre-installed)
- DigitalOcean API token with write permissions
- Terraform outputs available (for `add-domains-from-terraform.sh`)

## Troubleshooting

### Error: "jq is required but not installed"
```bash
brew install jq  # macOS
# or
apt-get install jq  # Linux
```

### Error: "Could not get app ID from Terraform"
Make sure you've run `terraform apply` first and the app was created successfully.

### Error: "DO_TOKEN not set"
```bash
export DO_TOKEN=your_token_here
```

### Error: "Failed to add domains (HTTP 422)"
Check that:
- The domains are valid
- The app exists and is accessible
- Your API token has the correct permissions

