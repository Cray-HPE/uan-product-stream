#!/usr/bin/env bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $THIS_DIR/lib/*

PRUNE_LIST=(
    lint
    pdf-templates
    templates
)

function help() {
    cat <<-MSG
Description:
This script recursively copies and transforms markdown files from a source directory into a
destination directory for use by the Hugo static website engine. It expects two named arguments
where --source is the path to the uan-product-stream docs repo and --destination is the path to
the hugo content folder.  The content folder will be deleted and recreated.

This script also looks for an environment variable named UAN_RELEASE in order to place content in
the appropriate subdirectory which maps to a Hugo "language".

Example:
./convert-docs-to-hugo.sh --source [path to uan docs] --destination [path to hugo content]

MSG
exit 1
}

function validate_args() {
    [[ $1 != "--source" ]] && help

    # Validate source directory
    [[ ! -d $2 ]] && help
    if [[ ! -d $2/$UAN_RELEASE ]]; then
        echo "Expected --source to point to the uan-product-stream docs repo.  Didn't find $UAN_RELEASE directory."
        help
    fi

    [[ $3 != "--destination" ]] && help

    # Validate destination directory
    [[ ! -d $4 ]] && help
    if [[ $(basename $4) != "content" ]]; then
        echo "Expected --destination to point to the hugo content directory."
        help
    fi

    if [[ -z $UAN_RELEASE ]]; then
        echo "Expected a UAN_RELEASE environment variable."
        help
    fi
}

function crawl_directory() {
    for file in $(ls "$1")
    do
        if [[ -f ${1}/${file} ]]; then
            if [[ "${file: -3}" == ".md" ]]; then
                process_file $1/$file
            else
                echo "${1}/${file} is not a markdown file. Copying as is..."
                mid_path=$(echo -n "${1}/${file}" | sed "s|${SOURCE_DIR}||" | sed "s|${file}||")
                cp ${1}/${file} $DESTINATION_DIR/$mid_path/
            fi
        else
            echo "Crawling subdirectory ${1}/${file}"
            mid_path=$(echo -n "${1}/${file}" | sed "s|${SOURCE_DIR}||")
            mkdir -p $DESTINATION_DIR/$mid_path
            crawl_directory ${1}/${file}
        fi
    done
}

function process_file() {
    oldtitle=$(get_old_title $1)
    newtitle=$(make_new_title "${oldtitle}")
    # Exiting with code 1 here does not throw error - just stops processing half way done
    # if [[ -z $newtitle ]]; then
    #     echo $1
    #     echo "Old Title: $oldtitle"
    #     echo "No title found"
    #     exit 1
    # fi
    filename=$(basename $1)
    mid_path=$(echo -n $1 | sed "s|${SOURCE_DIR}||" | sed "s|${filename}||")
    [[ $filename == "index.md" ]] && filename="_index.md"
    destination_file="${DESTINATION_DIR}/${mid_path}/${filename}"
    # echo -n "New Title: ${newtitle} - Transforming ${1} into ${destination_file}...  "
    echo -n "New Title: ${newtitle} - Transforming ${1} into ${destination_file}...  "

    # Add the yaml metadata to the top of the new file
    gen_hugo_yaml "$newtitle" > $destination_file

    # Add the file content.
    transform_links $1 >> $destination_file
    # echo "done."
}

function get_old_title() {
    # Look for a header1 tag in the first 10 lines of the file.
    cat $1 | head -10 | grep -E "^#+\s" | head -1
}

function populate_missing_index_files() {
    echo "####### Populating Missing Index Files #########"
    for dir in $(find $DESTINATION_DIR -type d)
    do
        relative_path=$(echo -n $dir | sed "s|${DESTINATION_DIR}||")
        if [[ ! -f $dir/_index.md ]] && \
            [[ -z $(echo $relative_path | grep "css") ]] && \
            [[ -z $(echo $relative_path | grep "fonts") ]] && \
            [[ -z $(echo $relative_path | grep "img") ]] && \
            [[ -z $(echo $relative_path | grep "images") ]] && \
            [[ -z $(echo $relative_path | grep "pdf-templates") ]] && \
            [[ -z $(echo $relative_path | grep "templates") ]] && \
            [[ -z $(echo $relative_path | grep "scripts") ]]; then
            new_title=$(make_new_title "$(basename $dir)")
            echo "Title: ${new_title} - Creating missing index file at $dir/_index.md"
            gen_hugo_yaml "$new_title" > $dir/_index.md
            gen_index_header "$new_title" >> $dir/_index.md
            gen_index_content $dir $relative_path >> $dir/_index.md
        fi
    done
}

function delete_dir_contents() {
    [[ -d $1 ]] && rm -rf $1
    mkdir -p $1
}

function prune_dir() {
    [[ -d $1 ]] && rm -rf $1 || echo "$1 doesn't exist"
}

validate_args $1 $2 $3 $4
SOURCE_DIR=$(cd $2 && pwd)
SOURCE_DIR=${SOURCE_DIR}/${UAN_RELEASE}/docs/portal/developer-portal

DESTINATION_DIR=$(cd $4 && pwd)
DESTINATION_DIR="${DESTINATION_DIR}/${UAN_RELEASE}"
delete_dir_contents $DESTINATION_DIR
# Prune irrelevent directories
for DIR in ${PRUNE_LIST[@]}; do
    echo "Pruning $SOURCE_DIR/$DIR"
    prune_dir $SOURCE_DIR/$DIR
done

crawl_directory $SOURCE_DIR
populate_missing_index_files
