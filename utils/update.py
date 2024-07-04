#%% Imports -------------------------------------------------------------------

import urllib
from pathlib import Path
from configparser import ConfigParser

#%% Inputs --------------------------------------------------------------------

# Paths
root_path = Path(__file__).resolve().parents[1]
utils_path = root_path / "utils"

#%% Functions -----------------------------------------------------------------

def update_main(path):
    with open(path, "r") as file:
        main = file.read()
    main = main.replace("img src='", "img src='utils/")
    return main

def update_template(path):
    with open(path, "r") as file:
        template = file.read()
    with open(utils_path / "README_install.md", "r") as file:
        install = file.read()
    with open(utils_path / "README_comments.md", "r") as file:
        comments = file.read()
    template = template.replace("{{ ij_version }}", ij_version)
    template = template.replace("{{ author }}", author)
    template = template.replace("{{ created }}", created)
    template = template.replace("{{ license }}", license)
    template = template.replace("{{ repo_name }}", repo_name)
    template = template.replace("{{ description }}", description)
    template = template.replace("{{ install }}", install)
    template = template.replace("{{ main }}", main)
    template = template.replace("{{ comments }}", comments)
        
    # Index
    sections = []
    for line in template.split("\n"):
        if line.startswith("## "):
            title = line.replace("## ", "").rstrip()
            link = "#" + title.replace(" ", "-").lower()
            sections.append(f"- [{title}]({link})")
    index = "## Index"
    for section in sections:
        index = index + f"\n{section}"
    template = template.replace("{{ index }}", index)   
    
    return template

#%% Initialize ----------------------------------------------------------------

# Parse INI config file
config = ConfigParser()
config.read(utils_path / "config.ini")
repo_name = root_path.name
ij_version = config["imagej"]["version"]
author = config["repository"]["author"]
author = urllib.parse.quote(author)
created = config["repository"]["created"].replace("-", "--")
created = urllib.parse.quote(created)
license = config["repository"]["license"]
license = urllib.parse.quote(license)
description = config["repository"]["description"]

#%% Execute -------------------------------------------------------------------

# Remove preexisting files
for path in list(root_path.glob("*readme*")):
    path.unlink()
  
# Update files
main = update_main(utils_path / "README_main.md")
template = update_template(utils_path / "README_template.md")

# Save files
with open(Path(root_path / "README.md"), "w") as file:
    file.write(template)     
