FROM ubuntu:16.04
RUN apt-get update -y && \
    apt-get install -y \
        autoconf \
        automake \
        bison \
        debhelper \
        devscripts \
        flex \
        g++-5 \
        gcc-5 \
        gfortran \
        gfortran-5 \
        ghostscript \
        git \
        libboost-all-dev \
        libtool \
        libxml2-dev \
        lsb-core \
        make \
        openjdk-8-jdk \
        perl-doc \
        python \
        texlive \
        vim \
        wget 
COPY .gnupg /root/.gnupg
COPY build-ROSE.sh /usr/local/bin/build-ROSE.sh
CMD /bin/bash
