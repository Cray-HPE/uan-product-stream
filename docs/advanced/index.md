# Cray EX User Access Node Installation Advanced Topics

> version: @product_version@
>
> build date: @date@

This section describes advanced topics for installing and operating User
Access Nodes (UAN) on Cray EX systems.

---

## Contents

* [Building the UAN image using the Cray Image Management System (IMS)](#buildrecipe)

---

<a name="buildrecipe"></a>

The Cray EX User Access Node product installer automatically registers a recipe with the Cray Image Management System 
(IMS). This recipe can be used to (re-)build the UAN image following the instructions below.

---
**NOTE**

The Cray EX User Access Node (UAN) recipe currently requires rpms that are not installed with the UAN product. The UAN
recipe can only be built after the Cray OS (COS) and Slingshot products are also installed on to the system. 

In future releases of the UAN product, work will be undertaken to resolve these dependency issues.

---

1. Locate the UAN Image Recipe within the Cray Image Management System (IMS).

        ~ # cray ims recipes list --format json | jq '.[] | select(.name | contains("uan"))'
        ...
        {
          "created": "2021-02-17T15:19:48.549383+00:00",
          "id": "4a5d1178-80ad-4151-af1b-bbe1480958d1",  <<-- Note this ID
          "link": {
            "etag": "3c3b292364f7739da966c9cdae096964",
            "path": "s3://ims/recipes/4a5d1178-80ad-4151-af1b-bbe1480958d1/recipe.tar.gz",
            "type": "s3"
          },
          "linux_distribution": "sles15",
          "name": "cray-shasta-uan-cos-sles15sp1.x86_64-@product_version@",
          "recipe_type": "kiwi-ng"
        }
        ...

   If successful, create a variable for the IMS recipe `id` in the returned data.

        ~ # export IMS_RECIPE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1

1. Using the IMS_RECIPE_ID, follow the instuctions in the _Build an Image Using IMS REST Service_ section of the 
   _HPE Cray EX System Administraion Guide_ to build the UAN Image.