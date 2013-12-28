#!/usr/bin/env bash
#===============================================================================
#
#          FILE: packmod.sh
# 
#         USAGE: ./packmod.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: dangerpeanut (na), dangerpeanut.net@gmail.com
#  ORGANIZATION: DangerPeanut.net
#       CREATED: 12/17/13 04:56:59
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

moddir=$2

builddir=$3

cd $moddir/$1 

\rm ${1}.zip

/usr/local/bin/zip -r $builddir/${1}.zip * > /dev/null
