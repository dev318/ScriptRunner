#!/bin/bash

# script.sh
# ScriptRunner
#
# Created by Zack Smith on 2/8/10.
# Copyright 2010 318, inc. All rights reserved.

# These can be configured in settings.plist in scriptArguments
# The scriptArguments array must exist currently
echo "My Arguments $@"

echo "Whoami: `/usr/bin/whoami`"


/bin/ls -l /
exit 0
