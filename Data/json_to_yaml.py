import os
import json
import yaml



def convert_json_to_yaml(folder_path):
    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".json"):
                json_path = os.path.join(root, file)
                yaml_path = os.path.join(root, os.path.splitext(file)[0] + ".yaml")


                try:
                    with open(json_path, 'r', encoding='utf-8') as json_file:
                        data = json.load(json_file)
                    
                    with open(yaml_path, 'w', encoding='utf-8') as yaml_file:
                        yaml.dump(data, yaml_file, default_flow_style=False, allow_unicode=True, explicit_start=False)
                    

                    os.remove(json_path)
                    print(f"Converted and deleted: {json_path}")



                except Exception as e:
                    print(f"error processing {json_path}: {e}")



if __name__ == "__main__":
    convert_json_to_yaml(".")
