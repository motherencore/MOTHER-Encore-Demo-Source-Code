import os
import yaml
import sys

def find_gotos(data, parent_key=""):
    """
    Recursively traverses a YAML structure and extracts all 'goto' keys,
    'options' values, and 'goto' keys inside 'if', including when 'if' is a list.
    """
    gotos = []
    if isinstance(data, dict):
        for key, value in data.items():
            if key == "goto":
                gotos.append((parent_key, value))
            elif key == "options" and isinstance(value, dict):
                # Treat the values of 'options' as 'goto'
                for option_key, option_value in value.items():
                    gotos.append((f"{parent_key}.options[{option_key}]", option_value))
            elif key == "if":
                # Check if 'if' is a list or a dictionary
                if isinstance(value, list):
                    for index, condition in enumerate(value):
                        if isinstance(condition, dict) and "goto" in condition:
                            gotos.append((f"{parent_key}.if[{index}]", condition["goto"]))
                elif isinstance(value, dict):
                    if "goto" in value:
                        gotos.append((f"{parent_key}.if", value["goto"]))
            else:
                # Continue searching in nested dictionaries
                sub_key = f"{parent_key}.{key}" if parent_key else key
                gotos.extend(find_gotos(value, sub_key))
    elif isinstance(data, list):
        for index, item in enumerate(data):
            sub_key = f"{parent_key}[{index}]"
            gotos.extend(find_gotos(item, sub_key))
    return gotos

def validate_goto_in_yaml(filepath):
    """
    Validates 'goto' references in a YAML file and checks if all keys are reachable.
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)

    if not isinstance(data, dict):
        return [], [f"The file {filepath} is not a valid YAML dictionary."]

    # Find all 'goto' references and existing keys
    keys = set(data.keys())
    gotos = find_gotos(data)
    missing_gotos = [(parent, goto) for parent, goto in gotos if goto not in keys]

    # Check reachable paths
    visited = set()
    stack = ["0"]  # Assume the starting point is key '0'

    while stack:
        current = stack.pop()
        if current in visited:
            continue
        visited.add(current)

        # Add 'goto' destinations for this key
        if current in data and isinstance(data[current], dict):
            goto = data[current].get("goto")
            if goto and goto not in visited:
                stack.append(goto)

            # Search nested 'goto' references and options
            for sub_key, value in data[current].items():
                if isinstance(value, dict) and "goto" in value:
                    sub_goto = value["goto"]
                    if sub_goto and sub_goto not in visited:
                        stack.append(sub_goto)
                if sub_key == "options" and isinstance(value, dict):
                    for option_value in value.values():
                        if option_value and option_value not in visited:
                            stack.append(option_value)
                if sub_key == "if":
                    # Handle 'if' as a list or dictionary
                    if isinstance(value, list):
                        for condition in value:
                            if isinstance(condition, dict):
                                sub_goto = condition.get("goto")
                                if sub_goto and sub_goto not in visited:
                                    stack.append(sub_goto)
                    elif isinstance(value, dict):
                        sub_goto = value.get("goto")
                        if sub_goto and sub_goto not in visited:
                            stack.append(sub_goto)

    unreachable_keys = keys - visited
    return missing_gotos, unreachable_keys

def check_all_yaml_files(base_path):
    """
    Scans all YAML files in the given directory and its subdirectories.
    Validates 'goto', 'options', 'if', and key reachability. Displays errors only.
    """
    if not os.path.isdir(base_path):
        print(f"Error: The directory '{base_path}' does not exist.")
        return

    for root, _, files in os.walk(base_path):
        for file in files:
            if file.endswith(('.yaml', '.yml')):
                filepath = os.path.join(root, file)
                missing_gotos, unreachable_keys = validate_goto_in_yaml(filepath)

                if missing_gotos or unreachable_keys:
                    print(f"Errors detected in {filepath}:")
                    if missing_gotos:
                        for parent_key, missing_key in missing_gotos:
                            print(f"  - Path '{parent_key}' contains a 'goto' pointing to '{missing_key}', which does not exist.")
                    if unreachable_keys:
                        for key in unreachable_keys:
                            print(f"  - Key '{key}' is not reachable.")

if __name__ == "__main__":
    # Get directory path from command line arguments
    if len(sys.argv) != 2:
        print("Usage: python check_dialogue_goto.py <directory_path>")
        sys.exit(1)

    base_path = sys.argv[1]
    check_all_yaml_files(base_path)
