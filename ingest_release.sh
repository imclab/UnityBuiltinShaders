#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

VERSION=$1
PACKAGE=raw/builtin_shaders-${VERSION}.zip

if [ ! -e $PACKAGE ]; then
  echo "ERROR: Can't find $PACKAGE"
  exit 1
fi

DIRS=(CGIncludes/ DefaultResources/ DefaultResourcesExtra/ Editor/)
for DIR in ${DIRS[*]}; do test -e $DIR && rm -rf $DIR; done
unzip $PACKAGE -d .
for DIR in ${DIRS[*]}; do test -e $DIR && git add $DIR; done
git commit --allow-empty -m "$VERSION"
