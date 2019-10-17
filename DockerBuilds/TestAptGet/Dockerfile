FROM ubuntu:18.04
RUN apt-get update -y && \
    apt-get install -y \
        software-properties-common 
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5a4c7db8f95ad138
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DF61639161C9A719
	
#Start after here to maintain keys and repo	
RUN apt-get update -y && \
	apt-get install -y \
		git \
		vim
COPY sources.list /etc/apt/sources.list
COPY rose_hello-world.c /root/rose_hello-world.c 
COPY rose_hello-world.cpp /root/rose_hello-world.cpp 
COPY test-ROSE.sh /usr/local/bin/test-ROSE.sh
ENTRYPOINT ["test-ROSE.sh"]
