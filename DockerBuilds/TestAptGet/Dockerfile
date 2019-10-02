FROM ubuntu:18.04
RUN apt-get update -y && \
    apt-get install -y \
        software-properties-common 
COPY sources.list /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5a4c7db8f95ad138
RUN apt-get update --allow-insecure-repositories
	
#Start after here to maintain keys and repo	
COPY rose_hello-world.c /root/rose_hello-world.c 
COPY rose_hello-world.cpp /root/rose_hello-world.cpp 
COPY test-ROSE.sh /usr/local/bin/test-ROSE.sh
CMD test-ROSE.sh ; bash
