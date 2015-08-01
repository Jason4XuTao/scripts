# export CATALINA_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

##### set environment #####
export JAVA_HOME=/etc/alternatives/java_sdk
export PATH=${JAVA_HOME}/bin/:$PATH
which java

##### set arguments #####
username=monitorRole
password=monpass
host=127.0.0.1
port=8999
iMax=1
iSleep=60000

COLL_HOME=/opt/apache-tomcat-7.0.56/test
cd $COLL_HOME

java -jar jython-standalone-2.7.0.jar stats7.py -h $host -l $port -m $iMax -s $iSleep  # 1>stats.log 2>&1
# java -jar jython-standalone-2.7.0.jar statsSecur.py -u $username -p $password -h $host -l $port -m $iMax -s $iSleep

