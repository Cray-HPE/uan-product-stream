rm -rf build/;
mkdir build/;
export DOCS_BUILD_DIR=$PWD;
echo "Building UAN Install Guide";
dita -i uan_install.ditamap -o build/install -f HPEscHtml5 && cp install_publication.json build/install/publication.json && cd build/install/ && zip -r crs8032_1en_us.zip ./;
cd $DOCS_BUILD_DIR;
echo "Building UAN Admin Guide";
dita -i uan_admin.ditamap -o build/admin -f HPEscHtml5 && cp admin_publication.json build/admin/publication.json && cd build/admin/ && zip -r crs8033_1en_us.zip ./;



