FROM debian:9
RUN apt-get update -y && \
    apt-get install -y \
        autoconf \
        automake \
        bison \
        debhelper \
        devscripts \
        flex \
        g++-6 \
        gcc-6 \
        gfortran \
        gfortran-6 \
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
