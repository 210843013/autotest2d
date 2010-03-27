#!/bin/bash

PROCES=1
ROUNDS=100
GAME_LOGGING="true"
TEXT_LOGGING="false"

###############

RESULT_DIR="result.d"
SUPPORT_HOST_OPTION="false"

server() {
	ulimit -t 180
	rcssserver $*
}

killall_server() {
    exec 2>/dev/null

    killall -9 rcssserver
    killall -9 rcssserver.bin
}

test_host_option() {
    OPTION="-server::host=\"127.0.0.1\""
    killall_server
    server $OPTION &
    if [ `ps -o pid= -C rcssserver | wc -l` -gt 0 ]; then
        SUPPORT_HOST_OPTION="true"
    fi
    killall_server
}

match() {
    SERVER_HOST=$1
	LOGDIR="log_$SERVER_HOST"

	OPTIONS=""
	OPTIONS="$OPTIONS -server::game_log_dir=\"./$LOGDIR/\""
	OPTIONS="$OPTIONS -server::text_log_dir=\"./$LOGDIR/\""
	OPTIONS="$OPTIONS -server::team_l_start=\"./start_left $SERVER_HOST\""
	OPTIONS="$OPTIONS -server::team_r_start=\"./start_right $SERVER_HOST\""
	OPTIONS="$OPTIONS -server::nr_normal_halfs=2 -server::nr_extra_halfs=0"
	OPTIONS="$OPTIONS -server::penalty_shoot_outs=false -server::auto_mode=on"
	OPTIONS="$OPTIONS -server::game_logging=$GAME_LOGGING -server::text_logging=$TEXT_LOGGING"

    if [ $SUPPORT_HOST_OPTION = "true" ]; then
        OPTIONS="$OPTIONS -server::host=\"$SERVER_HOST\""
    fi

    if [ $GAME_LOGGING = "true" ] || [ $TEXT_LOGGING = "true" ]; then
        mkdir $LOGDIR
    fi

	for i in `seq 1 $ROUNDS`; do
        RESULT="$RESULT_DIR/result_${SERVER_HOST}_$i"
        server $OPTIONS 1>$RESULT 2>&1
		sleep 5
	done
}

autotest() {
    export LANG=POSIX
	./clear.sh

    mkdir $RESULT_DIR
	TOTAL_ROUNDS=`expr $PROCES '*' $ROUNDS`
	echo $TOTAL_ROUNDS > $RESULT_DIR/total_rounds

    IP_PATTERN='192\.168\.[0-9]\{1,3\}\.[0-9]\{1,3\}'
    SERVER_HOSTS=(`ifconfig | grep -o "inet addr:$IP_PATTERN" | grep -o "$IP_PATTERN"`)

    test_host_option

    if [ $PROCES -gt 1 ]; then
        i=0
        while [ $i -lt $PROCES ] && [ $i -lt ${#SERVER_HOSTS[@]} ]; do
            match ${SERVER_HOSTS[$i]} &
            i=`expr $i + 1`
            sleep 30
        done
    else
        if [ $SUPPORT_HOST_OPTION = "true" ] && [ ${#SERVER_HOSTS[@]} -gt 0 ]; then
           match ${SERVER_HOSTS[0]} &
        else
            match localhost &
        fi
    fi
}

if [ $# -gt 0 ]; then
	autotest
else
	$0 $# &
fi

