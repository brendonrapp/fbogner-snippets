#!/bin/bash

SERVER_IP="10.39.1.151"
SERVER_NAME="Fileserver" # will be shown in Finder's sidebar
SERVICE_TYPE="_smb._tcp"
SERVICE_PORT=445

############ DO NOT EDIT BELOW THIS LINE ############
SLEEP_INTERVAL=5
PID=""
DNSSD_RUNNING=1

while [ true ]; do

	echo "Pinging $SERVER_IP..."
	ping -c 1 "$SERVER_IP" 1>2 2>/dev/null	#ping the server
	
	if [ "$?" -eq "0" ]; then	#and check if it's available
		# server reachable
		echo "$SERVER_IP is alive"
		
		kill -0 "$PID" 1>2 2>/dev/null	#check if dns proxy is still running
		DNSSD_RUNNING=$?
		
		if [ "$DNSSD_RUNNING" -ne "0" ]; then	# if we dont have a running dns-sd instance start it
			echo "Starting DNS SD Proxy for service $SERVICE_TYPE on server $SERVER_NAME"
			dns-sd -P "$SERVER_NAME" "$SERVICE_TYPE" local $SERVICE_PORT "$SERVER_NAME.local" "$SERVER_IP" 1>2 2>/dev/null &
			PID=$!;
		else 
			echo "DNS SD Proxy for service $SERVICE_TYPE on server $SERVER_NAME is already running"
		fi
	else	
		# server not reachable
		echo "$SERVER_IP is not alive"
		
		if [ ! "$PID" = "" ]; then	# if we have a running dns-sd instance stop it
			echo "Stopping DNS SD Proxy for service $SERVICE_TYPE on server $SERVER_NAME"
			kill "$PID" 1>2 2>/dev/null
			PID="";
		else 
			echo "DNS SD Proxy for service $SERVICE_TYPE on server $SERVER_NAME is not running"
		fi
	fi

	sleep $SLEEP_INTERVAL
done