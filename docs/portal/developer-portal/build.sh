rm -rf build/;
mkdir build/;
mkdir build/PDF;
export DOCS_BUILD_DIR=$PWD;
echo "Building UAN Install Guide";
# This line builds the HPESC HTML bundle for the install guide
dita -i uan_install_guide.ditamap -o build/install -f HPEscHtml5 && cp install_publication.json build/install/publication.json && cd build/install/ && zip -r crs8032_3en_us.zip ./;
cd $DOCS_BUILD_DIR;
# this builds the PDF using DITA-OT's default PDF transform
dita -i uan_install_guide.ditamap -o build/PDF/install -f pdf;
#This builds the single file Markdown version of the guide. This leverages DITA's "chunking"
dita -i uan_install_guide.ditamap --root-chunk-override=to-content -o build/Markdown -f markdown_github
#Repeat the process for the Admin Guide
echo "Building UAN Admin Guide";
dita -i uan_admin_guide.ditamap -o build/admin -f HPEscHtml5 && cp admin_publication.json build/admin/publication.json && cd build/admin/ && zip -r crs8033_3en_us.zip ./;
cd $DOCS_BUILD_DIR;
dita -i uan_admin_guide.ditamap -o build/PDF/admin -f pdf; 
dita -i uan_admin_guide.ditamap --root-chunk-override=to-content -o build/Markdown -f markdown_github
#DITA-OT spits out the individual Markdown files (which we don't want) in addition to the unified Md files (that we do want). These lines get rid of the extra files 
mv build/Markdown/uan_*_guide.md build/
rm -rf build/Markdown/*
mv build/uan_*_guide.md build/Markdown/



