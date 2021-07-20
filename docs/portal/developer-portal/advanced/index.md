## Customizing UAN Images Manually

1. Locate the UAN Image you want to customize from the Cray Image Management System (IMS).

    ```bash
    ncn-m001:~/ $ cray ims images list --format json | jq '.[] | select(.name | contains("uan"))'
    {
      "created": "2021-02-18T17:17:44.168655+00:00",
      "id": "6d46d601-c41f-444d-8b49-c9a2a55d3c21",
      "link": {
        "etag": "371b62c9f0263e4c8c70c8602ccd5158",
        "path": "s3://boot-images/6d46d601-c41f-444d-8b49-c9a2a55d3c21/manifest.json",
        "type": "s3"
      },
      "name": "uan-@product_version@-image"
    }
    ```

   If successful, create a variable for the IMS recipe `id` in the returned data.

    ```bash
    ncn-m001:~/ $ export IMS_IMAGE_ID=4a5d1178-80ad-4151-af1b-bbe1480958d1
   ```

1. Using the IMS_IMAGE_ID, follow the instructions in the _Customize an Image Root Using IMS_ to build the UAN Image.
