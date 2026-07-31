# shellcheck shell=bash

# Compute the GitLab release `offset` minor releases after a given version,
# honoring the release cadence: each major has minors 0..11, and after X.11 the
# next release is (X+1).0 (e.g. 18.11 -> 19.0 -> ... -> 19.11 -> 20.0).
#
# Sourced by test / upgrade-check.bats. Usage:
#   next_version 18.11.7-ee 1   # -> 19.0
#   next_version 19.2.0-pre     # -> 19.3 (offset defaults to 1)

# Number of minor releases per major (minors 0..11) before rolling over.
MINORS_PER_MAJOR=12

# Prints the "major.minor" string `offset` minor releases after `version`.
# Returns non-zero (and prints nothing to stdout) for an unrecognized version.
next_version() {
  local version="$1"
  local offset="${2:-1}"

  if [[ ! "$version" =~ ^([0-9]+)\.([0-9]+) ]]; then
    echo "unrecognized GitLab version: '${version}'" >&2
    return 1
  fi

  local index=$(( (BASH_REMATCH[1] * MINORS_PER_MAJOR) + BASH_REMATCH[2] + offset ))
  echo "$(( index / MINORS_PER_MAJOR )).$(( index % MINORS_PER_MAJOR ))"
}
