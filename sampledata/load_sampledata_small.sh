#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Uploading sampledata to $1"

# Employees 
echo "\nDeleting old humanresources index"
curl --insecure -u admin:admin -XDELETE "$1/humanresources"
echo "\nSetup Mapping"
curl --insecure -u admin:admin -H "Content-Type: application/json" -XPUT "$1/humanresources" -d @"$DIR/mappings_humanresources.json"
echo "\nLoad employee sample data"
curl --insecure -u admin:admin -H "Content-Type: application/json" -XPUT "$1/humanresources/_bulk" --data-binary @"$DIR/employees_small.json"

# Finance
echo "\nDeleting old finance index"
curl --insecure -u admin:admin -XDELETE "$1/finance"
echo "\nSetup Mapping"
curl --insecure -u admin:admin -H "Content-Type: application/json" -XPUT "$1/finance" -d @"$DIR/mappings_finance.json"
echo "\nLoad sample finance data"
curl --insecure -u admin:admin -H "Content-Type: application/json" -XPUT "$1/finance/_bulk" --data-binary @"$DIR/revenue.json"

