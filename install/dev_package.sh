#!/bin/bash
set -eo pipefail

apt-get update
apt-get install -y --force-yes --no-install-recommends $BUILD_PACKAGE
