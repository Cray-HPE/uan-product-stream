
# Configure Pluggable Authentication Modules \(PAM\) on UANs

Perform this procedure to configure PAM on UANs. This enables dynamic authentication support for system services.

Intialize and configure the Cray command line interface \(CLI\) tool on the system. See "Configure the Cray Command Line Interface \(CLI\)" in the CSM documentation for more information.

1. Verify that the Gitea Version Control Service \(VCS\) is running.

    ```bash
    ncn-m001# kubectl get pods --all-namespaces | grep vcs
    services          gitea-vcs-f57c54c4f-j8k4t          2/2     Running             1          11d
    services          gitea-vcs-postgres-0               2/2     Running             0          11d
    ```

2. Retrieve the initial Gitea login credentials for the `crayvcs` username.

    ```bash
    ncn-m001# kubectl get secret -n services vcs-user-credentials \
     --template={{.data.vcs_password}} | base64 --decode
    ```

    These credentials can be modified in the `vcs_user` role prior to installation or can be modified after logging in.

3. Use an external web browser to verify the Ansible plays are available on the system.

    The URL will take on the following format:

    https://api.SYSTEM-NAME.DOMAIN-NAME/vcs


4. Clone the system Version Control Service \(VCS\) repository to a directory on the system.

    ```bash
    ncn-w001# git clone https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git
    ```

5. Change to the `uan-config-management` directory.

    ```bash
    ncn-w001# cd uan-config-management
    ```

6. Make a new directory for the PAM configuration.

    a. Create a `group_vars/all` directory if making changes to all UANs.

        ```bash
        ncn-w001# mkdir -p group_vars/all
        ncn-w001# cd group_vars/all
        ```

    b. Create a `host_vars/XNAME` directory if the change is node specific.

        ```bash
        ncn-w001# mkdir -p host_vars/XNAME
        ncn-w001# cd host_vars/XNAME
        ```

7. Configure PAM.

    The default path is `/etc/pam.d/`, so only the module file name is required.

    ```bash
    # vi pam.yml
    ---
    uan_pam_modules:
      - name: pam_module_file_name
        lines:
          - "add this line to pam module file_name" 
          - "add another line to pam module file_name"  
      - name: another_pam_module_file_name    
        lines:    
          - "add this line to another_pam_module_file_name"
    ```

    The following is an example of adding the line `"account required pam\_access.so"` to the `/etc/pam.d/common-account` PAM file. The \\t is used to place a tab between `account required` and `pam\_access.so` to match the formatting of the common-account file contents. The quotes are required in the strings used in the `lines` filed.

    ```bash
    ---
    uan_pam_modules:
      - name: common-account
        lines:
          - "account required\tpam_access.so" 
    ```

8. Add the change from the working directory to the staging area.

    - All UANs:

        ```bash
        ncn-w001# git add group_vars/all/pam.yml
        ```

    - Node specific:

        ```bash
        ncn-w001# git add host_vars/XNAME/pam.yml
        ```

9. Commit the file to the master branch.

    ```bash
    ncn-w001# git commit -am 'Added PAM configuration'
    ```

10. Push the commit.

    ```bash
    ncn-w001# git push
    ```

    If prompted, use the Gitea login credentials.

11. Reboot the UAN\(s\) with the Boot Orchestration Service \(BOS\).

    ```bash
    ncn-w001# cray bos session create \
     --template-uuid UAN_SESSION_TEMPLATE --operation reboot
    ```

