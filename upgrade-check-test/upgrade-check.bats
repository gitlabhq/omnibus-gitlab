#!/usr/bin/env bats

# Integration assertion for the upgrade check-config smoke test. Driven by
# ./test, which starts the container ($CONTAINER) and passes
# $VERSION_OFFSET / $CHECK_VERSION. The version-cadence math this relies on is
# covered separately by next_version.bats (run first, no container).

setup() {
  # shellcheck source=next_version.sh
  source "${BATS_TEST_DIRNAME}/next_version.sh"

  # Colorize the pass/fail summary lines (disable with NO_COLOR).
  if [ -z "${NO_COLOR:-}" ]; then
    GREEN=$'\033[0;32m'
    RED=$'\033[0;31m'
    RESET=$'\033[0m'
  else
    GREEN='' RED='' RESET=''
  fi
}

setup_file() {
  echo "==> Reconfiguring default GitLab in ${CONTAINER} (this takes several minutes)..." >&3
  docker exec "${CONTAINER}" bash -c "
    mkdir -p /etc/gitlab
    cat > /etc/gitlab/gitlab.rb << 'GITLAB_RB'
external_url 'http://gitlab.example.com'
GITLAB_RB
    gitlab-ctl reconfigure
  "
}

@test "reconfigure wrote public attributes (check-config precondition)" {
  # check-config reads /var/opt/gitlab/public_attributes.json; if reconfigure
  # did not write it the check would silently skip, so guard against a false pass.
  run docker exec "${CONTAINER}" test -f /var/opt/gitlab/public_attributes.json
  [ "$status" -eq 0 ]
}

@test "default Omnibus config passes upgrade check for the next release" {
  local raw target
  # Capture docker's real exit code via run and detect the version
  run docker exec "${CONTAINER}" cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
  if [ "$status" -ne 0 ]; then
    echo "${RED}failed to read VERSION from ${CONTAINER} (exit ${status}); is the container still running? output: ${output}${RESET}" >&2
    return 1
  fi
  raw="$(echo "${output}" | tr -d '[:space:]')"
  echo "Detected GitLab version '${raw}' (from /opt/gitlab/embedded/service/gitlab-rails/VERSION in ${CONTAINER})" >&3

  if [ -n "${CHECK_VERSION:-}" ]; then
    target="${CHECK_VERSION}"
  else
    run next_version "${raw}" "${VERSION_OFFSET:-1}"
    if [ "$status" -ne 0 ]; then
      echo "${RED}could not determine GitLab version from container; VERSION reported: '${raw}'${RESET}" >&2
      return 1
    fi
    target="${output}"
  fi

  echo "Running: gitlab-ctl check-config --version=${target}" >&3
  run docker exec "${CONTAINER}" gitlab-ctl check-config --version="${target}"
  echo "check-config exited ${status} for ${target}:" >&3
  echo "${output}" >&3

  # A clean default config exits 0 with no deprecation output. "Deprecations
  # found" means default config would break on upgrade; any other non-zero
  # means the check could not run and must not be treated as a pass.
  if echo "${output}" | grep -q "Deprecations found"; then
    echo "${RED}FAIL: default Omnibus config has deprecation/removal warnings upgrading to ${target}; resolve them so default deployments upgrade cleanly (see output above).${RESET}" >&2
    return 1
  fi
  [ "$status" -eq 0 ]
  echo "${GREEN}PASS: default Omnibus config passes upgrade check for ${target}${RESET}" >&3
}
