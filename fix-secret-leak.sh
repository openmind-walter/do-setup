#!/bin/bash
# Script to remove .env file from git history

set -e

echo "⚠️  WARNING: This will rewrite git history!"
echo "Make sure you have a backup and coordinate with your team."
echo ""
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "Cancelled."
  exit 1
fi

echo ""
echo "Removing 02-frontend/.env from git history..."

# Remove the file from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch 02-frontend/.env" \
  --prune-empty --tag-name-filter cat -- --all

echo ""
echo "✅ Secret removed from git history"
echo ""
echo "Next steps:"
echo "1. Force push: git push origin --force --all"
echo "2. Rotate the exposed token at: https://cloud.digitalocean.com/account/api/tokens"
echo "3. Update your local .env and dev.tfvars with the new token"
echo ""
echo "⚠️  IMPORTANT: Coordinate with your team before force pushing!"

