#!/bin/bash

# Folder to process (default is the current folder)
folder="${1:-.}"

# Browsing JSON files
find "$folder" -type f -name "*.json" | while read -r file; do
    # Generate the path of the corresponding YAML file
    yaml_file="${file%.json}.yaml"
    echo "Conversion de $file en $yaml_file"
    
    # Converting the JSON file to YAML
    yq eval -P < "$file" > "$yaml_file"

	# Removing the JSON file
	rm "$file"
done
