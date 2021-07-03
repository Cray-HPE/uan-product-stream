# Apply the UAN Patch

Apply a UAN update patch to the release tarball.

- **OBJECTIVE**

    Apply a UAN update patch to the release tarball. This ensures that the latest UAN product artifacts are installed on the HPE Cray EX supercomputer.


1. Download the source release version \(uan-2.0.0.tar.gz\) of the UAN software package tarball and the wanted compressed patch uan-2.0.0-uan-2.0.0.patch.gz to the HPE Cray EX system.

2. Extract the source release distribution.

    ```bash
    ncn-w# tar -xzf uan-2.0.0.tar.gz
    ```

3. Uncompress the patch.

    ```bash
    ncn-w# gunzip uan-2.0.0-uan-2.0.0.patch.gz
    ```

4. Verify that the Git version is at least 2.16.5.

    The patch process is known to work with Git \>= 2.16.5. Older versions of Git may not correctly apply the binary patch.

    ```bash
    ncn-w# git version
    git version 2.26.2
    ```

5. Apply the patch.

    ```bash
    ncn-w# git apply -p2 --whitespace=nowarn --directory=uan-2.0.0 \
    uan-2.0.0-uan-2.0.0.patch
    ```

6. Set UAN\_RELEASE to reflect the new version.

    A different UAN release name can be chosen, if wanted.

    ```bash
    ncn-w# UAN_RELEASE="uan-2.0.0-day0-patch"
    ```

7. Update the name of the UAN release distribution directory.

    ```bash
    ncn-w# mv uan-2.0.0 $UAN_RELEASE
    ```

8. Create a tarball from the patched release distribution.

    ```bash
    ncn-w# tar -cvzf ${UAN_RELEASE}.tar.gz "${UAN_RELEASE}/"
    ```
