#!/bin/bash

directory=${1}

if [ -z "${directory}" ] ; then
	echo "Please specify a directory"
	exit 1
fi

pushd ${directory}
linked_files=$(find . -type l)
for linked_file in ${linked_files} ; do
	cp -a --verbose --preserve=timestamps --remove-destination $(readlink ${linked_file}) ${linked_file}
done
popd
