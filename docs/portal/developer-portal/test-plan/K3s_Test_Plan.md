## Overview
Perform this procedure to verify that K3s on UANs can launch the services necessary to replicate UAIs as Podman containers. 

The steps in this guide are biased towards simplicity and light on explanation. For more detail on all of the possible configuration permutations, consult [Enabling K3s](../advanced/Enabling_K3s.md).

This procedure assumes familiarity with the commands `cray cfs`, `cray bos` and, optionally, access to `sat bootprep` automation files to assist in reconfiguration of the UAN.

## Configuration  
1. Identify a UAN that has been fully booted and configured with COS. 

  The UAN chosen must be configured with the CAN or CHN, and be able to authenticate non-root users.
  
1. Verify the UAN has the CAN or CHN configured by checking the default route (IP address masked with `x.x.x.x`):
```
$ ip r | grep default
default via x.x.x.x dev can0
```

1. Verify non-root SSH access to the UAN.  Use `chn` or `can` depending on the default route):
```
$ ssh uan01.can.lemondrop.hpc.amslabs.hpecorp.net
(alanm@uan01.can.lemondrop.hpc.amslabs.hpecorp.net) Password:
Last login: Thu Mar  9 10:24:31 2023 from x.x.x.x
lemondrop

alanm@uan01:~
```

1. Checkout the UAN CFS repository from VCS and create a new branch. 

  In the following example, the currently booted UAN was configured with `integration-2.6.0`, so that was used as the starting point. Use the correct branch for the UAN being tested.
```
$ git clone https://auth.cmn.lemondrop.hpc.amslabs.hpecorp.net/vcs/cray/uan-config-management.git

$ git branch k3s origin/integration-2.6.0
branch 'k3s' set up to track 'origin/integration-2.6.0'.
arbus ~/supercomputers/lemondrop/uan-config-management2 (main) 

$ git checkout k3s
Switched to branch 'k3s'
Your branch is up to date with 'origin/integration-2.6.0'.
```
1. Complete the [MetalLB section](../advanced/Enabling_K3s.md#metallb) of the Enabling K3s guide. 

1. Modify `vars/uan_helm.yml` (IP addresses masked with `x.x.x.x`) and commit the change.
```
$ git diff
diff --git a/vars/uan_helm.yml b/vars/uan_helm.yml
index ac55f9a..906200d 100644
--- a/vars/uan_helm.yml
+++ b/vars/uan_helm.yml
@@ -39,5 +39,5 @@ uan_haproxy:
     chart: "{{ haproxy_chart }}"
     chart_path: "{{ helm_install_path }}/charts/{{ haproxy_chart }}.tgz"

-#metallb_ipaddresspool_range_start: "<start-of-range>"
-#metallb_ipaddresspool_range_end: "<end-of-range>"
+metallb_ipaddresspool_range_start: "x.x.x.x"
+metallb_ipaddresspool_range_end: "x.x.x.x"

$ git commit -m "Add MetalLB IP Address range" vars/uan_helm.yml
[k3s 1dde4ab] Add MetalLB IP Address range
 1 file changed, 2 insertions(+), 2 deletions()
```
1. Complete the [HAProxy section](../advanced/Enabling_K3s.md#haproxy-configuration) of the Enabling K3s guide. Replace `uan01 uan01.can.lemondrop.hpc.amslabs.hpecorp.net:9000` with the DNS of the UAN chosen for this test.

The following changes to `vars/uan_helm.yml` would be suitable changes for validation:
```
$ git diff
diff --git a/vars/uan_helm.yml b/vars/uan_helm.yml
index 906200d..59e699d 100644
--- a/vars/uan_helm.yml
+++ b/vars/uan_helm.yml
@@ -38,6 +38,25 @@ uan_haproxy:
     namespace: "haproxy-uai"
     chart: "{{ haproxy_chart }}"
     chart_path: "{{ helm_install_path }}/charts/{{ haproxy_chart }}.tgz"
+    args: "--set service.type=LoadBalancer"
+    config: |
+      global
+        log stdout format raw local0
+        maxconn 1024
+      defaults
+        log     global
+        mode    tcp
+        timeout connect 10s
+        timeout client 36h
+        timeout server 36h
+        option  dontlognull
+      listen ssh
+        bind *:22
+        balance leastconn
+        mode tcp
+        option tcp-check
+        tcp-check expect rstring SSH-2.0-OpenSSH.*
+        server uan01 uan01.can.lemondrop.hpc.amslabs.hpecorp.net:9000 check inter 10s fall 2 rise 1

$ git commit -m "Add HAProxy configuration" vars/uan_helm.yml
[k3s 1b54db9] Add HAProxy configuration
 1 file changed, 19 insertions(+)
```
1. Complete the  [SSHD section](../advanced/Enabling_K3s.md#sshd-configuration) of the Enabling K3s guide. 

  These changes to `vars/uan_sshd.yml` may be used as a valid test of a podman configuration:
```
arbus ~/supercomputers/lemondrop/uan-config-management2 (k3s) $ git diff
diff --git a/vars/uan_sshd.yml b/vars/uan_sshd.yml
index 9e13ff6..2651e08 100644
--- a/vars/uan_sshd.yml
+++ b/vars/uan_sshd.yml
@@ -26,3 +26,10 @@ uan_sshd_configs:
   - name: "uai"
     config_path: "/etc/ssh/uan"
     port: "9000"
+    config: |
+      Match User *
+        AcceptEnv DISPLAY
+        X11Forwarding yes
+        AllowTcpForwarding yes
+        PermitTTY yes
+        ForceCommand podman --root /scratch/containers/$USER run -it -h uai --cgroup-manager=cgroupfs --userns=keep-id --network=host registry.local/cray/uai:1.0

$ git commit -m "Add SSH configuration" vars/uan_sshd.yml
[k3s 7df6e7c] Add SSH configuration
 1 file changed, 7 insertions(+)
 ```
1. Uncomment the following line to install the K3s artifacts without rebuilding the image and requiring a reboot:
```
$ git diff
diff --git a/k3s.yml b/k3s.yml
index d918bc9..5332c12 100644
--- a/k3s.yml
+++ b/k3s.yml
@@ -62,7 +62,7 @@
       include_role:
         name: "{{ item }}"
       with_items:
-        #- uan_k3s_stage # Uncomment to stage K3s assets without Image Customization
+        - uan_k3s_stage # Uncomment to stage K3s assets without Image Customization
         - uan_k3s_install

     - name: Configure Helm and MetalLB
       
$ git commit -m "Enabling K3s install post-boot" k3s.yml
[k3s bb323b9] Enabling K3s install post-boot
 1 file changed, 1 insertion(+), 1 deletion(-)
```
1. Push the CFS changes to the upstream repository
```
git push origin k3s
```
1. Perform the following tasks on the UAN to be tested as root, to prepare for podman:
```
mkdir /scratch/containers
chmod 777 /scratch
chmod 777 /scratch/containers

TEST_USER=<non-root username>
if ! grep -sq $TEST_USER /etc/subuid; then echo $TEST_USER:200000000:$(id -u $TEST_USER) >> /etc/subuid; fi
if ! grep -sq $TEST_USER /etc/subgid; then echo $TEST_USER:200000000:$(id -u $TEST_USER) >> /etc/subgid; fi
```
1. Create and upload a podman container to the CSM registry. 

The following example uses the default container image from the User Access Service and should be run from an NCN:
```
mkdir podman_img; cd podman_img

BASE_IMAGE=$(cray uas admin config images list --format json | jq -r '.[] | select(.default == true) | .imagename')

cat << EOF > Containerfile
FROM $BASE_IMAGE
ENTRYPOINT /bin/sh
EOF

podman build -t registry.local/cray/uai:1.0 .

PODMAN_USER=$(kubectl get secret -n nexus nexus-admin-credential -o json | jq -r '.data.username' | base64 -d)
PODMAN_PASSWD=$(kubectl get secret -n nexus nexus-admin-credential -o json | jq -r '.data.password' | base64 -d)
podman push --creds "$PODMAN_USER:$PODMAN_PASSWD" registry.local/cray/uai:1.0
```
1. Update the CFS configuration on the UAN to include the new playbook:
```
UAN=x3000c0s13b0n0

CFS_CONFIG=$(cray cfs components describe $UAN --format json | jq -r '.desiredConfig')
cray cfs configurations describe --format json $CFS_CONFIG | jq 'del(.lastUpdated, .name)' > $CFS_CONFIG.json

vim $CFS_CONFIG.json
```
The modified CFS configuration should include the following new playbook after the standard UAN `site.yaml` playbook:
```
    {
      "cloneUrl": "https://api-gw-service-nmn.local/vcs/cray/uan-config-management.git",
      "branch": "k3s",
      "name": "k3s",
      "playbook": "k3s.yml"
    },
```
1. Update the CFS Configuration and wait for the status to transition from `pending` to `configured`:
```
$ cray cfs configurations update $CFS_CONFIG --file $CFS_CONIG.json
$ cray cfs components describe $UAN --format json | jq -r .configurationStatus
pending
$ ...
$ cray cfs components describe $UAN --format json | jq -r .configurationStatus
configured
```
1. Complete the [Validation Checks](../advanced/Enabling_K3s.md#validation-checks) section of the Enabling K3s guide.