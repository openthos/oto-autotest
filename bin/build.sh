#!/bin/bash -x
# $1 : location of oto8 repository
# $2 : the script need running in docker
# $3 : the out dir

# source /etc/profile > /dev/null 2>&1
DATE=`date +%Y%m%d%H`
IS_NEW=F
export USER=root	# for crontab

if [ -z $2 ]; then
  echo MUST define \$1 and \$2.
  echo \$1 : location of oto8 repository  
  echo \$2 : the script need running in docker
  exit 2
elif [ ! -d $1 ]; then
  echo $1 is NOT a valid path
  exit 2
fi

pushd $1
  repo sync > /dev/null
  wait
  repo manifest -r -o ../prop/$DATE.xml
  CMP_XML=`ls -t ../prop | awk 'NR==2'`
  diff ../prop/$DATE.xml ../prop/$CMP_XML
  RESULT_DIFF=$?
  if [ $RESULT_DIFF -eq 1 ]; then
    IS_NEW=T
  elif [ -z $CMP_XML ]; then
    IS_NEW=T
  elif [ $RESULT_DIFF -eq 0 ]; then
    rm ../prop/$DATE.xml
  fi

if [ $IS_NEW == F ]; then
  echo There is no new updates
  exit 2
fi

$2 user $3 > /dev/null 2>&1
$2 userdebug $3 > /dev/null 2>&1
$2 eng $3 > /dev/null 2>&1
popd

## there is some mistake when running "docker exec", so running build locally
# docker start szx-8.1 
# docker exec -it szx-8.1 bash -c "$2 user"
# docker exec -it szx-8.1 bash -c "$2 userdebug"
# docker exec -it szx-8.1 bash -c "$2 eng"
# docker stop szx-8.1
    

