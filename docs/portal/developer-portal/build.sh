rm -rf build/;
mkdir build/;
dita -i *.ditamap -o build -f html5 && cp publication.json build/ && cd build/ && zip -r x1234567en_us.zip ./



