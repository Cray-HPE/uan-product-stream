# Customizing UAN Images Manually

1. Query IMS for the UAN Image you want to customize.

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
      "name": "uan-PRODUCT_VERSION-image"
    }
    ```

2. Create a variable for the IMS image `id` in the returned data.

   ```bash
   ncn-m001:~/ $ export IMS_IMAGE_ID=6d46d601-c41f-444d-8b49-c9a2a55d3c21
   ```

3. Using the IMS_IMAGE_ID, follow the instructions in the _Customize an Image Root Using IMS_ in the CSM documentation to build the UAN Image.
