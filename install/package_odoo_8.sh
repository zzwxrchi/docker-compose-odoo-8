#!/bin/bash
set -eo pipefail

apt-get update
# authentication error for libc-ares2
# apt-get install -y --force-yes --no-install-recommends libc-ares2

apt-get install -y --force-yes --no-install-recommends \
    ca-certificates \
    curl \
    nodejs \
    npm \
    ntp \
    python-support \
    python-pyinotify \
    python-pip
#    python-renderpm 
#    node-clean-css \
#    node-less \

##  for 9.0-10.0
#    antiword \
#    apt-transport-https \
#    ghostscript \
#    graphviz \
#    less \
#    nano \
#    poppler-utils \
#    python \
#    python-libxslt1 \
#    python-pip \
#    xfonts-75dpi \
#    xfonts-base \
#    tcl expect
