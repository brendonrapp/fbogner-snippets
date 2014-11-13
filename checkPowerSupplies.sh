#!/bin/sh

VERSION=1

# getopts is based on http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# A POSIX variable
OPTIND=1         		# Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
EXPECTED_POWER_SUPPLIES=2	# Default number of power supplies
SUCCESS_RESULT="0x1"		# Default result if a power supply is working


while getopts "hpr:" opt; do
    case "$opt" in
    h)
		echo "This tool checks the state of all installed power supplies and reports their current state. It can be used in automated monitoring tools like nagios."
		echo "It depends on ipmitool and supports all systems that report the state of the installed power supplies through the sensors subcommand. I used it primarily on Supermicro X9 class motherboards."
		echo ""
    	echo "Usage: $0"
		echo "	-h 	Shows this help"
		echo "	-p=2	The number of expected power supplies"
		echo "	-r=0x1	The value that indicates a working power supply (see ipmitool sensors)"
		echo ""
		echo "Example:"
		echo "$0 -p=3 	# Check 3 installed power supplies"
		echo "$0		# Check 2 installed power supplies"
		echo "$0 -r=0x4	# A working power supply reports a state of 0x4" 
		echo ""
		echo "Exit codes:"
		echo "	0	All power supplies are working"
		echo "	1	ipmitool is not installed"
		echo "	2	Found more power supplies than expected"
		echo "	3	At least one power supply is missing"
		echo "	4	At least one power supply failed"
		echo ""
		echo "Version $VERSION released in 2014 by Florian Bogner - http://bogner.sh"
        exit 0
        ;;
    p)  EXPECTED_POWER_SUPPLIES=$2
        ;;
    r)  SUCCESS_RESULT=$2
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# check if ipmitool exists
if ! hash ipmitool; then
	echo "ipmitool is not installed"
	exit 1
fi

# detect all installed power supplies
POWER_SUPPLY_STATES=$(ipmitool sensor|grep 'PS[0-9]\+ Status'|cut -d'|' -f2 2>/dev/null)
FOUND_POWER_SUPPLIES=$(echo "$POWER_SUPPLY_STATES" | wc -l)

if [ $FOUND_POWER_SUPPLIES -gt $EXPECTED_POWER_SUPPLIES ]; then
	echo "We found $FOUND_POWER_SUPPLIES power supplies but expected only $EXPECTED_POWER_SUPPLIES"
	echo "Use the -p option to specify the correct number"
	exit 2
elif [ $FOUND_POWER_SUPPLIES -lt $EXPECTED_POWER_SUPPLIES ]; then
	echo "We found $FOUND_POWER_SUPPLIES power supplies but expected $EXPECTED_POWER_SUPPLIES"
	echo "At least one power supply is missing"
	exit 3
fi

# check the power supply state
WORKING_SUPPLIES=0

while read -r STATE; do
    
	STATE=$(echo "$STATE"| tr - ' ')	# trim

	
	if [ "$STATE" == "$SUCCESS_RESULT" ]; then
		WORKING_SUPPLIES=$((WORKING_SUPPLIES+1))
	fi 

done <<< "$POWER_SUPPLY_STATES"

if [ $EXPECTED_POWER_SUPPLIES -ne $WORKING_SUPPLIES ]; then
	echo "There are $WORKING_SUPPLIES working power supplies but we have $EXPECTED_POWER_SUPPLIES installed"
        echo "At least one power supply failed"
        exit 4
fi

# everything is fine
echo "All $EXPECTED_POWER_SUPPLIES power supplies are working as expected"
exit 0
