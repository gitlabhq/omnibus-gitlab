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

readable_report=""
json_report="["
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
    readable_report="$readable_report\n$dependency: "
    short_descriptions="$short_descriptions\n$dependency: "
    for row in $(echo "${response}" | jq -r '.[] | @base64'); do
      _jq(){
        echo ${row} | base64 --decode | jq -r ${1}
      }
      vulnerability=$(_jq '.')
      id=$(echo $vulnerability | jq -r '.id')
      severity=$(echo $vulnerability | jq -r '.cvss')

      if [ $(echo "${severity}<4" | bc -l) -eq "1" ]; then
        priority=Low
      elif [ $(echo "${severity}<7" | bc -l) -eq "1" ]; then
        priority=Medium
      else
        priority=High
      fi

      summary=$(echo $vulnerability | jq  '.summary')
      reference=$(echo $vulnerability | jq -r '.references[1]')

      readable_report="$readable_report
        $id
        Severity: $severity
        Summary: $summary
        References:
          $reference"

      json_report=$(printf '%s {\"tool\":\"%s\",\"message\":%s,\"url\":\"%s\",\"priority\":\"%s\"},' "$json_report" "$dependency" "$summary" "$reference" "$priority")
      short_descriptions="$short_descriptions
        - $id"
      counter=$((counter+1));
    done

    readable_report="$readable_report\n"
  fi
done

json_report="${json_report%,}]"

if [ "$counter" -gt "0" ]; then
  echo -e "\033[0;31m$counter vulnerabilities were found\e[0m";
  echo -e "\033[0;31m$short_descriptions\e[0m";
  echo $json_report > $REPORT_PATH/gl-dependency-scanning-report.json
  IFS= && echo -e $readable_report > $REPORT_PATH/dependency_report.txt
  echo "Full dependency scanning report can be found at $REPORT_PATH/dependency_report.txt"
  exit 1;
else
  echo -e "\033[0;32mNo vulnerabilities were found\e[0m";
  exit 0;
fi
echo $vulnerabilities
