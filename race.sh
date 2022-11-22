#!/bin/bash
DEBUG=0
method='GET'
header=
body=
N=5

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
      --method)
      method="$2" 
      shift
      shift
      ;;
      -h|--header)
      header="$2"
      shift # past argument
      shift # past value
      ;;
      -n)
      N="$2"
      shift # past argument
      shift # past value
      ;;
      -b|--body)
      body="$2"
      shift # past argument
      shift # past value
      ;;
      --debug)
      DEBUG=1
      shift
      shift
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

URL1=$1
URL2=$2
temp_file=$(mktemp /tmp/race.XXXXXX)

if [ $DEBUG = 1 ]; then
  echo $URL1
  echo $URL2
  echo $N
  echo $method
  echo $header
  echo $body
fi

request () {
  curl -w "%{time_total}\n" -o /dev/null -s \
    --location --request $method $1 \
    --header 'Content-Type: application/json' \
    --header "$header" \
    --data-raw "$body"
}

average_last_n_lines_file () {
  echo "scale=scale(7); (`tail -n $1 $2 | paste -sd+ | sed 's/,/./g'`)" | bc -l | sed "s/$/\/$N/g" | bc -l
}

echo $URL1 > $temp_file
for run in $(seq 1 $N); do request $URL1 >> $temp_file; done
echo "`average_last_n_lines_file $N $temp_file`s" >> $temp_file
echo $URL2 >> $temp_file
for run in $(seq 1 $N); do request $URL2 >> $temp_file; done
echo "`average_last_n_lines_file $N $temp_file`s" >> $temp_file
cat $temp_file
