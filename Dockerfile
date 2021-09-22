FROM ubuntu

RUN groupadd -r bora && useradd -r -g bora bora

LABEL version="1.0"


CMD ["/usr/bin/wc","--help"]

