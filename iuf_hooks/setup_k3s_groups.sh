#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
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

# This script expects some commands to return non-zero
# in the case that node groups do not exist.
set +e

K3S_SERVER_GROUP="k3s_server"
K3S_SERVER_GROUP_DESC="K3S server nodes"
K3S_AGENT_GROUP="k3s_agent"
K3S_AGENT_GROUP_DESC="K3S agent nodes"
K3S_EXCLUSIVE_GROUP="K3s"
NODE_ROLE="Application"
NODE_SUBROLE="UAN"

function usage() {

  echo "$0 checks to see if the $K3S_SERVER_GROUP and $K3S_AGENT_GROUP groups "
  echo "exist in HSM and have any members. If they exist and have members, the "
  echo "script exits and the groups are left as-is. If they don't exist, HSM is "
  echo "queried for all nodes of $NODE_ROLE $NODE_SUBROLE.  The $K3S_SERVER_GROUP "
  echo "group is created with the first node as the sole member. "
  echo "The $K3S_AGENT_GROUP is also created with the remaining nodes as "
  echo "members."
  echo ""
  echo "Usage: $0 [-h | -v]"
  echo ""
  echo "options:"
  echo "h      Print this help"
  echo "v      verbose mode"
  echo ""
  exit 0

}

function check_auth() {

  # Check if a Cray CLI configuration exists...
  if cray hsm state components list 2>&1 | egrep --silent "Error: No configuration exists"; then
    echo "ERROR cray command not initialized. Initialize with 'cray init' and try again"
    exit 1
  fi

  # Check if Cray CLI has a valid authentication token...
  if cray hsm state components list > /dev/null 2>&1 | egrep --silent "401|403"; then
    echo "ERROR cray command not authorized. Authorize with 'cray auth login' and try again"
    exit 1
  fi

}

function create_node_group() {

  cray hsm groups create \
    --members-ids "$1" \
    --exclusive-group "$2" \
    --description "$3" \
    --label "$4"

  if [ $? -ne 0 ]; then
    echo "ERROR Failed to create $4 HSM group"
    exit 1
  fi 

}

function check_node_group() {

  cray hsm groups members list $1 2> /dev/null | wc -l | xargs

}

function get_node_xnames() {
  
  local LOCAL_NODES

  LOCAL_NODES=$( cray hsm state components list \
    --role $1 --subrole $2 --format json \
    | jq -r '.Components[].ID' | sort )

  if [ $? -ne 0 ]; then
    echo "ERROR Failed to get $1 $2 nodes"
    exit 1
  fi

  # Convert newline separated node names into an array
  IFS=$'\n' read -rd '' -a NODE_ARRAY <<< "$LOCAL_NODES"

}

while getopts "hv" arg; do
  case $arg in
    h)
      usage
      ;;
    v)
      set -x
      ;;
  esac
done

check_auth

# Check if $K3S_SERVER_GROUP and $K3S_AGENT_GROUP HSM groups already exist with members
NUM_K3S_SERVER_NODES=$( check_node_group $K3S_SERVER_GROUP )
NUM_K3S_AGENT_NODES=$( check_node_group $K3S_AGENT_GROUP )

if [ $NUM_K3S_SERVER_NODES -ne 0 -a $NUM_K3S_AGENT_NODES -ne 0 ]; then
  echo "INFO $K3S_SERVER_GROUP and $K3S_AGENT_GROUP are already configured"
  exit 0
fi

# Get all the $NODE_ROLE $NODE_SUBROLE nodes, sorted by XNAME (Components.ID)
get_node_xnames $NODE_ROLE $NODE_SUBROLE 
# The K3s configuration requires at least one $NODE_ROLE $NODE_SUBROLE nodes
if [ ${#NODE_ARRAY[@]} -lt 1 ]; then
  echo "WARNING There are not enough $NODE_ROLE $NODE_SUBROLE nodes to support K3s configuration"
  exit 0
fi
    
# Set $K3S_SERVER_GROUP to first $NODE_ROLE $NODE_SUBROLE node
K3S_SERVER=${NODE_ARRAY[0]}

# Create $K3S_SERVER_GROUP HSM group
if [ $NUM_K3S_SERVER_NODES -eq 0 ]; then
  create_node_group "$K3S_SERVER" "$K3S_EXCLUSIVE_GROUP" "$K3S_SERVER_GROUP_DESC" "$K3S_SERVER_GROUP"
fi

# Set K3S_AGENT_LIST to remaining $NODE_ROLE $NODE_SUBROLE nodes
if [ ${#NODE_ARRAY[@]} -gt 1 ]; then
  # K3S_AGENT_LIST must be comma-separated, so replace so replace space with comma
  K3S_AGENT_LIST=$( echo ${NODE_ARRAY[@]:1} | sed 's/ /,/g' )

  # Create $K3S_AGENT_GROUP HSM group
  create_node_group "$K3S_AGENT_LIST" "$K3S_EXCLUSIVE_GROUP" "$K3S_AGENT_GROUP_DESC" "$K3S_AGENT_GROUP"
fi

exit 0
