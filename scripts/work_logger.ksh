#!/bin/ksh -vx
# Time Tracker is a set of functions that can be implemented in ksh to keep
# track of time spent working on a project. 

# create a new log file
function newLog {
session=$(tmux list-pane -F '#S' | head -1)
date=$(date +"%d_%m_%y")
filename=~/"work_logs/$session-$date.csv"
touch $filename
echo "$filename created..."
if [[ -e $1 ]]; then
	echo "Joining $1 to $filename"
	joinLog $session-$date $1
	rm $1
	echo "$1 joined and removed"
fi
}
export newLog

# start the current work time with the date and start time
function startLog {
out=$(date +"%m/%d/%y")
start=`calculateQuarter`
out="$out\t$start\t"
session=$(tmux list-pane -F '#S' | head -1)
date=$(date +"%d_%m_%y")
filename=~/"work_logs/$session-$date.csv"
printf "$out" >> $filename
echo "Start time: $start"
}
export startLog

# append the end time, time worked, and comments to the current work line
function stopLog {
date=$(date +"%d_%m_%y")
end=`calculateQuarter`
session=$(tmux list-pane -F '#S' | head -1)
filename=~/"work_logs/$session-$date.csv"
echo "End time: $end"
start=`getStart`
time_worked=`calculateDuration $start $end`
echo "Time Worked: $time_worked"
if [[ $# -eq 1 ]]; then
	message=$1
	out="$end\t$time_worked\t$message\n"
	echo "Comment: $message"
else
	out="$end\t$time_worked\n"
fi
printf "$out" >> $filename
}
export stopLog

# calculate the quarter for time (currently 15 mins, can be changed though
function calculateQuarter {
typeset -i hr min qtr rmnd calc_min calc_hr minimum middle
minimum=15
middle=$minimum/2
OIFS=$IFS
IFS=':'
set -A arr $(date +"%H:%M")
IFS=$OIFS
hr_start=`echo ${arr[0]} | cut -c1`
if [[ $hr_start == 0 ]]; then
	hr_new=${arr[0]}
	hr=${hr_new#?}
else
	hr=${arr[0]}
fi
min_start=`echo ${arr[1]} | cut -c1`
if [[ $min_start == '0' ]]; then
	min_new=${arr[1]}
	min=${min_new#?}
else
	min=${arr[1]}
fi

qtr=$min/$minimum
rmnd=$min%$minimum
if [[ $rmnd -gt $middle ]]; then
	qtr=$qtr+1
fi
calc_min=$qtr*$minimum
calc_hr=$hr
if [[ $qtr -eq 0 ]]; then
	typeset -L calc_min
	calc_min=00
elif [[ $calc_min -eq 60 ]]; then
	typeset -L calc_min
	calc_min=00
	calc_hr=$hr+1
fi
endTime="$calc_hr:$calc_min"
printf $endTime
}
export calculateQuarter

# Get the start time from the file
function getStart {
session=$(tmux list-pane -F '#S' | head -1)
date=$(date +"%d_%m_%y")
filename=~/"work_logs/$session-$date.csv"
line=$(tail -n 1 $filename)
set -A arr $line
start_time=${arr[1]}
printf $start_time
}
export getStart

function getTime {
typeset -i comment_length row
if [[ -e $1 ]]; then
	file=$1
else
	session=$(tmux list-pane -F '#S' | head -1)
	date=$(date +"%d_%m_%y")
	file=~/"work_logs/$session-$date.csv"
fi

row=1

echo "#:\tDate:\t\tStart:\tEnd:\tDur:\tComments:"
while read date start end duration comments
do
	comment_length=${#comments}
	if [[ ${#comments} -gt 50 ]]; then
		comments=$(echo $comments | awk '{printf substr($0,1,47)}')"..."
	fi
	echo "$row\t$date\t$start\t$end\t$duration\t$comments"
	row=$row+1
done < "$file"
total_duration=`fullLog $1`
echo "\t\t\t\tTotal:\t$total_duration"
}
export getTime

# calculate the duration between two HH:MM times
function calculateDuration {
typeset -i start_secs end_secs duration_secs duration_mins duration_hrs

start_secs=`calculateSeconds $1`

end_secs=`calculateSeconds $2`

duration_secs=$end_secs-$start_secs
duration_hrs=$duration_secs/3600
duration_mins=$duration_secs%3600/60

if [[ $duration_mins -eq 0 ]]; then
	typeset -L duration_mins
	duration_mins=00
fi

duration="$duration_hrs:$duration_mins"
printf $duration
}
export calculateDuration

# calculane the number of seconds in an HH:MM time
function calculateSeconds {
typeset -i hr_mins mins secs
OIFS=$IFS
IFS=':'
set -A new_time $1
IFS=$OIFS
hr_start=`echo ${new_time[0]} | cut -c1`
if [[ $hr_start == 0 ]]; then
	hr_new=${arr[0]}
	hr_mins=${hr_new#?}
else
	hr_mins=${new_time[0]}
fi
hr_mins=$hr_mins*60
min_start=`echo ${new_time[1]} | cut -c1`
if [[ $min_start == 0 ]]; then
	min_new=${new_time[1]}
	mins=${min_new#?}
else
	mins=${new_time[1]}
fi
mins=$mins+$hr_mins
secs=$mins*60
printf $secs
}
export calculateSeconds

# gets the current amount of time worked
function currentLog {
start=`getStart`
now=`date +"%H:%M"`
if [[ "$now" == 0* ]]; then
	now=${now#?}
fi
duration=`calculateDuration $start $now`
printf "Start:\tNow:\tTime Worked:\n$start\t$now\t$duration\n"
}

# get the total hours for this cur
function fullLog {
if [[ -e $1 ]]; then
	file=$1
else
	session=$(tmux list-pane -F '#S' | head -1)
	date=$(date +"%d_%m_%y")
	file=~/"work_logs/$session-$date.csv"
fi
typeset -i hrs mins calc_hrs calc_mins
hrs=0
mins=0
while read date start end duration comments
do
OIFS=$IFS
IFS=':'
set -A new_time $duration
IFS=$OIFS
hrs=$hrs+${new_time[0]}
mins=$mins+${new_time[1]}

done < "$file"
calc_hrs=$mins/60
calc_mins=$mins%60
hrs=$hrs+$calc_hrs
mins=$calc_mins

printf "$hrs:$mins"
}
export fullLog


function dayLog {
if [[ -z $1 ]]; then
	cur_date=$(date +"%m/%d/%y")
else
	cur_date=$1
fi

if [[ -e $2 ]]; then
	file=$2
else
	session=$(tmux list-pane -F '#S' | head -1)
	file_date=$(date +"%d_%m_%y")
	file=~/"work_logs/$session-$file_date.csv"
fi
typeset -i hrs mins calc_hrs calc_mins
hrs=0
mins=0
while read date start end duration comments
do
	if [[ $date == $cur_date ]]; then
OIFS=$IFS
IFS=':'
set -A new_time $duration
IFS=$OIFS
hrs=$hrs+${new_time[0]}
mins=$mins+${new_time[1]}
fi
done < "$file"
calc_hrs=$mins/60
calc_mins=$mins%60
hrs=$hrs+$calc_hrs
mins=$calc_mins

printf "$cur_date: $hrs:$mins"
}
export dayLog

function joinLog {
if [[ -z "$1" ]]; then
	echo "Please enter both files"
else
	out_file=~/"work_logs/$1.csv"
fi

if [[ -z "$2" ]]; then
	echo "Please enter the file to be added"
else
	in_file=$2
fi
if [[ -e $out_file ]]; then
	echo "$out_file exists."
else
	touch $out_file
fi
if [[ -e $in_file ]]; then
	cat $in_file >> $out_file
else
	echo "$in_file doesn't exist"
fi
}
export joinLog

function getItem {
if [[ -z $1 ]]; then
	echo "Choose an entry number, dangus!"
else
	session=$(tmux list-pane -F '#S' | head -1)
	date=$(date +"%d_%m_%y")
	filename=~/"work_logs/$session-$date.csv"
	sed -n $1p $filename
fi
}

# wrapper function wl -<flags> [args...]
function wl {
	# if no arguments print out the current log's time, if that log exists
	if [[ ${#} -eq 0 ]]; then
		getTime
	else 
		args_1=$1
		start=`echo $args_1 | cut -c1`
		
		# make sure flags are marked by a '-'
		if [[ $start == '-' ]]; then
			#continue
			args_1=${args_1#?}
			continue=true

			# iterate through flags
			while [[ $continue == true ]]
			do
				arg=`echo $args_1 | cut -c1`
				args_1=${args_1#?}
				#echo $arg
				if [[ -z $args_1 ]]; then
					continue=false
				fi
				#separate flag logic

				# new log
				if [[ $arg == 'N' ]]; then
					newLog $2
				fi

				# start the log
				if [[ $arg == 's' ]]; then
					startLog
				fi

				# stop the log
				if [[ $arg == 'f' ]]; then
					#echo $2
					stopLog "$2"
				fi

				# get current work block time
				if [[ $arg == 'c' ]]; then
					currentLog
				fi

				# get extended comments for an entry (i)tem
				if [[ $arg == 'i' ]]; then
					getItem $2
				fi

				# get the date stuff
				if [[ $arg == 'd' ]]; then
					echo `dayLog $2 $3` "Hours\n"
				fi

				# edit it!
				if [[ $arg == 'v' ]]; then
					session=$(tmux list-pane -F '#S' | head -1)
					date=$(date +"%d_%m_%y")
					filename=~/"work_logs/$session-$date.csv"
					vi +'set noeol' +'set binary' $filename
				fi

				# (g)et from Box
				if [[ $arg == 'g' ]]; then
					echo "Get from Box"
					if [[ $# -lt 2 ]]; then
						session=$(tmux list-pane -F '#S' | head -1)
						date=$(date +"%d_%m_%y")
						filename="$session-$date.csv"
					else
						filename=$2
					fi
					~/dotfiles/scripts/box_down.expect $filename work_logs
					echo "\n"
				fi

				# (p)ush to Box
				if [[ $arg == 'p' ]]; then
					session=$(tmux list-pane -F '#S' | head -1)
					date=$(date +"%d_%m_%y")
					filename="$session-$date.csv"
					~/dotfiles/scripts/box_up.expect $filename work_logs
					echo "\n"
				fi

				# (a)rchive - add files to work_logs/.archive directory
				if [[ $arg == 'a' ]]; then
					session=$(tmux list-pane -F '#S' | head -1)
					date=$(date +"%d_%m_%y")
					filename="$session-$date.csv"
					echo "Archiving $filename..."
					current=~/"work_logs/$filename"
					archive=~/"work_logs/.archive/"
					mv $current $archive
					~/dotfiles/scripts/box_up.expect $filename work_logs/.archive
					echo "Cleaning up other $session logs..."
					rm -i ~/work_logs/$session*
					~/dotfiles/scripts/box_delete.expect $session work_logs/

					echo "\n"
				fi
			done
		else
			echo "First Argument must be a '-' followed by one or more flags"
		fi
	fi
}
export wl
