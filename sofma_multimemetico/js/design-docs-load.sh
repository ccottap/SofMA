#!/bin/sh

curl -X PUT http://127.0.0.1:5984/sofea_test/_design/docs -H "Content-Type: application/json" -d @docs_count.json
curl -X PUT http://127.0.0.1:5984/sofea_test/_design/rev -H "Content-Type: application/json" -d @revs.json
curl -X PUT http://127.0.0.1:5984/sofea_test/_design/by -H "Content-Type: application/json" -d @by.json