#!/bin/bash

if [[ $# > 0 ]]
then
	DB_NAME=$1
else
	DB_NAME=sofea_test
fi

#echo "DEPLOYING DATABASE: $DB_NAME"

curl -X DELETE http://127.0.0.1:5984/$DB_NAME
for i in chroms docs by_fitness by_gen
do
#    echo "creating views $i"
    cd $i
    couchapp push . $DB_NAME
    cd ..
done
#echo "ALL VIEWS CREATED"

