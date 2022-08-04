rm -rf build/;
mkdir build/;
mkdir build/PDF;
export DOCS_BUILD_DIR=$PWD;
echo "Building UAN Install Guide";
dita -i uan_install.ditamap -o build/install -f HPEscHtml5 && cp install_publication.json build/install/publication.json && cd build/install/ && zip -r crs8032_3en_us.zip ./;
cd $DOCS_BUILD_DIR;
dita -i uan_install.ditamap -o build/PDF/install -f pdf;
echo "Building UAN Admin Guide";
dita -i uan_admin.ditamap -o build/admin -f HPEscHtml5 && cp admin_publication.json build/admin/publication.json && cd build/admin/ && zip -r crs8033_3en_us.zip ./;
cd $DOCS_BUILD_DIR;
dita -i uan_admin.ditamap -o build/PDF/admin -f pdf; 


