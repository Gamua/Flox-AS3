#!/bin/bash

# This script creates a nice API reference documentation for the Flox source.
# It uses the "ASDoc" tool that comes with the Flex SDK.
# Adapt the ASDOC variable below so that it points to the correct path.

echo "Please enter the version number (like '1.0'), followed by [ENTER]:"
read version

ASDOC="/Applications/Adobe Flash Builder 4.6/sdks/4.6.0/bin/asdoc"

"${ASDOC}" \
  -doc-sources ../src \
  -main-title "Flox AS3 Reference (v$version)" \
  -window-title "Flox AS3 Reference" \
  -package com.gamua.flox "The main components of the Flox cloud service." \
  -package com.gamua.flox.utils "Utility classes and helper methods." \
  -output html
