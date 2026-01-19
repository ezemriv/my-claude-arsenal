#!/bin/bash

# Script to sync agents from repository to local configuration directory
# Only copies files that are newer in source than destination

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$SCRIPT_DIR/agents"

##########################################################
# UPDATE THIS SECTION BASED ON YOUR SETUP ################
AGENTS_DEST="$HOME/.claude/agents"
##########################################################

echo "Syncing agents from $AGENTS_DIR to $AGENTS_DEST..."

# Create destination directory if it doesn't exist
mkdir -p "$AGENTS_DEST"

# Sync agents directory
rsync -auv --itemize-changes --delete "$AGENTS_DIR/" "$AGENTS_DEST/"

echo "✓ Agent sync complete!"
