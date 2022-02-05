#!/usr/bin/env bash

set -ex
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
[[ -d docs-uan ]] && rm -rf docs-uan || echo "docs-uan doesn't exist"
mkdir -p docs-uan
cd docs-uan
git clone --depth=1 -b release/docs-html git@github.com:Cray-HPE/docs-uan.git
cd ..
rm -rf docs-uan/docs-uan/* docs-uan/docs-uan/.gitignore
cp -r public/* docs-uan/docs-uan/
cd docs-uan/docs-uan
git add .
git commit -m "Generated HTML from docs-uan"
git push origin release/docs-html
