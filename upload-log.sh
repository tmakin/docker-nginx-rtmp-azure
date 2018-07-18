#!/bin/bash

# Wrapper around the upload script with debug logging
# NB: avoid using this in production as it does not have any rotation

set -o pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

$DIR/upload.sh $1 &> /tmp/upload.log
