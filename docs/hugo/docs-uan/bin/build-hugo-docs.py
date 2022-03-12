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

from email.policy import default
import pathlib
import subprocess
from tkinter import W
import yaml
from jinja2 import Environment, FileSystemLoader
from optparse import OptionParser


THIS_DIR = pathlib.Path(__file__).parent.resolve()
# Get options
parser = OptionParser()
parser.add_option("-r", "--releases", dest="release_args",
                  action="store", type="string",
                  help="comma-separated list of releases",
                  metavar="RELEASE1,RELEASE2,...")
parser.add_option("-f", "--release-file", dest="release_file",
                  action="store", type="string",
                  default="../release_list.yml",
                  help="file containing list of releases",
                  metavar="RELEASE_FILE")
parser.add_option("-n", "--no-clone", dest="clone_docs",
                  action="store_false", type="boolean",
                  default=True,
                  help="flag to not clone the doc source")

(options, args) = parser.parse_args()

if options.release_args:
    release_list = options.release_args.split(',')
else:
    release_file_path = pathlib.Path(options.release_file).resolve()
    with open(release_file_path, 'r') as release_info:
        out = yaml.safe_load(release_info)
    release_list = out['releases']

release_string = ' '.join(release_list)
chars_to_strip = ['v', '.']
# Create a mapping table to map the characters
# to be deleted with empty string.  For example,
# this converts 'v2.3.1' to '231'.
translation_table = str.maketrans('', '', ''.join(chars_to_strip))
linkcheck_string = ''
version_list = []
for i in release_list:
    linkcheck_string = linkcheck_string + 'linkcheck_en_' + i.translate(translation_table) + ' '
    version_list.append(i.translate(translation_table))

file_loader = FileSystemLoader('templates')
env = Environment(loader=file_loader)

build_template = env.get_template('build.sh.j2')
hugo_template = env.get_template('hugo_prep.yml.j2')
config_template = env.get_template('config.toml.j2')
test_template = env.get_template('test.yml.j2')

build_out = build_template.render(releases=release_string, linkchecks=linkcheck_string, clone=options.clone_docs)
hugo_prep_out = hugo_template.render(releases=release_list, translation=translation_table)
config_out = config_template.render(releases=release_list, translation=translation_table)
test_out = test_template.render(releases=release_list, translation=translation_table)
print(build_out)
print()
print(hugo_prep_out)
print()
print(config_out)
print()
print(test_out)

### Build docs/hugo/docs-uan/bin/build.sh from template ###
with open("./build.sh", "w") as fh:
    fh.write(build_out)
### Build docs/hugo/docs-uan/config.toml from template ###
with open("../config.toml", "w") as fh:
    fh.write(config_out)
### Build docs/hugo/docs-uan/bin/compose/hugo_prep.yml from template ###
with open("./compose/hugo_prep.yml", "w") as fh:
    fh.write(hugo_prep_out)
### Build docs/hugo/docs-uan/bin/compose/test.yml from template ###
with open("./compose/test.yml", "w") as fh:
    fh.write(test_out)

### Run docs/hugo/docs-uan/bin/build.sh ###
build_docs = subprocess.run(["./build.sh"])
print("Results of the document build was: ", build_docs.returncode)