# Boot UANs

Perform this procedure to boot UANs using BOS so that they are ready for user logins.

Perform [Create UAN Boot Images](../operations/Create_UAN_Boot_Images.md) before performing this procedure.

1. Create a BOS session to boot the UAN nodes.

    ```bash
    ncn-m001# cray bos session create --template-uuid uan-sessiontemplate-PRODUCT_VERSION --operation reboot --format json | tee session.json
    {
     "links": [
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "jobId": "boa-89680d0a-3a6b-4569-a1a1-e275b71fce7d",
         "rel": "session",
         "type": "GET"
       },
       {
         "href": "/v1/session/89680d0a-3a6b-4569-a1a1-e275b71fce7d/status",
         "rel": "status",
         "type": "GET"
       }
     ],
     "operation": "reboot",
     "templateUuid": "uan-sessiontemplate-PRODUCT_VERSION"
    }
    
    ```
    
3. Retrieve the BOS session ID from the output of the previous command.

    ```bash
    ncn-m001# export BOS_SESSION=$(jq -r '.links[] | select(.rel=="session") | .href' session.json | cut -d '/' -f4)
    ncn-m001# echo $BOS_SESSION
    89680d0a-3a6b-4569-a1a1-e275b71fce7d
    ```
    
4. Retrieve the Boot Orchestration Agent \(BOA\) Kubernetes job name for the BOS session.

    ```bash
    ncn-m001# BOA_JOB_NAME=$(cray bos session describe $BOS_SESSION --format json | jq -r .job)
    ```

5. Retrieve the Kuberenetes pod name for the BOA assigned to run this session.

    ```bash
    ncn-m001# BOA_POD=$(kubectl get pods -n services -l job-name=$BOA_JOB_NAME --no-headers -o custom-columns=":metadata.name")
    ```
    
6. View the logs for the BOA to track session progress.

    ```bash
    ncn-m001# kubectl logs -f -n services $BOA_POD -c boa
    ```

7. List the CFS sessions started by the BOA. Skip this step if CFS was not enabled in the boot session template used to boot the UANs.

    If CFS was enabled in the boot session template, the BOA will initiate a CFS session.

    In the following command, `pending` and `complete` are also valid statuses to filter on.

    ```bash
    ncn-m001# cray cfs sessions list --tags bos_session=$BOS_SESSION --status running --format json
    ```

