#!/bin/bash
# Scans the dependencies for security vulnerabilities
# Arguments: A path to version-manifest.json file
# example: ./gitlab-debscan.sh $HOME/version-manifest.json

set -e

version_file=$1;

if [ "$#" == "0" ]; then
  echo "You need to pass a path to versions_manifest file";
  exit 1;
fi

if [ ! -f $version_file ]; then
  echo "$version_file does not exist";
  exit 1;
fi

software_versions=($(cat $version_file | jq -r ".software|to_entries|map(\"\(.key)/\(.value.locked_version|tostring)\")|.[]" | grep -v 'null' ))
base_url=https://cve.circl.lu/api/search

counter=0;

vulnerabilities=""
short_descriptions=""
REPORT_PATH=${REPORT_PATH-/tmp}

echo "Checking dependencies for known CVEs"
printf "%-70s %-10s\n\n" Dependency Status
for dependency in "${software_versions[@]}"
do
  response=$(curl -s $base_url/$dependency);

  if [ "$response" = "[]" ]; then
    printf "%-70s \033[0;32m%-10s\e[0m\n" ${dependency} Secure;
  else
    printf "%-70s \033[0;31m%-10s\e[0m\n" ${dependency} Vulnerable;
    vulnerabilities="$vulnerabilities\n$dependency: "
    short_descriptions="$short_descriptions\n$dependency: "
    for row in $(echo "${response}" | jq -r '.[] | @base64'); do
      _jq(){
        echo ${row} | base64 -d | jq -r ${1}
      }
      vulnerability=$(_jq '.')
      vulnerabilities="$vulnerabilities
        $(echo $vulnerability |  jq -r '.id')
        Severity: $(echo $vulnerability | jq -r '.cvss')
        Summary: $(echo $vulnerability |  jq -r '.summary')
        References:
          $(echo $vulnerability | jq -r '.references[1,2]' | tr '\n' ' ')"

      short_descriptions="$short_descriptions
        - $(echo $vulnerability | jq -r '.id')"
      counter=$((counter+1));
    done
    vulnerabilities="$vulnerabilities\n"
  fi
done

if [ "$counter" -gt "0" ]; then
  echo -e "\033[0;31m$counter vulnerabilities were found\e[0m";
  echo -e "\033[0;31m$short_descriptions\e[0m";
  IFS= && echo -e $vulnerabilities > $REPORT_PATH/dependency_report.txt
  echo "Full dependency scanning report can be found at $REPORT_PATH/dependency_report.txt"
  exit 1;
else
  echo -e "\033[0;32mNo vulnerabilities were found\e[0m";
  exit 0;
fi
echo $vulnerabilities
