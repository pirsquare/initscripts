#!/bin/bash
#
# /etc/rc.d/init.d/td-agent
#
# chkconfig: - 80 20
# description: td-agent
# processname: td-agent
# pidfile: /var/run/td-agent/td-agent.pid
#
### BEGIN INIT INFO
# Provides:          td-agent
# Default-Stop:      0 1 6
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# Short-Description: td-agent's init script
# Description:       td-agent is a data collector
### END INIT INFO

# Source function library.
. /etc/init.d/functions

name="td-agent"
prog="td-agent"
process_bin=/opt/td-agent/embedded/bin/ruby

# timeout can be overridden from /etc/sysconfig/td-agent
STOPTIMEOUT=120

if [ -f /etc/sysconfig/$prog ]; then
        . /etc/sysconfig/$prog
fi
PIDFILE=${PIDFILE-/var/run/td-agent/$prog.pid}
DAEMON_ARGS=${DAEMON_ARGS---user td-agent}
TD_AGENT_ARGS="${TD_AGENT_ARGS-/usr/sbin/td-agent --group td-agent --log /var/log/td-agent/td-agent.log --use-v1-config}"

if [ -n "${PIDFILE}" ]; then
        PIDFILE_DIR=$(dirname ${PIDFILE})
        if [ ! -e $PIDFILE_DIR ]; then
                mkdir -p $PIDFILE_DIR
        fi
        chown -R td-agent:td-agent $PIDFILE_DIR
        TD_AGENT_ARGS="${TD_AGENT_ARGS} --daemon ${PIDFILE}"
fi

# 2012/04/17 Kazuki Ohta <k@treasure-data.com>
# use jemalloc to avoid fragmentation
if [ -f "/opt/td-agent/embedded/lib/libjemalloc.so" ]; then
        export LD_PRELOAD=/opt/td-agent/embedded/lib/libjemalloc.so
fi

RETVAL=0

start() {
        # Set Max number of file descriptors for the safety sake
        # see http://docs.fluentd.org/en/articles/before-install
        ulimit -n 65536
        echo -n "Starting $name: "
        daemon --pidfile=$PIDFILE $DAEMON_ARGS $process_bin "$TD_AGENT_ARGS"
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch /var/lock/subsys/$prog
        return $RETVAL
}

stop() {
        echo -n "Shutting down $name: "
        if [ -e "${PIDFILE}" ]; then
            # Use own process termination instead of killproc because killproc can't wait SIGTERM
            TD_AGENT_PID=`cat "$PIDFILE" 2>/dev/null`
            if [ -n "$TD_AGENT_PID" ]; then
                /bin/kill "$TD_AGENT_PID" >/dev/null 2>&1
                RETVAL=$?
                if [ $RETVAL -eq 0 ]; then
                    TIMEOUT="$STOPTIMEOUT"
                    while [ $TIMEOUT -gt 0 ]; do
                        /bin/kill -0 "$TD_AGENT_PID" >/dev/null 2>&1 || break
                        sleep 1
                        let TIMEOUT=${TIMEOUT}-1
                    done
                    if [ $TIMEOUT -eq 0 ]; then
                        echo -n "Timeout error occurred trying to stop td-agent..."
                        RETVAL=1
                        failure
                    else
                        RETVAL=0
                        success
                    fi
                else
                    failure
                fi
            else
                failure
                RETVAL=4
            fi
        else
            killproc $prog
            RETVAL=$?
            if [ $RETVAL -eq 0 ]; then
                success
            else
                failure
            fi
        fi
        echo
        [ $RETVAL -eq 0 ] && rm -f $PIDFILE && rm -f /var/lock/subsys/$prog
        return $RETVAL
}

restart() {
        configtest || return $?
        stop
        start
}

reload() {
        configtest || return $?
        echo -n "Reloading $name: "
        killproc $process_bin -HUP
        RETVAL=$?
        echo
}

configtest() {
        eval "$TD_AGENT_ARGS $DAEMON_ARGS --dry-run -q"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    reload)
        reload
        ;;
    condrestart)
        [ -f /var/lock/subsys/$prog ] && restart || :
        ;;
    configtest)
        configtest
        ;;
    status)
        status -p $PIDFILE 'td-agent'
        ;;
    *)
        echo "Usage: $prog {start|stop|reload|restart|condrestart|status|configtest}"
        exit 1
        ;;
esac
exit $?