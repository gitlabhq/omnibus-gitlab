#!/bin/env bash
# license_check.sh
# Check the included software licenses, as deliniated in $install_dir/LICENSE
# - Compare to list of good/bad/unknown, and throw warnings (for now)
# Note: this is currently heavily related to the state of omnibus' licensing.rb

# list arrays, members are pattern strings!
GOODLIST=('^MIT' '^LGPL' '^Apache' '^Ruby' '^BSD-[23]{1}' '^ISC' )
BADLIST=('^GPL' '^AGPL' )

echo "###### BEGIN LICENSE CHECK ######"

# fetch install_dir from config/projects/gitlab.rb and verify the output.
install_dir="$(grep -B0 -A0 -C1 -e '^install_dir' config/projects/gitlab.rb | cut -d'"' -f2)"
if [ ! -d $install_dir ]; then
    echo "Unable to retrieve install_dir, thus unable to check \$install_dir/LICENSE"
    exit 1;
else
    echo "Checking licenses via the contents of '$install_dir/LICENSE'"
fi

if [ ! -f "$install_dir/LICENSE" ]; then
    echo "Unable to open '$install_dir/LICENSE'!"
    exit 1;
fi

# grep out each piece of software, version, licensefrom $install_dir/LICENSE
declare -A SOFTWARE
declare -A LICENSE
{
    software=''
    license=''
    while IFS= read -r line ; 
    do
        # reset to be sure we don't accidentally fill erroneously
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
# - for x in seq: we have two arrays, and need to walk synchronously
for x in `seq 0 "$(( ${#SOFTWARE[*]} - 1 ))"`; do
    # managed continue state once we've checked a license.
    CONTINUE=false

    # if it matches in GOODLIST, break this loop, and continue in the parent
    for n in ${GOODLIST[@]} ; do
        if [[ ${LICENSE[$x]} =~ $n ]]; then
            echo "Good   : ${SOFTWARE[$x]} uses ${LICENSE[$x]}"
            CONTINUE=true;
            break;
        fi
    done
    if [[ $CONTINUE == true ]]; then continue; fi

    # if it matches in BADLIST, break this loop, and continue in the parent
    for n in ${BADLIST[@]} ; do
        if [[ ${LICENSE[$x]} =~ $n ]]; then
            echo "Check  ! ${SOFTWARE[$x]} uses ${LICENSE[$x]}"
            CONTINUE=true
            break;
        fi
    done
    if [[ $CONTINUE == true ]]; then continue; fi

    # if we've made it here, we're unsure of the state of the reported license
    echo "Unknown? ${SOFTWARE[$x]} uses ${LICENSE[$x]}"
done

echo "###### END LICENSE CHECK ######"
