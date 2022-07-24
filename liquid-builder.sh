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

# -- Telegram Functions used of Telegram API
tg_send_pic ()	# send picture(s) via Telegram API
{
        curl https://api.telegram.org/bot"${TOKEN}"/sendphoto \
                -F "chat_id=${CHATID}" \
                -F "photo=@$1" \
                -F "caption=$2"
}

tg_send_msg ()  # send message(s) via Telegram API
{
	curl -sX POST https://api.telegram.org/bot"${TOKEN}"/sendMessage \
		-d chat_id="${CHATID}" \
		-d parse_mode=Markdown \
		-d disable_web_page_preview=true \
		-d text="$1" &>/dev/null
}

tg_send_file () # send file(s) via Telegram API
{
	MD5=$(md5sum "$1" | cut -d' ' -f1)
	curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TOKEN}"/sendDocument \
		-F "chat_id=${CHATID}" \
		-F "parse_mode=Markdown" \
		-F "caption=$2 | *MD5*: \`$MD5\`"
}
