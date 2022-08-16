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
  export KBUILD_BUILD_USER=$TARGET_BUILD_USER
  export KBUILD_BUILD_HOST=$TARGET_BUILD_HOST
  export KBUILD_BUILD_VERSION=$TARGET_PACKAGE_NAME+$TARGET_SPECIAL_BUILDID
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
	else

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
	fi
fi

if [ $TARGET_CLONE_DEPENDENCIES == 'true' ]; then
	if [ $TARGET_USE_TELEGRAM == 'true' ]; then
		tg_send_msg "*Cloning Dependencies!*"
	fi
	if [ $TARGET_COMPILER == 'clang' ]; then
		if ! [ $TARGET_COMPILER_REPOSITORY ]; then
			echo -e "${red}[x] TARGET_COMPILER_REPOSITORY is undeclared"
			echo -e "${red}[x] unable to sync."
			return 0
		else
			if [ ! -d ${TARGET_WORKSPACE_DIRECTORY}/clang ]; then
				echo -e "${blue}[i] Cloning ${TARGET_COMPILER_REPOSITORY}..."
				git clone --depth=1 "${TARGET_COMPILER_REPOSITORY}" ${TARGET_WORKSPACE_DIRECTORY}/clang &>/dev/null
				echo -e "${green}[*] Done."
				KBUILD_COMPILER_STRING=$("${TARGET_COMPILER_REPOSITORY}"/clang/bin/clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')
				export KBUILD_COMPILER_STRING
				export PATH=$TARGET_COMPILER_REPOSITORY/clang/bin/:/usr/bin/:${PATH}
        MAKE+=(
          ARCH=arm64
          O=out
          CROSS_COMPILE=aarch64-linux-gnu-
          CROSS_COMPILE_ARM32=arm-linux-gnueabi-
          AR=llvm-ar
          AS=llvm-as
          NM=llvm-nm
          OBJDUMP=llvm-objdump
          STRIP=llvm-strip
          CC=clang
          V=0 2>&1 | tee ${TARGET_WORKSPACE_DIRECTORY}/builder.log
        )
				echo -e "${blue}[i] Compiler Strings have been set successfully."
			fi
		fi
	elif [ $TARGET_COMPILER == 'gcc' ]; then
		if ! [ $TARGET_COMPILER_REPOSITORY ]; then
			echo -e "${red}[x] TARGET_COMPILER_REPOSITORY is undeclared"
			echo -e "${red}[x] unable to sync."
			return 0
		else
			if [ ! -d ${TARGET_WORKSPACE_DIRECTORY}/gcc64 ]; then
				echo -e "${blue}[i] Cloning ${TARGET_GCC_COMPILER_REPOSITORY}..."
				git clone --depth=1 "${TARGET_GCC_COMPILER_REPOSITORY}" ${TARGET_WORKPSACE_DIRECTORY}/gcc64 &>/dev/null
				echo -e "${green}[*] Done."
			elif [ ! -d ${TARGET_WORKSPACE_DIRECTORY}/gcc32 ]; then
				echo -e "${blue}[i] Cloning ${TARGET_GCC_COMPILER32_REPOSITORY}..."
				git clone --depth=1 "${TARGET_GCC_COMPILER32_REPOSITORY}" ${TARGET_WORKSPACE_DIRECTORY}/gcc32 &>/dev/null
				echo -e "${green}[*] Done."
				KBUILD_COMPILER_STRING=$("${TARGET_WORKSPACE_DIRECTORY}"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
				export KBUILD_COMPILER_STRING
				export PATH="${TARGET_WORKSPACE_DIRECTORY}"/gcc32/bin:"${TARGET_WORKSPACE_DIRECTORY}"/gcc64/bin:/usr/bin/:${PATH}
        MAKE+=(
          ARCH=arm64
          O=out
          CROSS_COMPILE=aarch64-elf-
          CROSS_COMPILE_ARM32=arm-eabi-
          LD="${TARGET_WORKSPACE_DIRECTORYSPACE_DIRECTORY}"/gcc64/bin/aarch64-elf-"${TARGET_LINKER}"
          AR=llvm-ar
          NM=llvm-nm
          OBJDUMP=llvm-objdump
          OBJCOPY=llvm-objcopy
          OBJSIZE=llvm-objsize
          STRIP=llvm-strip
          HOSTAR=llvm-ar
          HOSTCC=gcc
          HOSTCXX=aarch64-elf-g++
          CC=aarch64-elf-gcc
          V=0 2>&1 | tee ${TARGET_WORKSPACE_DIRECTORY}/builder.log
        )
				echo -e "${blue}[i] Compiler Strings have been set successfully."
      fi
		fi
	if [ $TARGET_PACKAGE_ANYKERNEL == 'true' ]; then
		if [ ! -d $TARGET_WORKSPACE_DIRECTORY/anykernel ]; then
			echo -e "${blue}[i] Cloning ${TARGET_ANYKERNEL_SOURCE}..."
			git clone --depth=1 "${TARGET_ANYKERNEL_SOURCE}" ${TARGET_WORKSPACE_DIRECTORY}/anykernel &>/dev/null
			echo -e "${green}[*] Done."
		fi
		package ()
		{
			echo -e "${blue}[i] Building ZIP..."
			if [ $TARGET_USE_TELEGRAM == 'true' ]; then
				tg_send_msg "*Building ZIP!*"
			fi
			cd $TARGET_WORKSPACE_DIRECTORY/anykernel
			cp $TARGET_WORKSPACE_DIRECTORY/out/arch/arm64/boot/${TARGET_COMPRESSION_STYLE} $(pwd)
			zip -r9 "$TARGET_PACKAGE_NAME".zip . -x ".git*" -x "README.md" -x "LICENSE" -x "*.zip" &>/dev/null
			echo -e "${green}[*] ZIP Built!"
			if [ $TARGET_USE_TELEGRAM == 'true' ]; then
				tg_send_msg "*ZIP Built!*"
				tg_send_file "$TARGET_PACKAGE_NAME.zip" "
#$TARGET_SPECIAL_BUILDID
*compiler:* \`$KBUILD_COMPILER_STRING\`
*builder:* \`$TARGET_BUILD_USER\`
*host:* \`$TARGET_BUILD_HOST\`
*kversion:* \`make kernelversion 2>/dev/null\`
"
			fi
		}
fi

kcompile()
{
  echo -e "${blue}[i] attempt to Build (${DEVICE})[${CODENAME}]"
  make -j"$TARGET_CORES" "${TARGET_DEFCONFIG}" "${MAKE[@]}"
  if [ -f ${TARGET_WORKSPACE_DIRECTORY}/out/arch/arm64/boot/${IMAGE_COMPRESSION_STYLE} ]; then
    echo -e "${green}[*] successfully compiled target"
    if [ $TARGET_PACKAGE_ANYKERNEL == "true" ]; then
      package
    fi
  else
    echo -e "${red}[!] something went wrong, check provided logs."
  fi
}

kcompile

