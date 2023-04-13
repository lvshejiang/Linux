#!/bin/sh
# ########################################################################
# AUTHOR: ***
# DATE:  2019-01-05
# DESCRIBE: This Script is use to excact fio test result. Each file
#           will be extract needed 6 line in 10 fio result files
#           to generate a new log file which is totally 60 lines.
# USAGE: execute with no argument
# fio_logname: The generate new file name, you can modify it as you like
# fio_dir: Default dir which contains the 10 result files, user can modify
#          it to set the default dir,or can also specify it at running time
# ########################################################################

fio_logname=fio_log_$1_`date +%Y%m%d%H%M%S`.txt
#fio_dir=/root/fio_dir

if [ x$1 != x ]; then
   if [ -d $1 -a -e $1 ]; then
       fio_dir=$1
   else
       echo INPUT IS NOT A DIR or DIR NOT EXIST! CHECK!
       exit 1
   fi
else
#   if [ ! -e $fio_dir ]; then
#       mkdir $fio_dir
#   fi
    echo Please Execute like './fioLogGenerate-2.0.sh fiodir1'
    exit 1
fi

b=0
fio_tmplog=fio_tmp_`echo $RANDOM`.txt
for log in 4k_randrw 8k_randrw 64k_randrw 128k_randrw 1M_randrw 4k_rw 8k_rw 64k_rw 128k_rw 1M_rw
do
a=`expr $a + 1`
echo $a th
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
tnum=`ls $fio_dir | wc -l`
echo Extract $log within filename \(Total Files: $a\/$tnum \):
fnum=`ls $fio_dir | grep [-]$log | wc -l`
echo Match Files: $fnum
ls $fio_dir | grep [-]$log

if [ $? -ne 0 ]; then
    b=`expr $b + 1`
    echo NO FILE CONTAINS \"$log\" WITHIN $fio_dir, SKIP LOG WITH 6 NO MEANING LINES,PLEASE CHECK!!
else
   if [ $fnum -ne 1 ]; then
    b=`expr $b + 1`
    echo MORE THAN ONE FILES CONTAIN \"$log\" WITHIN $fio_dir, NO PROCESSION BEFORE DELETEING EXTRA ONE!!
   fi
fi

echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


seqString=("read" "lat" "bw" "write" "lat" "bw")
if [ $fnum -ne 1 ]; then
    for errnum in `seq 1 6`
        do
            echo "     "$errnum ${seqString[$errnum-1]} $log file not exist or more then one! Check Please! >> ./$fio_tmplog 
        done
    cat ./$fio_tmplog | sed -e 's/\t/ /' -e 's/$/\r/' >> ./$fio_logname
else
    cat -n $fio_dir/*-$log*.txt | sed -n '/iops/p' >> ./$fio_tmplog 
    cat -n $fio_dir/*-$log*.txt | sed -n '/.^* lat/p' | sed -n '/stdev/p' >> ./$fio_tmplog 
    cat -n $fio_dir/*-$log*.txt | sed -n '/.^* bw/p' | sed -n '/stdev/p' >> ./$fio_tmplog 
    sort -bn ./$fio_tmplog | sed -e 's/\t/ /' -e 's/$/\r/' >> ./$fio_logname
fi
    cat /dev/null > ./$fio_tmplog
done

rm -f ./$fio_tmplog

echo +----------------------`date +%Y-%m-%d`----------------------+
if [ $b -ne 0 ]; then
echo $b Files NOT PROCESS! SEE ABOVE LIST!
else
echo $a Files PROCESS! SEE ABOVE LIST!
fi

lines=`cat ./$fio_logname | wc -l`
if [ $lines -ne 60 ]; then
echo $fio_logname Lines no exactly 60 lines! ERROR!!
Rst=Error_LOG!!
else
    readSum=`sed -n '/read/=' ./$fio_logname | awk '{rsum+=$1} END {print rsum}'`
    writeSum=`sed -n '/write/=' ./$fio_logname | awk '{wsum+=$1} END {print wsum}'`
    if [ $readSum -ne 280 -a $writeSum -ne 310 ]; then
    echo SEQUENCE CHECK BAD!\(SHOULD BE IN read-lat-bw-write-lat-bw\)
    else
    Rst=SUCCESS_LOG!
    fi
fi
echo $Rst Checkin $PWD\/$fio_logname
echo +------------------------------------------------------+
