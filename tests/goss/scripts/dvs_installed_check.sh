#! /bin/bash
# Copyright 2021 Hewlett Packard Enterprise Development LP

count=`kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers | wc -l`
dvs_count=`for node in \`kubectl get nodes -l cps-pm-node=True -o custom-columns=":metadata.name" --no-headers\`; do
            ssh $node "lsmod | grep '^dvs '"; done | wc -l`

if [[ 'count' == 'dvs_count' ]];then
  echo FAIL
else
  echo PASS
fi

exit