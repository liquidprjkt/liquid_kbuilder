#!/usr/bin/sh
#
# The liquid Project
# Copyright (c) 2022 UsiFX <xprjkts@gmail.com>
#

# Placeholders: [i] [x] [*]

# Debugging
set +x

# Colors (\e)
green='\e[1;32m'
blue='\e[1;34m'
yellow='\e[1;93m'
red='\e[1;31m'

# first of all, include build configuration
if [ $(pwd)/builder-arg.cfg ]; then
	source $(pwd)/builder-arg.cfg
	echo -e "${blue}[i]: Configured\e[0m"
else
	echo -e "${red}[x]: Build Configurations not found!\n"
	return 0
fi

if [ ${TARGET_USE_TELEGRAM} == 'true' ];then
        if [ ${CHATID} == '' ]; then
                echo -e "${red}[x]: Chat ID is not defined"
                return 0
        elif [ ${TOKEN} == '' ]; then
                echo -e "${red}[x]: Bot Token is not defined"
		return 0
        fi
fi
