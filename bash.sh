#!/bin/bash
  
echo "Run my docker file"

echo "Dockerfile" 
cat > Dockerfile  << EOF

FROM ubuntu

CMD ["wc", "--help"]

EOF

echo "Building Dockerfile and runing it"
docker build -t testubuntu:latest . && docker run -it testubuntu:latest
                                                                                