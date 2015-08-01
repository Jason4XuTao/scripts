#!/bin/bash

basedir=/root/scripts/linux-perf-coll
mtime=30
log=$basedir/`basename $0 .sh`.log

# Use process substitution with & redirection and exec
if test -t 1; then
	exec > >(tee -a $log)
	exec 2>&1
else
	exec >>$log
	exec 2>&1
fi

# delete old file in datapath
# dataPath=$1
# mtime=$2
clearLogs()
{
	find $1 -type f -mtime +$2 -name "*.txt" -print |
	while read oldFile
	do
		echo "deleting file `ls -l $oldFile`"
		rm -f $oldFile
	done
}

function get_os_type
{
while read tmpos
do
	os=`cat /etc/*release | tr "[:upper:]" "[:lower:]" | sed -n "s/.*\($tmpos\).*/\1/p" | uniq`
	if [ ! -z "$os" ]
	then
		ver=`cat /etc/*release | tr "[:upper:]" "[:lower:]" | sed -n 's/.*release[^0-9.]*\([0-9.]*\)[^0-9.]*/\1/p' | uniq`
		break
	fi
done <<EOM
centos
red hat
ubuntu
EOM
}

os=
ver=
host=`hostname`
createtime=`date '+%Y%m%d%H%M'`
datadir=$basedir/source
sysdatafile=$datadir/batch_${host}_Linux_${createtime}.txt
proccpufile=$datadir/batch_${host}_LinuxProcessCPU_${createtime}.txt
procmemfile=$datadir/batch_${host}_LinuxProcessMEM_${createtime}.txt
kernparafile=$datadir/batch_${host}_sysctl_${createtime}.txt

get_os_type
case "$os" in
"ubuntu")
	salogdir=/var/log/sysstat
	;;
"red hat" | "centos")
	salogdir=/var/log/sa
	;;
*)
	;;
esac

mkdir -p -m 755 $datadir

yesterday=`date +%d -d yesterday`
#yesterday=$1
echo "`date '+DATE: %y%m%d%nTIME: %H%M%S'`"
echo "extract $yesterday sysstat & atop report"

echo "cpu core count : " >$sysdatafile
getconf _NPROCESSORS_ONLN >>$sysdatafile
# cat /proc/cpuinfo | egrep "core id|physical id" | tr -d "\n" | sed s/physical/\\nphysical/g | grep -v ^$ | sort | uniq | wc -l >>$sysdatafile
# grep --count processor /proc/cpuinfo >>$sysdatafile

echo "total memory : " >>$sysdatafile
grep MemTotal /proc/meminfo | awk '{print $2, $3}' >>$sysdatafile

# os
echo "os : " >>$sysdatafile
echo $os >>$sysdatafile

# version
echo "version : " >>$sysdatafile
echo $ver >>$sysdatafile
# dmidecode | grep "Product Name"

echo >>$sysdatafile
#LC_TIME="POSIX" sar -A -f $salogdir/sa$yesterday >>$sysdatafile
sar -A -f $salogdir/sa$yesterday >>$sysdatafile

atop -r y -g -c > $proccpufile
atop -r y -m -c > $procmemfile

/sbin/sysctl -a >$kernparafile

echo "clear old sysstat report data"
clearLogs $datadir $mtime 2>&1

echo "-------------------------"
