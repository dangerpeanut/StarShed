#!/usr/bin/env bash
#===============================================================================
#
#          FILE: cleanempties.sh
# 
#         USAGE: ./cleanempties.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: dangerpeanut (na), dangerpeanut.net@gmail.com
#  ORGANIZATION: DangerPeanut.net
#       CREATED: 12/17/13 08:04:44
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

moddir=$2

find $moddir/$1 -type d -empty -delete
