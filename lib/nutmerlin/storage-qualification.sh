#!/bin/sh

# Exact entries are added only from a waiver-free router/device/filesystem report.
# shellcheck disable=SC2034  # Consumed by the sourcing preflight module.
storage_qualification_load() {
	storage_expected_identity=unknown storage_exact_profile=unqualified storage_journaling=unknown
	storage_file_fsync=unknown storage_directory_fsync=unknown
	storage_stable_identity=unknown storage_interruption_recovery=unknown
}
