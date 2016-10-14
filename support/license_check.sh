#!/bin/env bash
# license_check.sh
# Check the included software licenses, as deliniated in $install_dir/LICENSE
# - Compare to list of good/bad, and throw warnings (for now)
# Note: this is currently heavily related to the state of omnibus' licensing.rb

# list arrays, members are pattern strings!
# GOOD currently not actually used in this code, and here for documentation reasons.
GOODLIST=('^MIT' '^LGPL' '^Apache' '^Ruby' '^BSD-[23]{1}' '^ISC' )
BADLIST=('^GPL' '^AGPL' )


# fetch install_dir from config/projects/gitlab.rb and verify the output.
install_dir="$(grep -B0 -A0 -C1 -e '^install_dir' config/projects/gitlab.rb | cut -d'"' -f2)"
if [ ! -d $install_dir ]; then
    echo "Unable to retrieve install_dir, thus unable to check \$install_dir/LICENSE"
    exit 1;
else
    echo "Checking licenses via the contents of '$install_dir/LICENSE'"
fi

# grep out each piece of software, version, licensefrom $install_dir/LICENSE
declare -A SOFTWARE
declare -A LICENSE
{
    software=''
    license=''
    while IFS= read -r line ; 
    do
        # reset to be sure we don't somehow accidentally 
        if [[ "$line" == "--" ]]; then
            software=''
            license=''
            continue
        fi
    
        if [[ $line =~ 'product bundles '(.*)','$ ]]; then
            software=${BASH_REMATCH[1]}
            SOFTWARE[${#SOFTWARE[@]}]=$software
        fi
        if [[ $line =~ 'available under a "'(.+)'"' ]]; then
            license=${BASH_REMATCH[1]}
            LICENSE[$(( ${#SOFTWARE[@]} - 1))]=$license
        fi
        
    done <<< "$(grep -B1 -e 'which is available under a' $install_dir/LICENSE)"
}

# check the license against the pattern from the lists.
for x in `seq 0 "$(( ${#SOFTWARE[*]} - 1 ))"`; do
    for n in ${BADLIST[@]} ; do
        if [[ ${LICENSE[$x]} =~ $n ]]; then
            echo "BAD LICENSE! ${SOFTWARE[$x]} uses ${LICENSE[$x]}"
            continue
        fi
    done
done 
