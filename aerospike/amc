#!/bin/sh

# chkconfig: 2345 95 20
# description: Start daemon at boot time
# Enable service provided by daemon.
# processname: amc

PROJECT="/opt/amc"
PIDFILE="/tmp/amc.pid"
CRONJOB="${PROJECT}/bin/start_amc_cron.sh"
GUNICORN="${PROJECT}/bin/gunicorn"
CONFIG="${PROJECT}/config/gunicorn_config.py"

CMD="${GUNICORN} --daemon --config=${CONFIG} flaskapp:app"

default="\033[0;39m"
red="\033[0;31m"
green="\033[0;32m"

check_amc_status(){
    status=1
    if [ -z "`ps aux | grep amc | grep -v grep | grep gunicorn | grep master`" ]; then
        status=0
    fi
    echo $status
}

check_cronjob_status(){
    status=1
    if [ -z "`ps aux | grep ${CRONJOB} | grep -v grep`" ]; then
        status=0
    fi
    echo $status
}

start_amc(){
  status=$(check_amc_status)
  if [ $status -eq 0 ] ; then
      port_check=$(netstat -ln | grep ':8081 ' | grep LISTEN)
      if [ "$port_check" = "" ]
      then
        rm -f $PIDFILE
        $CMD
        if [ $? = 0 ]; then
          echo -e "AMC is ${green}started${default}."
        else
          echo -e "AMC ${red}failed${default}."
        fi
      else
        echo "Port 8081 is being used, please unlock the port and try to start it again."
        exit 1
      fi
  else
    echo -e "AMC is ${red}running${default}."
    exit 1
  fi
}

stop_amc(){
  status=$(check_amc_status)
  if [ $status -eq 0 ] ; then
    echo -e "AMC is ${red}not running${default}."
  else
    kill -9 `cat $PIDFILE`
    kill -9 `ps aux | grep amc | grep -v grep | grep worker | awk '{print $2}'`
    $(remove_cron) 
    if [ $? = 0 ]; then
      echo -e "AMC is ${green}stopped${default}."
      rm -f $PIDFILE
    else
      echo -e "AMC ${red}could not be stopped${default}."
    fi
  fi
}

amc_status(){
  status=$(check_amc_status)
  if [ $status -eq 0 ] ; then
    echo -e "AMC is ${red}not running${default}."
  else
    echo -e "AMC is ${green}running${default}."
  fi
}

start_cron(){
    status=$(check_cronjob_status)
    if [ $status -eq 0 ]; then
       sh $CRONJOB
    fi
}

remove_cron(){
    echo 1 > /opt/amc/stop_signal
}

# Carry out specific functions when asked to by the system
case "$1" in
    start)
        python_version=$(python -c 'import sys; print int(sys.version_info[0:2] > (2, 5) and sys.version_info[0:2] < (3,))')
        if [ $python_version -ne 0 ]; then
            echo "Starting AMC...."
            output=$(start_amc)
            echo "$output"
            sleep 1
            $(start_cron) &
        else
            echo "Unable to start the AMC, unsupported Python version found. Please update the Python version to 2.6 or 2.7"
        fi
    ;;
    stop)
	    echo "Stopping AMC...."
	    output=$(stop_amc)
            $(remove_cron)
	    echo "$output"
    ;;
    status)
            echo "Retrieving AMC status...."
	    output=$(amc_status)
            echo "$output"
    ;;
    restart)
	    echo "Restarting AMC...."
	    output="$(stop_amc)"
            echo "$output"
            sleep 1
            python_version=$(python -c 'import sys; print int(sys.version_info[0:2] > (2, 5) and sys.version_info[0:2] < (3,))')
            if [ $python_version -ne 0 ]; then
                output=$(start_amc)
                sleep 1
                $(start_cron) &
                echo "$output"   
            else
                echo "Unable to restart the AMC, unsupported Python version found. Please update the Python version to 2.6 or 2.7"
            fi
    ;;
    --help)
           cat ${PROJECT}/README
    ;;
    --version)
           cat ${PROJECT}/amc_version
           echo
    ;;
    *)
        echo "Usage: /etc/init.d/amc {start|stop|restart|status}"
        exit 1
    ;;
        
esac

exit 0

