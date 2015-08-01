##### set environment for wlst #####
WL_HOME=/opt/Middleware/wlserver_12.1
JAVA_HOME=/usr/lib/jvm/jre-1.6.0-openjdk.x86_64
export CLASSPATH=${WL_HOME}/server/lib/weblogic.jar:$CLASSPATH
export PATH=${JAVA_HOME}/bin/:$PATH
echo $CLASSPATH
which java

##### set AdminServer info #####
username=weblogic
password=welcome1
admin_url=t3://127.0.0.1:7011
iMax=5
iSleep=60000

COLL_HOME=/root/scripts/weblogic12-jdk6-stat
cd $COLL_HOME

java weblogic.WLST ${COLL_HOME}/serverMonitor.py -u $username -p $password -a $admin_url -m $iMax -s $iSleep # 2>&1 1>wlst.log
