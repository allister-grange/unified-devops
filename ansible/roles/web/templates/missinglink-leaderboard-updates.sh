#!/bin/bash

curl "https://localhost:5001/api/v1/at/bestServices" -H  "accept: */*" -d "" --insecure
curl "https://localhost:5001/api/v1/at/worstServices" -H  "accept: */*" -d "" --insecure
curl "https://localhost:5001/api/v1/metlink/bestServices" -H  "accept: */*" -d "" --insecure
curl "https://localhost:5001/api/v1/metlink/worstServices" -H  "accept: */*" -d "" --insecure
