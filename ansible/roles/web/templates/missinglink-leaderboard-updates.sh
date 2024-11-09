#!/bin/bash

curl "http://localhost:5002/api/v1/at/bestServices" -H  "accept: */*" -d "" --insecure
curl "http://localhost:5002/api/v1/at/worstServices" -H  "accept: */*" -d "" --insecure
curl "http://localhost:5002/api/v1/metlink/bestServices" -H  "accept: */*" -d "" --insecure
curl "http://localhost:5002/api/v1/metlink/worstServices" -H  "accept: */*" -d "" --insecure
