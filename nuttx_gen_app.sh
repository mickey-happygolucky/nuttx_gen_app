#!/bin/bash
#title           :nuttx_gen_app.sh
#description     :This script will generate NuttX application template.
#author		     :Yusuke Mitsuki(mickey.happygolucky@gmail.com)
#date            :20190531
#version         :0.1
#usage		     :bash nuttx_gen_app.sh APP_NAME [(STACK_SIZE|-d)]
#notes           :NUTTX_APP_DIR should be set NUTTX_APP_DIR before run this script.
#bash_version    :4.4.19(1)-release
#==============================================================================


################################################################################
# variables
APP_NAME=""
APP_DIR=""
STACK_SIZE=2048

################################################################################
# functions
abort()
{
    echo "abort!!"
    exit
}

check_app_root()
{
    if [ -z ${NUTTX_APP_DIR} ] ; then
        echo "NUTTX_APP_DIR is not set."
        exit
    fi
}

check_dir()
{
    if [ -d $1 ] ; then
        echo "$1 already exists."
        return 1
    elif [ -e $1 ] ; then
        echo "$1 is not directory. "
        abort
    else
        echo "$1 does not exists. creating."
        mkdir -p $1
    fi
    return 0
}

check_external_dir()
{
    check_dir ${NUTTX_APP_DIR}/external
}

check_app_dir()
{
    check_dir ${NUTTX_APP_DIR}/external/${APP_NAME}
    if [ $? -ne 0 ] ; then
        abort
    fi
    APP_DIR=${NUTTX_APP_DIR}/external/${APP_NAME}
}

check_args()
{
    if [ $# -ne 1 -a $# -ne 2 ] ; then
        echo "nuttx_gen_app.sh APP_NAME [(STACK_SIZE|-d)]"
        echo " APP_NAME:    name of application that will be create."
        echo " STACK_SIZE:  default stack size of application."
        echo " -d:          delete application which specified by APP_NAME."
        exit
    fi
    if [ $# -eq 2 ] ; then
        if [ $2 = '-d' ] ; then
            delete_app $1
            exit
        fi
        local a2=`echo $2|bc`
        if [ $a2 -eq 0 ] ; then
            echo "STACK_SIZE must be number."
            abort
        fi
        STACK_SIZE=$2
    fi
    APP_NAME=$1
    echo "APP_NAME="${APP_NAME}
    echo "STACK_SIZE="${STACK_SIZE}
}

# This functions cannot use ${APP_NAME} and ${APP_DIR}.
# Because their are not confirmed.
delete_app() 
{
    if [ -L ${NUTTX_APP_DIR}/$1 ] ; then
        rm -f ${NUTTX_APP_DIR}/$1
        echo "${NUTTX_APP_DIR}/$1 deleted."
    fi
    if [ -e ${NUTTX_APP_DIR}/external/$1 ] ; then
        rm -rf ${NUTTX_APP_DIR}/external/$1
        echo "${NUTTX_APP_DIR}/external/$1 deleted."
    fi
}

check_file()
{
    if [ -f $1 ] ; then
        echo "$1 exists."
    elif [ -e $1  ] ; then
        echo "$1 is not regular file."
        abort
    fi
}

gen_Kconfig()
{
    local file=${APP_DIR}/Kconfig
    check_file ${file}
    cat <<EOF > ${file}
config EXTERNAL_${APP_NAME^^}
	tristate "\"${APP_NAME^}\" example"
	default n
	---help---
		Enable the \"${APP_NAME^}\" example

if EXTERNAL_${APP_NAME^^}

config EXTERNAL_${APP_NAME^^}_PROGNAME
	string "Program name"
	default "${APP_NAME,,}"
	depends on BUILD_LOADABLE
	---help---
		This is the name of the program that will be use when the NSH ELF
		program is installed.

config EXTERNAL_${APP_NAME^^}_PRIORITY
	int "${APP_NAME^} task priority"
	default 100

config EXTERNAL_${APP_NAME^^}_STACKSIZE
	int "${APP_NAME^} stack size"
	default ${STACK_SIZE}

endif
EOF
    echo "${file} created."
}

gen_Make_defs()
{
    local file=${APP_DIR}/Make.defs
    check_file ${file}
    cat <<'EOF' > ${file}
ifneq ($(CONFIG_EXTERNAL_%APP_NAME%),)
CONFIGURED_APPS += %app_name%
endif
EOF
    sed -i "s/%APP_NAME%/${APP_NAME^^}/" ${file}
    sed -i "s/%App_Name%/${APP_NAME^}/" ${file}
    sed -i "s/%app_name%/${APP_NAME}/" ${file}

    echo "${file} created."
}

gen_Makefile()
{
    local file=${APP_DIR}/Makefile
    check_file ${file}
    cat <<'EOF'> ${file}
-include $(TOPDIR)/Make.defs

# %App_Name%, World! built-in application info

CONFIG_EXTERNAL_%APP_NAME%_PRIORITY ?= SCHED_PRIORITY_DEFAULT
CONFIG_EXTERNAL_%APP_NAME%_STACKSIZE ?= %STACK_SIZE%

APPNAME = %app_name%

PRIORITY  = $(CONFIG_EXTERNAL_%APP_NAME%_PRIORITY)
STACKSIZE = $(CONFIG_EXTERNAL_%APP_NAME%_STACKSIZE)

# %App_Name%, World! Example

ASRCS =
CSRCS =
MAINSRC = %app_name%_main.c

CFLAGS += -I$(TOPDIR)/mbedtls

CONFIG_EXTERNAL_%APP_NAME%_PROGNAME ?= %app_name%$(EXEEXT)
PROGNAME = $(CONFIG_EXTERNAL_%APP_NAME%_PROGNAME)

MODULE = CONFIG_EXTERNAL_%APP_NAME%

include $(APPDIR)/Application.mk
EOF

    sed -i "s/%APP_NAME%/${APP_NAME^^}/" ${file}
    sed -i "s/%App_Name%/${APP_NAME^}/" ${file}
    sed -i "s/%app_name%/${APP_NAME}/" ${file}
    sed -i "s/%STACK_SIZE%/${STACK_SIZE}/" ${file}

    echo "${file} created."
}

gen_main_file()
{
    local file=${APP_DIR}/${APP_NAME}_main.c
    check_file ${file}
    cat <<EOF > ${file}
/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <nuttx/config.h>
#include <stdio.h>

/****************************************************************************
 * ${APP_NAME}_main
 ****************************************************************************/

#if defined(BUILD_MODULE)
int main(int argc, FAR char *argv[])
#else
int ${APP_NAME}_main(int argc, char *argv[])
#endif
{
    printf("Hello, world\n");
    return 0;
}
EOF
    echo "${file} created."
}

create_link()
{
    if [ -e ${NUTTX_APP_DIR}/${APP_NAME} ] ; then
        rm -f ${NUTTX_APP_DIR}/${APP_NAME}
    fi
    ln -s ${APP_DIR} ${NUTTX_APP_DIR}/${APP_NAME}
    echo "${NUTTX_APP_DIR}/${APP_NAME} created."
}

################################################################################
# main logic
check_app_root
check_external_dir 
check_args $@
check_app_dir
gen_Kconfig
gen_Make_defs
gen_Makefile
gen_main_file
create_link
