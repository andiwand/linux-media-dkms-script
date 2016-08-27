#!/bin/bash

# constants
BUILD=1

# paths
FILE_DKMS="dkms.conf"
DIR_MEDIA_BUILD="media_build"

# determine script path
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR_SCRIPT="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# update paths
FILE_DKMS="${DIR_SCRIPT}/${FILE_DKMS}"
DIR_MEDIA_BUILD="${DIR_SCRIPT}/${DIR_MEDIA_BUILD}"

# determine nuber of cores
CORES=$( grep -c '^processor' /proc/cpuinfo )

# args
VERSION=$1

if [ "$BUILD" = 1 ]; then
	# clone
	mkdir "$DIR_MEDIA_BUILD"
	git clone git://linuxtv.org/media_build.git "$DIR_MEDIA_BUILD"
	
	# download and untar
	cd "$DIR_MEDIA_BUILD"
	make download untar
	
	# build
	make -j$((CORES+1)) -l${CORES}
else
	cd "$DIR_MEDIA_BUILD"
fi

# clear dkms.conf
echo -n > $FILE_DKMS

echo "PACKAGE_NAME=\"linux-media\"" >> $FILE_DKMS
echo "PACKAGE_VERSION=\"$VERSION\"" >> $FILE_DKMS
echo "REMAKE_INITRD=\"no\"" >> $FILE_DKMS
echo "AUTOINSTALL=\"no\"" >> $FILE_DKMS
echo "BUILT_MODULE_LOCATION=\".\"" >> $FILE_DKMS
echo "MAKE=\"make download untar default\"" >> $FILE_DKMS
echo "CLEAN=\"make clean\"" >> $FILE_DKMS

i=0
for f in $( find -name *.ko ); do
	MODULE_FILE=$( basename $f )
	MODULE=$( basename $f .ko )
	DIR=$( dirname $f )
	DIR=${DIR#./}
	echo "BUILT_MODULE_NAME[$i]=\"$MODULE\"" >> $FILE_DKMS
	echo "BUILT_MODULE_LOCATION[$i]=\"$DIR\"" >> $FILE_DKMS
	echo "DEST_MODULE_LOCATION[$i]=\"/updates\"" >> $FILE_DKMS
	i=$(( i+1 ))
done

