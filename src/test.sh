#!/bin/sh

INPUT_DIR=/tmp2
TEST_DIR=/tmp2/test
TEST_CASES="50k 100k 200k 400k 800k 1m 2m 4m 8m 15m"
ONLY_PC=0
RETEST=0
IMMEDIATE_START=0

export INPUT_DIR

echo "TEST_DIR=$TEST_DIR"
echo "INPUT_DIR=$INPUT_DIR"
echo "TEST_CASES=$TEST_CASES"

for i in $*
do
	if [ "$i" = "only_pc" ]; then
		ONLY_PC=1
	fi
	if [ "$i" = "retest" ]; then
		RETEST=1
	fi
	if [ "$i" = "start" ]; then
		IMMEDIATE_START=1
	fi
done

if [ $ONLY_PC = 1 ]; then
	echo "ONLY_PC!!!"
fi

if [ $RETEST = 1 ]; then
	echo "RE-TEST MODE!!!"
	if [ ! -d "$TEST_DIR" ]; then
		echo "$TEST_DIR does not exists!!"
		echo "TEST_DIR should exist for re-test mode!"
		exit 1;
	fi
else
	if [ $IMMEDIATE_START = 1 ]; then #WARNING: immediate start assumes removing test directory!
		rm -rf $TEST_DIR
	elif [ -d "$TEST_DIR" ]; then
		# Control will enter here if $DIRECTORY exists
		read -p "Do you want to delete '$TEST_DIR?' [y/n] " -n 1
		echo ""
		if [[ ! $REPLY =~ ^[Yy]$ ]]
		then
			rm -rf $TEST_DIR
		fi
	fi
fi


if [ ! -d "$TEST_DIR" ]; then
	# Control will enter here if $DIRECTORY doesn't exist
	mkdir -p $TEST_DIR
fi

if [ $IMMEDIATE_START != 1 ]; then
	read -p "Press any key to start tests..."
fi
echo "Starting tests..."

for i in $TEST_CASES
do
	PC=${i/k/000}
	PC=${PC/m/000000}
	PCM=$(($PC*5))
	INFILE=${TEST_DIR}/${i}_input.txt
	GENINPUT_OUTFILE=${TEST_DIR}/${i}_geninput_out.txt
	if [ $ONLY_PC = 1 ]; then
		OUTFILE=${TEST_DIR}/${i}_out_pc.txt
	else
		OUTFILE=${TEST_DIR}/${i}_out.txt
	fi
	echo "================================================================================================="
	echo "Running for $i points"
	echo "================================================================================================="
	make test_clean > /dev/null
	if [ $RETEST != 1 ]; then
		echo "Generating input..."
		make -C gen_input all POINT_COUNT=$PC POINT_COORD_MAX=$PCM >> $GENINPUT_OUTFILE
	else
		cp $INFILE $INPUT_DIR/input.txt
		OUTFILE=${OUTFILE}_`date +%H:%M:%S`
	fi
	echo "Running test..."
	if [ $ONLY_PC = 1 ]; then
		make test_pc POINT_COUNT=$PC POINT_COORD_MAX=$PCM 1> $OUTFILE
	else
		make test POINT_COUNT=$PC POINT_COORD_MAX=$PCM 1> $OUTFILE
	fi
	if [ $? != 0 ]; then
		echo "Encountered ERROR in $i. Check $OUTFILE for details."
		echo "================================================================================================="
		exit 1
	fi
	mv $INPUT_DIR/input.txt $INFILE
	echo "SUCCESS for $i"
done

echo "DONE ALL!"
echo "================================================================================================="
