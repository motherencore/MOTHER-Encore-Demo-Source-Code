#!/bin/bash

# Folder to process (default is the current folder)
folder="${1:-.}"

# Browsing JSON files
find "$folder" -type f -name "*.yaml" | while read -r file; do
    # Generate the path of the corresponding JSON file
    json_file="${file%.yaml}.json"
    
    # Convert the YAML file to JSON
    yq eval -o=json "$file" > "$json_file"

	# Removing the YAML file
	rm "$file"
done
