#!/usr/bin/python3
#
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# This script takes a list of releases (tags or branches) and generates
# the html documentation using hugo.
#
# The list of releases may be proivided on the command line using the
# '--releases' option.  By default, the list of options are in
# docs/hugo/docs-uan/releases.yaml.
# The default releases.yaml file may be overridden by the '--release-file'
# option.

import pathlib
import subprocess
import yaml
from jinja2 import Environment, FileSystemLoader
from optparse import OptionParser


THIS_DIR = str(pathlib.Path(__file__).parent.resolve())
# Get options
parser = OptionParser()
parser.add_option("-f", "--release-file", dest="release_file",
                  action="store", type="string",
                  default=THIS_DIR + "/../release_list.yml",
                  help="file containing list of releases",
                  metavar="RELEASE_FILE")
parser.add_option("--no-clone", dest="clone_docs",
                  action="store_false", default=True,
                  help="flag to not clone the doc source")
parser.add_option("--no-publish", dest="publish_docs",
                  action="store_false", default=True,
                  help="flag to not publish to github pages")
parser.add_option("-r", "--releases", dest="release_args",
                  action="store", type="string",
                  help="comma-separated list of releases",
                  metavar="RELEASE1,RELEASE2,...")

(options, args) = parser.parse_args()

# Generate release list from command line or release_file
if options.release_args:
    release_list = options.release_args.split(',')
else:
    release_file_path = pathlib.Path(options.release_file).resolve()
    with open(release_file_path, 'r') as release_info:
        out = yaml.safe_load(release_info)
    release_list = out['releases']

# Convert release list to a space delimited string
release_string = ' '.join(release_list)
# Create a mapping table to map the characters
# to be deleted with empty string.  For example,
# this converts the release name 'v2.3.1' to '231'
# which is used in hugo language names.
chars_to_strip = ['v', '.']
translation_table = str.maketrans('', '', ''.join(chars_to_strip))
linkcheck_string = ''
version_list = []
for i in release_list:
    linkcheck_string = linkcheck_string + 'linkcheck_en_' + i.translate(translation_table) + ' '
    version_list.append(i.translate(translation_table))

# Create template loader
file_loader = FileSystemLoader(THIS_DIR + "/templates")
env = Environment(loader=file_loader)

# Build docs/hugo/docs-uan/bin/build.sh from template
build_template = env.get_template('build.sh.j2')
build_out = build_template.render(releases=release_string, linkchecks=linkcheck_string, clone=options.clone_docs)
with open(THIS_DIR + "/build.sh", "w") as fh:
    fh.write(build_out)

# Build docs/hugo/docs-uan/config.toml from template
config_template = env.get_template('config.toml.j2')
config_out = config_template.render(releases=release_list, translation=translation_table)
with open(THIS_DIR + "/../config.toml", "w") as fh:
    fh.write(config_out)

# Build docs/hugo/docs-uan/bin/compose/hugo_prep.yml from template
hugo_template = env.get_template('hugo_prep.yml.j2')
hugo_prep_out = hugo_template.render(releases=release_list, translation=translation_table)
with open(THIS_DIR + "/compose/hugo_prep.yml", "w") as fh:
    fh.write(hugo_prep_out)

# Build docs/hugo/docs-uan/bin/compose/test.yml from template
test_template = env.get_template('test.yml.j2')
test_out = test_template.render(releases=release_list, translation=translation_table)
with open(THIS_DIR + "/compose/test.yml", "w") as fh:
    fh.write(test_out)

# Run docs/hugo/docs-uan/bin/build.sh
chmod_build_docs = subprocess.call(['chmod', '0755', THIS_DIR + "/build.sh"])
print("Building docs...")
build_docs = subprocess.run([THIS_DIR + "/build.sh"])
print("build.sh exited with code ", build_docs.returncode)

# Run docs/hugo/docs-uan/bin/push.sh
if options.publish_docs:
    chmod_build_docs = subprocess.call(['chmod', '0755', THIS_DIR + "/push.sh"])
    print("Publishing docs to github pages...")
    push_docs = subprocess.run([THIS_DIR + "/push.sh"])
    print("push.sh exited with code ", push_docs.returncode)
