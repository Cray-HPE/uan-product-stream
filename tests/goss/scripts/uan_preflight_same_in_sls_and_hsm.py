#!/usr/bin/env python3

import json
import subprocess
import sys


def main():
    # Get UAN Nodes from HSM
    cmd = "cray hsm state components list --role Application --subrole UAN --format json".split()
    raw_result = subprocess.run(cmd, stdout=subprocess.PIPE)
    result = json.loads(raw_result.stdout.decode("utf-8"))
    hsm_discovered_uans = {node["ID"] for node in result["Components"]}

    # Get UAN nodes that SLS knows about
    cmd = "cray sls hardware list --format json".split()
    raw_result = subprocess.run(cmd, stdout=subprocess.PIPE)
    result = json.loads(raw_result.stdout.decode("utf-8"))
    sls_known_uans = {node["Xname"] for node in result
                      if "ExtraProperties" in node
                      if "SubRole" in node["ExtraProperties"]
                      if node["ExtraProperties"]["SubRole"] == "UAN"}

    if hsm_discovered_uans != sls_known_uans:
        in_hsm_not_sls = hsm_discovered_uans - sls_known_uans
        in_sls_not_hsm = sls_known_uans - hsm_discovered_uans
        if in_hsm_not_sls:
            print("ERROR: The Hardware State Manager (HSM) contains UAN nodes that System Layout Service (SLS) does not.")
            print("Nodes: ", in_hsm_not_sls)
        if in_sls_not_hsm:
            print("ERROR: System Layout Service (SLS) contains UAN nodes the Hardware State Manager (HSM) does not.")
            print("Nodes: ", in_sls_not_hsm)
        sys.exit(1)


if __name__ == "__main__":
    main()
