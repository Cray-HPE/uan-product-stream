
## Mount a New File System on a UAN

Use CFS to create a mount point for a new file system on a UAN.

Familiarity with Git workflows and a Git client compatible with the Git server provided by the Configuration Framework Service \(CFS\).

- **OBJECTIVE**

    Set up a new file system on application nodes, such as a User Access Nodes \(UAN\), using a Git workflow.

    See [VCS Branching Strategy](VCS_Branching_Strategy.md) for more information.


1. Perform Steps 1-3 of [Create UAN Boot Images](Create_UAN_Boot_Images.md).

2. Create a directory for `Application` role nodes.

    ```bash
    ncn-w001# mkdir -p group_vars/Application
    ```

3. Define the home directory information for the new file system in the filesystems.yml file.

    ```bash
    ncn-w001# vi group_vars/Application/filesystems.yml
    ---
    filesystems:
      - src: 10.252.1.1:/home
        mount_point: /home    
        fstype: nfs4    
        opts: rw,noauto
        state: mounted
    ```

4. Add the change from the working directory to the staging area.

    ```bash
    ncn-w001# git add -A
    ```

5. Commit the file to the working branch.

    ```bash
    ncn-w001# git commit -am 'Added file system info'
    ```

6. Resume [Create UAN Boot Images](Create_UAN_Boot_Images.md) at Step 5. 
