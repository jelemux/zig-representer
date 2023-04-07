#!/usr/bin/env bash

# Synopsis:
# Run the representer on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test mapping to a mapping.json file in the passed-in output directory.
# The test mapping are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/representers/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

slug="${1}"
input_dir="${2%/}"
output_dir="${3%/}"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: creating representation..."

/opt/representer/bin/zig-representer --slug "${slug}" --input-dir "${input_dir}" --output-dir "${output_dir}"

# Exit if there an error occured while processing the solution files
if [ $? -ne 0 ]; then
    exit $?
fi

echo "${slug}: done"