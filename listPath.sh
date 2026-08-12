#!/bin/sh

# Get the PATH variable
path_variable="$PATH"

# Set the Internal Field Separator to colon to split the path
IFS=":"

# Loop through each directory in the PATH
for folder in $path_variable; do
  echo "$folder"
done

# Reset IFS to its default value
unset IFS

