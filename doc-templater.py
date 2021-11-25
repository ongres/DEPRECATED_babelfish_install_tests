import sys
import glob
import re

distro=sys.argv[1]

path_format="distros/{distro}/template**"

initial_template = []

with open("doc-template.md") as initial_template_file:
    initial_template = initial_template_file.readlines()

output = []
for template_line in initial_template:
    match = re.search("{{ (template\.\d+) }}", template_line)
    if match:
        script_template_filename = match.group(1)
        script_template_file_format = "distros/{distro}/{template}"
        with open(script_template_file_format.format(distro = distro, template = script_template_filename)) as script_template_file:
            content = script_template_file.readlines()
            starts_with=re.search("^#!", content[0])
            if starts_with:
                content.pop(0)
            output = output + content
    else:
        output.append(template_line)


output_file_format = "compiling-babelfish-from-source.{distro}.md"
with open(output_file_format.format(distro = distro), 'w') as output_file:
    output_file.writelines(output)
  