#!/bin/bash

basedir=/root/scripts/linux-perf-coll
pickinterval=1
schedjob="1 0 * * * $basedir/po4linux.sh"

# Use process substitution with & redirection and exec
log=$basedir/`basename $0 .sh`.log
exec > >(tee $log)
exec 2>&1

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

function cmp_version
{
	curver=$1
	dstver=$2
	curmajor=$(echo $curver | cut -d. -f1)
	dstmajor=$(echo $dstver | cut -d. -f1)
#	echo "curmajor:$curmajor dstmajor:$dstmajor"
	if [ $curmajor -gt $dstmajor ]
	then
		return 0
	elif [ $curmajor -lt $dstmajor ]
	then
		return 1
	fi
	
	curminor=$(echo $curver | cut -d. -f2)
	dstminor=$(echo $dstver | cut -d. -f2)
#	echo "curminor:$dstminor curminor:$dstminor"
	if [ $curminor -gt $dstminor ]
	then
		return 0
	elif [ $curminor -lt $dstminor ]
	then
		return 1
	fi
	
	curmicro=$(echo $curver | cut -d. -f3)
	dstmicro=$(echo $dstver | cut -d. -f3)
#	echo "curmicro:$dstmicro curmicro:$dstmicro"
	if [ $curmicro -gt $dstmicro ]
	then
		return 0
	elif [ $curmicro -le $dstmicro ]
	then
		return 1
	fi
}

function init_sysstat
{
	echo "function init_sysstat"
	case "$os" in
	"ubuntu")
#		dpkg-query -l sysstat
		which sar >/dev/null 2>&1
		rc=$?
		if [ $rc -eq 0 ]
		then
			pkgver=`sar -V 2>&1 | sed -n 's/sysstat version \(.*\)/\1/p'`
			echo "sysstat $pkgver is already installed"
		else
			echo "sysstat is not installed"
			cd $basedir/soft
			if [ "$arch" != "64" ]
			then
				pkgname=`ls sysstat* | grep deb | grep -v 64`
			else
				pkgname=`ls sysstat* | grep deb | grep 64`
			fi
			pkgver=`echo $pkgname | sed -n 's/sysstat[-_]\([0-9.]*\)-.*/\1/p'`
			echo "installing $pkgname version $pkgver"
			sudo -i dpkg -i $basedir/soft/$pkgname
		fi

		sudo -i sed -i -e 's/HISTORY=.*/HISTORY=31/' /etc/sysstat/sysstat
		cmp_version $pkgver "8.1.3"
		rc=$?
		if [ $rc -eq 0 ]
		then
			echo "The version of sysstat is $pkgver, bigger than 8.1.3!"
			#SADC_OPTIONS="-S DISK"
		else
			echo "The version of sysstat is $pkgver, lower than 8.1.3, so add SADC_OPTIONS for sadc!"
			sudo -i sed -i -e 's/SADC_OPTIONS=.*/SADC_OPTIONS="-d"/' /etc/sysstat/sysstat
			grep -q -F 'SADC_OPTIONS="-d"' /etc/sysstat/sysstat || sudo -i echo 'SADC_OPTIONS="-d"' >> /etc/sysstat/sysstat
		fi
		sudo -i sed -i -e 's/ENABLED="false"/ENABLED="true"/' /etc/default/sysstat
		sudo -i sed -i -e "s#.*/[0-9]* \(.*debian-sa1.*\)#\*/$pickinterval \1#" /etc/cron.d/sysstat
		;;
	"red hat" | "centos")
#		rpm -q sysstat >/dev/null
		which sar >/dev/null 2>&1
		rc=$?
		if [ $rc -eq 0 ]
		then
			pkgver=`sar -V 2>&1 | sed -n 's/sysstat version \(.*\)/\1/p'`
			echo "sysstat $pkgver is already installed"
		else
			echo "sysstat is not installed"
			cd $basedir/soft
			tmposver=`uname -r | sed -n "s/[0-9.-]*\([a-z].*\)/\1/p"`
			if [ "$arch" != "64" ]
			then
				pkgname=`ls sysstat* | grep $tmposver | grep -v 64`
			else
				pkgname=`ls sysstat* | grep $tmposver | grep 64`
			fi
			pkgver=`echo $pkgname | sed -n 's/sysstat[-_]\([0-9.]*\)-.*/\1/p'`
			echo "installing $pkgname version $pkgver"
			rpm -ivh $basedir/soft/$pkgname
		fi
		
		sed -i -e 's/HISTORY=.*/HISTORY=31/' /etc/sysconfig/sysstat
		cmp_version $pkgver "8.1.3"
		rc=$?
		if [ $rc -eq 0 ]
		then
			echo "The version of sysstat is $pkgver, bigger than 8.1.3!"
			#SADC_OPTIONS="-S DISK"
		else
			echo "The version of sysstat is $pkgver, lower than 8.1.3, so add SADC_OPTIONS for sadc!"
			grep -q -F 'SADC_OPTIONS="-d"' /etc/sysconfig/sysstat || echo 'SADC_OPTIONS="-d"' >> /etc/sysconfig/sysstat
		fi
		sed -i -e "s#\*/[0-9]* \(.*\)#\*/$pickinterval \1#" /etc/cron.d/sysstat
		;;
	*)
		;;
	esac
}

function init_atop
{
	echo "function init_atop"
	case "$os" in
	"ubuntu")
		which atop >/dev/null 2>&1
		rc=$?
		if [ $rc -eq 0 ]
		then
			pkgver=`atop -V 2>&1 | cut -d' ' -f2`
			echo "atop $pkgver is already installed"
		else
			echo "atop is not installed"
			cd $basedir/soft
			if [ "$arch" != "64" ]
			then
				pkgname=`ls atop* | grep deb | grep -v 64`
			else
				pkgname=`ls atop* | grep deb | grep 64`
			fi
			pkgver=`echo $pkgname | sed -n 's/atop[-_]\([0-9.]*\)-.*/\1/p'`
			echo "installing $pkgname version $pkgver"
			sudo -i dpkg -i $basedir/soft/$pkgname
		fi

		pickinterval=`expr $pickinterval \* 60`
		sudo -i sed -i -e "s/INTERVAL=.*/INTERVAL=$pickinterval/" /etc/default/atop
		;;
	"red hat" | "centos")
		which atop >/dev/null 2>&1
		rc=$?
		if [ $rc -eq 0 ]
		then
			pkgver=`atop -V 2>&1 | cut -d' ' -f2`
			echo "atop $pkgver is already installed"
		else
			echo "atop is not installed"
			cd $basedir/soft
			if [ "$arch" != "64" ]
			then
				pkgname=`ls atop* | grep rpm | grep -v 64`
			else
				pkgname=`ls atop* | grep rpm | grep 64`
			fi
			pkgver=`echo $pkgname | sed -n 's/atop[-_]\([0-9.]*\)-.*/\1/p'`
			echo "installing $pkgname version $pkgver"
			rpm -ivh $basedir/soft/$pkgname
		fi

		pickinterval=`expr $pickinterval \* 60`
		sed -i -e "s/INTERVAL=.*/INTERVAL=$pickinterval/" /etc/atop/atop.daily
		;;
	*)
		;;
	esac
}

function init_cron
{
	echo "function init_cron"
	cd $basedir
	crontab -l > cron.tmp
	shellname=`echo "$schedjob" | sed -n 's#.*/\([a-zA-Z0-9]*\.sh\).*#\1#p'`
	grep -q "$shellname" cron.tmp
	rc=$?
	if [ $rc -eq 0 ]
	then
		sed -i -n "#$shellname#d" cron.tmp
	fi
	echo "$schedjob" >> cron.tmp
	crontab cron.tmp
	rm cron.tmp
}

os=
ver=
arch=`getconf LONG_BIT`
pkgname=

uname=`uname | tr "[:upper:]" "[:lower:]"`
if [ "linux" = "$uname" ]
then
	get_os_type
	echo "os:${os}; version:${ver}; arch:${arch}bit"
	init_sysstat
	init_atop
	init_cron
fi
