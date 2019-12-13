#!/bin/sh

action=${1-all}
echo Action $action




if [ "$action" == "all" ] || [ "$action" == "fetch" ]; then
  # by default will pull last 30 days
  fromdate=$(date --date "30 days ago" +"%Y-%m-%d")
  if [ -n "$NUMBER_OF_DAYS_FETCH" ]; then
    fromdate=$(date --date "$NUMBER_OF_DAYS_FETCH days ago" +"%Y-%m-%d")
  fi

  if [ -e /subreddits.txt ] && [ -z $SUBREDDITS ]; then
    SUBREDDITS=$(cat /subreddits.txt)
  fi

	if [ -z "$SUBREDDITS" ] ; then
		echo No subreddits provided
		echo Either supply /subreddits.txt or set env variable SUBREDDTS
		exit 1
	fi

	curryear=$(date +"%Y")
  currmon=$(date +"%m")
	currday=$(date +"%d")

	for sr in $SUBREDDITS; do
		#lastday=$(find /app/data/$sr/$curryear/$currmon/ -type d 2>/dev/null | awk -F'/' '{print $NF}' | sort | tail -1)

    # find the last day stored for this subreddit
		lastday=$(find /app/data/$sr/ -type d 2>/dev/null | egrep '[[:digit:]]+/[[:digit:]]+/[[:digit:]]+$' | awk -F'/' '{print $(NF-2)"-"$(NF-1)"-"$NF}' | sort -n | tail -1)
		if [ -z "$lastday" ]; then
			lastday="$fromdate"
		fi

    # if the last day stored is later than the passed in from date
    # use the last day stored instead (rather than pulling days that
    # are already stored)
    if [[ "$lastday" > "$fromdate" ]] ;
    then
      fromdate="$lastday"
    fi

    # default to date to current date
		todate=$(date +"%Y-%m-%d")

    # override from and to date if they are passed in as variables
    if [ -n "$FROM_DATE" ]; then
      $fromdate="$FROM_DATE"
    fi
    if [ -n "$TO_DATE" ]; then
      $fromdate="$TO_DATE"
    fi

		echo "Fetching $sr from $fromdate to $todate at" $(date)
		/app/fetch_links.py $sr $fromdate $todate
		echo "Done fetching $sr at" $(date)
	done
fi

if [ "$action" == "all" ] || [ "$action" == "html" ]; then
	echo "Cleaning up html directory"
  rm -fr ./r/*
  cp -r /app/static/ ./r/

  numdays_arg=""
  if [ -n  "$NUMBER_OF_DAYS_WRITE" ]; then
    numdays_arg=" --number-of-days=$NUMBER_OF_DAYS_WRITE"
  fi

	echo "Writing html files $numdays_arg"
	/app/write_html.py $numdays_arg
	echo "Done writing html files"
fi

if [ "$action" == "all" ] || [ "$action" == "push" ]; then
	if [ -z "$SURGE_EMAIL" ]; then
		echo No SURGE_EMAIL provided
		exit
	fi

	if [ -z "$SURGE_PASS_KEY" ]; then
		echo No SURGE_PASS_KEY provided
		exit
	fi
	
	if [ -z "$SURGE_DOMAIN" ]; then
		echo No SURGE_DOMAIN provided
		exit
	fi

	sed -i "s/EMAIL/${SURGE_EMAIL}/g" /root/.netrc
	sed -i "s/PASS_KEY/${SURGE_PASS_KEY}/g" /root/.netrc

	surge /app/r/ $SURGE_DOMAIN

fi

