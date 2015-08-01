# java weblogic.WLST fmtServerMonitor.py

import sys
import re
import os
from java.lang import System

import getopt

username = ''
password = ''
admin_url = ''
iMax = 0
iSleep = 0
iIndex = 0

def usage():
  print "Usage:"
  print "ServerMonitor.py -u username -p password -a admin_url -m iMax -s iSleep"

def initArgs():
  global username, password, admin_url, iMax, iSleep
  try:
    opts, args = getopt.getopt(sys.argv[1:], "u:p:a:m:s:", ["username=", "password=", "admin_url=", "iMax=", "iSleep="])
  except getopt.GetoptError, err:
    print str(err)
    usage()
    sys.exit(2)

  for opt, arg in opts:
    if opt == "-u":
      username = arg
    elif opt == "-p":
      password = arg
    elif opt == "-a":
      admin_url = arg
    if opt == "-m":
      iMax = long(arg)
    elif opt == "-s":
      iSleep = long(arg)

  if username == "":
    print "Missing \"-u username\" parameter."
    usage()
    sys.exit(2)
  if password == "":
    print "Missing \"-p password\" parameter."
    usage()
    sys.exit(2)
  if admin_url == "":
    print "Missing \"-a admin_url\" parameter."
    usage()
    sys.exit(2)
  if iMax == 0:
    print "Missing \"-m iMax\" parameter."
    usage()
    sys.exit(2)
  if iSleep == 0:
    print "Missing \"-s iSleep\" parameter."
    usage()
    sys.exit(2)

def callerName() :
  "callerName() - Returns the name of the calling routine (or '?')"
  return sys._getframe( 1 ).f_code.co_name;

def trycd(path) :
  funName = callerName();              # Name of this function
  try:
    s = cmo
    cd(path) 
    return 1
  except WLSTException, e:
    # this typically means the server is not active, just ignore
    print '''An unexpected exception %s \nwas encountered 
      when cd(%s) from path(%s)''' % (str(e), path, s)
    return 0

def printSortedDictValues(dstFile, adict):
  df = java.text.SimpleDateFormat("MM/dd-HH:mm:ss")
  fmtdf = df.format(java.util.Date())
  adict.update({"0MM/dd-HH:mm:ss":fmtdf})
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

# definition to print a running servers jvm heap details
def print_heap_details(server_name):
  funName = callerName();              # Name of this function
  print '******************************FUNCTION : %s******************************' % funName
  cd('/ServerRuntimes/'+server_name+'/JVMRuntime/'+server_name)
  attrList = ['HeapFreeCurrent', 'HeapSizeCurrent', 'HeapSizeMax']
  valList = []
  for idx in range(len(attrList)):
    valList.append(`int(get(attrList[idx])/1024/1024)`)
  dictionary = dict(zip(attrList, valList))
  print "Heap Details for %s :" % server_name
  dstFile = server_name + '.Heap.csv'
  printSortedDictValues(dstFile, dictionary)
 
# definition to print a running servers thread details
def print_thread_details(server_name):
  funName = callerName();              # Name of this function
  print '******************************FUNCTION : %s******************************' % funName
  cd('/ServerRuntimes/'+server_name+'/ThreadPoolRuntime/ThreadPoolRuntime')
  attrList = ['Throughput', 'ExecuteThreadIdleCount', 'ExecuteThreadTotalCount', 'HoggingThreadCount', 'PendingUserRequestCount', 'QueueLength', 'StandbyThreadCount']
  # ExecuteThreadTotalCount : The total number of threads in the pool
  # Throughput : The mean number of requests completed per second.
  valList = []
  for idx in range(len(attrList)):
    valList.append(`get(attrList[idx])`)
  dictionary = dict(zip(attrList, valList))
  print "Thread Details for %s :" % server_name
  dstFile = server_name + '.Thread.csv'
  printSortedDictValues(dstFile, dictionary)

# definition to print a running servers jdbc details
def print_jdbc_details(server_name):
  funName = callerName();              # Name of this function
  print '******************************FUNCTION : %s******************************' % funName
  cd('/ServerRuntimes/'+server_name+'/JDBCServiceRuntime/'+server_name)
  dsList=cmo.getJDBCDataSourceRuntimeMBeans()
  for ds in dsList:  #cd("JDBCDataSourceRuntimeMBeans/"+dsList[0].getName())
    if 0 == trycd("JDBCDataSourceRuntimeMBeans/"+ds.getName()) :
      continue
    attrList = ['ActiveConnectionsCurrentCount', 'WaitingForConnectionCurrentCount', 'CurrCapacity', 'LeakedConnectionCount', 'NumAvailable', 'NumUnavailable', 'WaitingForConnectionCurrentCount']
    # ConnectionsTotalCount : The cumulative total number of database connections created in this data source since the data source was deployed
    # CurrCapacity : The current count of JDBC connections in the connection pool in the data source
    # NumAvailable : The number of database connections that are currently idle and available to be used by applications in this instance of the data source
    # Number Unavailable : The number of connections currently in use by applications or being tested in this instance of the data source.
    valList = []
    for idx in range(len(attrList)):
      valList.append(`get(attrList[idx])`)
    cd('../..')
    dictionary = dict(zip(attrList, valList))
    print "JDBC Details for %s :" % ds.getName()
    dstFile = server_name + '.' + ds.getName() + '.JDBC.csv'
    printSortedDictValues(dstFile, dictionary)

# definition to print a running servers details
def print_server_details(server_name):
  funName = callerName();              # Name of this function
  print '******************************FUNCTION : %s******************************' % funName
  if 0 == trycd("/ServerRuntimes/"+server_name) :
    return
  print '------------------------------Server %s Runtime Details------------------------------' % server_name
#    print('State:: ' + str(cmo.getState()))
#    print('Open Sockets:: ' + str(cmo.getOpenSocketsCurrentCount()))
#    print ''
  print_heap_details(server_name)
  print_thread_details(server_name)
  print_jdbc_details(server_name)

def main():
  try:
    global username, password, admin_url, iIndex, iMax, iSleep
    initArgs();
    #redirect('./fmtServerMonitor.log', 'false')
    print 'Connecting WebLogic at ' + admin_url
    connect(username, password, admin_url)
    domainConfig()  
    serverlist=cmo.getServers()  
    domainRuntime()
    while iIndex < iMax:
      for svr in serverlist:  
        server_name = svr.getName()
        print_server_details(server_name)
      iIndex += 1
      java.lang.Thread.currentThread().sleep(iSleep)
    disconnect()
    sys.exit(0)
  except Exception, e:
    print "An unexpected exception was encountered: %s" % str(e)
    sys.exit(1)

if __name__== "main":  
  main()
