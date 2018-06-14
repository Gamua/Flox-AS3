#!/bin/bash

# This script creates a nice API reference documentation for the Flox source.
# It uses the "ASDoc" tool that comes with the Flex SDK.
# Adapt the ASDOC variable below so that it points to the correct path.

if [ $# -ne 1 ]
then
  echo "Usage: `basename $0` [version]"
  echo "  (version like '1.0')"
  exit 1
fi

version=$1
ASDOC="/Users/redge/Dropbox/Development/library/flash/air/air-28/bin/asdoc"

"${ASDOC}" \
  -doc-sources ../src \
  -main-title "Flox AS3 Reference (v$version)" \
  -window-title "Flox AS3 Reference" \
  -package-description-file=../build/ant/package-descriptions.xml
  -output html
