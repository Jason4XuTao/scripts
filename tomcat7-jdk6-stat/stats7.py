
# Jython 'unknown enocoding gb13030' on japanese system
# java -jar jython-standalone-2.7.0.jar -C utf-8 stats.py -h localhost -l 8999 -m 10 -s 30000
# export CATALINA_OPTS="-Dcom.sun.management.jmxremote -Djava.rmi.server.hostname=127.0.0.1 -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;
import javax.management.ObjectName as ObjectName;
import java.lang.management.ManagementFactory;
import sys, cmd, socket, optparse
from java.lang import System
from urlparse import urljoin
from cmd import Cmd
from time import localtime, strftime
import os
import re
import getopt

host = '127.0.0.1'
port = 8999
iMax = 12
iSleep = 30000
iIndex = 0

def usage():
    print "Usage:"
    print "stats.py -h host -l port -m iMax -s iSleep"
    sys.exit(2)

def initArgs():
    global host, port, iMax, iSleep
    try:
        opts, args = getopt.getopt(sys.argv[1:], "h:l:m:s:", ["host=", "port=", "iMax=", "iSleep="])
        for opt, arg in opts:
            if opt == "-h":
                host = arg
            if opt == "-l":
                port = arg
            if opt == "-m":
                iMax = long(arg)
            elif opt == "-s":
                iSleep = long(arg)
      
        if host == "":
            print "Missing \"-h host\" parameter."
            usage()
        if port == 0:
            print "Missing \"-l port\" parameter."
            usage()
        if iMax == 0:
            print "Missing \"-m iMax\" parameter."
            usage()
        if iSleep == 0:
            print "Missing \"-s iSleep\" parameter."
            usage()

        print "parameters: %s, %s, %s, %s" % (host, port, iMax, iSleep)
    except getopt.GetoptError, err:
        print str(err)
        usage()
  
def printSortedDictValues(dstFile, adict):
    try:
        adict.update({"0MM/dd-HH:mm":strftime("%d/%m-%H:%M", localtime())})
        items = adict.items()
        items.sort()
        keys = adict.keys()
        keys.sort()
        if not os.path.exists(dstFile):
            ff = open(dstFile, "w")
            print >>ff, ",".join(keys)
            ff.close()
        f = open(dstFile, "a")
        print >>f, ",".join([value for key, value in items])
        f.close()
        print ",".join(keys)
        print ",".join([value for key, value in items])
    except Exception, e:
        print "An unexpected exception was encountered: %s" % str(e)
        sys.exit(1)

def init_mbsc(host, port):
    serviceURL = str()
    serviceURL = "service:jmx:rmi:///jndi/rmi://"
    serviceURL = serviceURL + host + ":" + str(port) + "/jmxrmi"
    url =  javax.management.remote.JMXServiceURL(serviceURL);
    global connector, remote
    connector = javax.management.remote.JMXConnectorFactory.connect(url);
    remote = connector.getMBeanServerConnection();

def get_attribute(mbean, attribute):
    obn = javax.management.ObjectName(mbean);
    return remote.getAttribute(obn, attribute);

def stats(server_name):
    typeExp = re.compile(".*(type=\w+).*", re.IGNORECASE)
#    nameExp = re.compile(r'name=\w+(?:-\w+)+', re.IGNORECASE) #".*(name=\w+).*"
    domainList = remote.getDomains()
    for domEle in domainList:
        str = domEle + ":*"
        for ele in remote.queryMBeans(ObjectName(str),None):
#            print "------------------"
#            print ele
            type = None
            name = None
            context = None
            m = re.match(typeExp, ele.toString())
            if(m):
                type = re.split('=', m.group(1))[1]
            if(re.findall(r'name=[^,]+', ele.toString())):
                name = re.split('=', re.findall(r'name=[^,]+', ele.toString())[0])[1]
                if name[-1] == ']':
                    name = name[:-1]
            if(re.findall(r'context=[^,]+', ele.toString())):
                context = re.split('=', re.findall(r'context=[^,]+', ele.toString())[0])[1]
                if context[-1] == ']':
                    context = context[:-1]
#            if(type and name):
#                print "type:%s, name:%s" % (type, name)
#            elif(type and context):
#                print "type:%s, context:%s" % (type, context)
#            else:
#                print "type:%s" % type
            if(type.lower() == "threadpool"):
                print "type:%s, name:%s" % (type, name)
                objName = ObjectName(ele.getObjectName().getCanonicalName())
                attrList = ['currentThreadCount', 'currentThreadsBusy', 'maxThreads']
                valList = []
                for idx in range(len(attrList)):
                    valList.append(`remote.getAttribute(objName, attrList[idx])`)
                dictionary = dict(zip(attrList, valList))
#                print "Thread Details for %s :" % server_name
                dstFile = server_name + '.Thread.' + name.replace('\"','') + '.csv'
                printSortedDictValues(dstFile, dictionary)
            elif(type.lower() == "datasource"):
                print "type:%s, name:%s, context:%s" % (type, name, context)
                objName = ObjectName(ele.getObjectName().getCanonicalName())
                attrList = ['numActive', 'numIdle']
                valList = []
                for idx in range(len(attrList)):
                    valList.append(`remote.getAttribute(objName, attrList[idx])`)
                dictionary = dict(zip(attrList, valList))
#                print "DataSource Details for %s:%s:%s" % (server_name, name, context)
                dstFile = server_name + '.' + context.replace('/','') + '.DS.' + name.replace('\"','').replace('/','') + '.csv'
                printSortedDictValues(dstFile, dictionary)
            elif(type.lower() == "manager"):
                objName = ObjectName(ele.getObjectName().getCanonicalName())
                attrList = ['sessionCounter', 'activeSessions', 'maxActiveSessions']
                valList = []
                for idx in range(len(attrList)):
                    valList.append(`remote.getAttribute(objName, attrList[idx])`)
                dictionary = dict(zip(attrList, valList))
                print "Session Details for %s:%s" % (server_name, context)
                dstFile = server_name + '.APP.' + context.replace('/','') + '.csv'
                printSortedDictValues(dstFile, dictionary)
            elif(type.lower() == "memory"):
                objName = ObjectName(ele.getObjectName().getCanonicalName())
                obj = remote.getAttribute(objName, "HeapMemoryUsage")
                attrList = ['init', 'committed', 'used', 'max']
                valList = []
                for idx in range(len(attrList)):
                    valList.append(`int(obj.get(attrList[idx])/1024/1024)`)
                dictionary = dict(zip(attrList, valList))
                print "Heap Details for %s" % server_name
                dstFile = server_name + '.Heap.csv'
                printSortedDictValues(dstFile, dictionary)

try:
    #global host, port, iIndex, iMax, iSleep
    initArgs();
    print 'Connecting Tomcat at ' + host + ":" + str(port)
    init_mbsc(host, port)
    while iIndex < iMax:
        server_name = host + "_" + str(port)
        stats(server_name)
        print "="*25
        iIndex += 1
        java.lang.Thread.currentThread().sleep(iSleep)
    connector.close()
except Exception, e:
    print "An unexpected exception was encountered: %s" % str(e)
    sys.exit(1)
