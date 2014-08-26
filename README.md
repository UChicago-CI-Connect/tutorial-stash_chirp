Access Stash remotely from your job using Parrot and Chirp
==========================================================

Overview
--------

There are some conditions where transferring to the worker node via HTCondor is not practical - for example, when the required input datasets are larger than the local scratch space available on the remote worker node. One way to do this is to create a tarball (a .tar.gz file) and instruct your job to pull it remotely as secondary payload. This tutorial will show you how to do this using a helper framework named SkeletonKey in conjunction with Parrot and Chirp.

Preliminaries
-------------
Before going through the examples, login to login.osgconnect.net and setup a work area:
Initial Setup
```
% ssh login.osgconnect.net
$ tutorial stash_chirp
$ cd osg-stash_chirp
$ mkdir ~/stash/chirp_access
```
All of the files that we ask you to type below are present in the tutorial folder, ~/osg-chirp_chirp. You may edit them in place instead of typing; or you can type them fresh to reinforce your experience.
Remote data access
------------------
This example will guide you through creating a job that will read and write from a filesystem exported by Chirp. Chirp securely exposes a local filesystem path over the network so that remote jobs can access local data. SkeletonKey is a helper for setting up the secure access.
#### Create the application tarball

A tarball is a single-file archive of one or more files and folders that can be unpacked into its original form, much like a zip file. Tools for working with tarballs are universal to UNIX/Linux servers, while zip/unzip are perhaps less common.

First, create a new folder to contain your payload. You will then use this folder to create your tarball.

Create a shell script, ~/osg-stash_chirp/data_app/data_access.sh with the following lines:
```bash
#!/bin/bash
echo "testing output on: `date`" > $CHIRP_MOUNT/data_access_test
cat $CHIRP_MOUNT/data_access_test
```
Notice the use of the $CHIRP_MOUNT environment variable in this script. The SkeletonKey helper defines $CHIRP_MOUNT as the local path to the directory being exported from the Chirp server. 

Next, make sure the data_access.sh script is executable and create a tarball:
```
$ chmod 755 data_app/data_access.sh
$ tar cvzf data_app.tar.gz data_app
```
Then copy the tarball to your public directory in Stash. Ensure that it can be read by anyone:
```
$ cp data_app.tar.gz ~/stash/public/
$ chmod 644 ~/stash/public/data_app.tar.gz
```
 

Note that this makes data_app.tar.gz available via HTTP, at http://stash.osgconnect.net/+netid/data_app.tar.gz. This illustrates the integration of file access in OSG Connect and Stash, and SkeletonKey will make use of this.
#### Create a job wrapper

Open a file called ~/osg-stash_chirp/data_access.ini and add the following lines, replacing username with the appropriate values. This file is a SkeletonKey configuration profile.
```
# SkeletonKey profile for data access tutorial
[Directories]
export_base = /stash/user/username
read = /
write = /
 
[Application]
location = http://stash.osgconnect.net/+username/data_app.tar.gz
script = ./data_app/data_access.sh
```

Run SkeletonKey on ~/osg-stash_chirp/data_access.ini. This creates a job wrapper named run_job.py — an executable that you will submit to Condor as a job, which performs setup and then invokes your real application.
```
$ skeleton_key -c data_access.ini
```
#### Verification
As always, run the job wrapper locally to verify that it's working correctly before submitting to the grid. Note that run_job.py contains ad hoc security credentials for accessing your data, and as such should NOT be world readable.
```
$ chmod 700 run_job.py
$ ./run_job.py
```
The job wrapper will virtually mount your ~/stash (/stash/user/username) folder through Parrot and Chirp, and data_access.sh will deposit output there. Even though the job runs locally and is very short, it may take surprisingly long because of the "remote" access setup. In real-world jobs the setup time is negligible compared to the job run time itself.

Verify that the file was written correctly:
```
$ cat ~/stash/data_access_test
testing output on: Thu May 22 08:33:53 CDT 2013
```

The output should match the output given in the example above with the exception of the date and time. Once the output is verified, delete the output file:
```
$ rm ~/stash/data_access_test
```
#### Submitting jobs to OSG Connect

Create a file called ~/osg-stash_chirp/osg-connect.submit with the following contents.
```
universe = vanilla
notification = never
executable = ./run_job.py
output = logs/data_$(Cluster).$(Process).out
error = logs/data_$(Cluster).$(Process).err
log = logs/data.log
ShouldTransferFiles = YES
when_to_transfer_output = ON_EXIT
Queue 100
```

Submit the job to HTCondor. This will put 100 instances of the job onto the grid, because of the "Queue 100":
```
$ condor_submit osg-connect.submit
```
Verify that the jobs ran successfully:
```
$ cat ~/stash/data_access_test
```