#! /usr/bin/env bash

# Script for replacing variables in config/config.xml with contents from some
# file
#
# Usage: ./replace-var-in-config '{{auth}}' ./dev-auth.xml
# 
# replaces the string '{{auth}}' in config/config.xml with the contents
# from ./dev-auth.xml

set -e

if [ -z "$1" ]
then
	echo "Variable name is required as first argument"
	exit 1
fi

if [ -z "$2" ]
then
	echo "File to take contents from is required as second argument"
	exit 1
fi

VARIABLE_TO_REPLACE="{{$1}}"
FILE_TO_REPLACE_WITH="$2"
FILE_TO_REPLACE_IN="config/config.xml"

CONTENT_TO_REPLACE_WITH=$(cat $FILE_TO_REPLACE_WITH | tr -d '\n' | tr -d '\t')

sed -i.bak "s|$VARIABLE_TO_REPLACE|$CONTENT_TO_REPLACE_WITH|g" $FILE_TO_REPLACE_IN
