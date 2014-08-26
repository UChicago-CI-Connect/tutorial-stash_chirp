#!/bin/bash
echo "testing output on: `date`" > $CHIRP_MOUNT/data_access_test
cat $CHIRP_MOUNT/data_access_test
