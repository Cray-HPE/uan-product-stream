#!/usr/bin/env bash

set -ex
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
mkdir -p docs-uan
cd docs-uan
git clone --depth=1 -b release/docs-html git@github.com:Cray-HPE/uan-product-stream.git
cd ..
rm -rf docs-uan/docs-uan/* docs-uan/docs-uan/.github docs-uan/docs-uan/.gitignore docs-uan/docs-uan/.version
cp -r public/* docs-uan/docs-uan/
cd docs-uan/docs-uan
git add .
git commit -m "Generated HTML from docs-uan"
git push origin release/docs-html
