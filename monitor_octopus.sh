#!/bin/bash

projectName=$1
baseUrl=$OCTOPUS_URL
header="X-Octopus-ApiKey:$OCTOPUS_KEY"

echo Monitoring $projectName

curl -sS -H $header "$baseUrl/api/projects" > tmp

totalProj=`cat tmp | jq '.TotalResults'`
pageCount=`cat tmp | jq '.ItemsPerPage'`

pages=`echo "($totalProj/$pageCount)+1" | bc`

echo Total project $totalProj. Number of pages $pages

for i in `seq $pages`
do
    echo Reading page $i
    url="$baseUrl/api/projects?skip=$((($i - 1) * 30))"

    curl -sS -H $header "$baseUrl/api/projects?skip=$((($i - 1) * 30))" | jq ".Items[] | select (.Name == \"$projectName\")" > tmp

   if [ `cat tmp | wc -l` -gt 0 ]
   then 
      echo Found
      break
  fi
done

if [ `cat tmp | wc -l` -lt 1 ]
then
    echo Project not found
    exit 1
fi

projectId=`cat tmp | jq '.Id' | sed s/\"//g`
echo Project ID: $projectId

rm tmp

while true
do
    deployments=`curl -sS -H $header "$baseUrl/api/tasks?project=$projectId&active=true" | jq '.Items | length'`

    echo Total deployments: $deployments
    if [ $deployments -eq 0 ]
    then
	say -v Vicki Finished $1
	exit 0
    fi
    sleep 1
done

echo Finished

