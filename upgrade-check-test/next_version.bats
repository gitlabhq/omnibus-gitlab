#!/usr/bin/env bats

# Unit tests for the version-cadence helper (next_version.sh).

setup() {
  # shellcheck source=next_version.sh
  source "${BATS_TEST_DIRNAME}/next_version.sh"
}

@test "next_version advances a minor within a major" {
  run next_version 19.2.0-ee 1
  [ "$status" -eq 0 ]
  [ "$output" = "19.3" ]
}

@test "next_version handles an in-development (-pre) tag" {
  run next_version 19.2.0-pre 1
  [ "$status" -eq 0 ]
  [ "$output" = "19.3" ]
}

@test "next_version rolls the last minor of a major to the next major .0" {
  run next_version 18.11.7-ee 1
  [ "$status" -eq 0 ]
  [ "$output" = "19.0" ]
}

@test "next_version rolls 19.11 over to 20.0" {
  run next_version 19.11.0-ee 1
  [ "$status" -eq 0 ]
  [ "$output" = "20.0" ]
}

@test "next_version supports an explicit offset (18.11 + 2 -> 19.1)" {
  run next_version 18.11.7-ee 2
  [ "$status" -eq 0 ]
  [ "$output" = "19.1" ]
}

@test "next_version defaults the offset to 1" {
  run next_version 18.0.0-ee
  [ "$status" -eq 0 ]
  [ "$output" = "18.1" ]
}

@test "next_version fails on an unrecognized version string" {
  run next_version master 1
  [ "$status" -ne 0 ]

  run next_version "" 1
  [ "$status" -ne 0 ]
}
