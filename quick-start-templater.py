import sys
import re

distro=sys.argv[1]

def load_prerequisites_paths():    
    return [
        "distros/{distro}/steps/core-prerequisites".format(distro = distro),
        "distros/{distro}/steps/extension-prerequisites".format(distro = distro)
    ]

def parse_prerequesite(path):
    prerequisite_content = []
    with open(path) as prerequisites_file:
        prerequisite_content = prerequisites_file.readlines()
    parsed_content=[]
    
    if re.search("^#!", prerequisite_content[0]):
        prerequisite_content.pop(0)

    for content_line in prerequisite_content:
        command_line = content_line
        if re.search("^sudo ", content_line): # is chaning user
            command_line = content_line[5:]
        
        parsed_content.append(command_line)
    return parsed_content   

def generate_prerequisites():
    prerequisites_paths = load_prerequisites_paths()
    prerequisite_script = [ "#!/bin/sh\n" ]
    for prerequisite_path in prerequisites_paths:
        parsed_prerequisite = parse_prerequesite(prerequisite_path)
        prerequisite_script = prerequisite_script + parsed_prerequisite
    return prerequisite_script

def write_prerequisites(prerequisites):
    pre_requesite_script_path = "output/{distro}/quickinstall/prerequisites.sh".format(distro=distro)
    with open(pre_requesite_script_path, 'w') as output_file:
        output_file.writelines(prerequisites)


prerequisites = generate_prerequisites()

write_prerequisites(prerequisites)

