path="XXy/Monopogen"

python  ${path}/src/Monopogen.py  preProcess -b bam.lst -o out -t 8


python  ${path}/src/Monopogen.py  germline  \
    -t 8   -r  region.lst \
    -p  ../example/ \
    -g  ../example/chr20_2Mb.hg38.fa   -m 3 -s all  -o out


     
