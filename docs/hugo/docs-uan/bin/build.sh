#!/usr/bin/env bash
set -ex
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $THIS_DIR/lib/*
cd $THIS_DIR/..
LAST_DIR=${OLDPWD}
BRANCHES=(main)

function clean() {
  function clean_dir() {
    [[ -d ./$1 ]] && sudo rm -rf ./$1
    mkdir -p ./$1
  }
  clean_dir content
  clean_dir public
  clean_dir docs-uan
  [[ -f uan_docs_build.log ]] && rm uan_docs_build.log
  touch uan_docs_build.log
  docker network prune -f
}
clean

function build () {
  echo "Cloning into docs-uan..."

  mkdir -p ./docs-uan
  cd ./docs-uan
  for branch in ${BRANCHES[@]}; do
    git clone --depth 1 -b $branch git@github.com:Cray-HPE/uan-product-stream.git ./$branch
  done
  cd ${OLDPWD}

  echo "Preparing markdown for Hugo..."
  docker-compose -f $THIS_DIR/compose/hugo_prep.yml up \
    --force-recreate --no-color --remove-orphans | \
  tee -a uan_docs_build.log
  docker-compose -f $THIS_DIR/compose/hugo_prep.yml down

  echo "Creating root _index.md"
  gen_hugo_yaml "UAN Documentation" > content/_index.md
  gen_index_header "UAN Documentation" >> content/_index.md
  gen_index_content content $relative_path >> content/_index.md

  echo "Build html pages with Hugo..."
  docker-compose -f $THIS_DIR/compose/hugo_build.yml up \
    --force-recreate --no-color --remove-orphans --abort-on-container-exit | \
  tee -a uan_docs_build.log
  docker-compose -f $THIS_DIR/compose/hugo_build.yml down
}
build

function test_links() {
  echo "Build html pages with Hugo..."

  # Standup the nginx server as a background daemon first
  docker-compose -f $THIS_DIR/compose/test.yml up --force-recreate --no-color --remove-orphans -d serve_static

  # Crawl the links for each version
  docker-compose -f $THIS_DIR/compose/test.yml up --no-color --remove-orphans \
  linkcheck_en_main | tee -a uan_docs_build.log

  # Tear it all down
  docker-compose -f $THIS_DIR/compose/test.yml down
}
test_links

cd $LAST_DIR
