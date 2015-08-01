# export CATALINA_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
# export CATALINA_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=192.168.234.147 -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=true -Dcom.sun.management.jmxremote.password.file=../conf/password.txt -Dcom.sun.management.jmxremote.access.file=../conf/access.txt"

##### set environment #####
#export JAVA_HOME=/etc/alternatives/java_sdk
#export PATH=${JAVA_HOME}/bin/:$PATH
which java

##### set arguments #####
username=monitorRole
password=monpass
host=127.0.0.1
port=8999
iMax=3
iSleep=60000

COLL_HOME=/opt/apache-tomcat-6.0.41/test
cd $COLL_HOME

java -jar jython-standalone-2.5.3.jar stats6.py -h $host -l $port -m $iMax -s $iSleep  # 1>stats.log 2>&1

