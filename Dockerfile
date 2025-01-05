# Start with Ubuntu 16.04
FROM ubuntu:16.04

# Set the maintainer label (optional)
LABEL maintainer="your_name@example.com"

# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4475023EB6D7BF29
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EB9326A7BF6DFCD


# Install glfw3 repo for Ubuntu 14.04
# RUN echo "deb http://ppa.launchpad.net/keithw/glfw3/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/fillwave_ext.list

# Install dependencies: gcc, g++, git, wget, vim, xz-utils
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    wget \
    vim \
    xz-utils \
    libx11-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    libglfw3-dev \
    mingw-w64 \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Nim
RUN wget https://nim-lang.org/download/nim-2.2.0-linux_x64.tar.xz -P /root \
    && tar -xf /root/nim-2.2.0-linux_x64.tar.xz -C /root \
    && rm /root/nim-2.2.0-linux_x64.tar.xz

# Download and extract Go
RUN wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -P /root \
    && tar -xf /root/go1.23.4.linux-amd64.tar.gz -C /root \
    && rm /root/go1.23.4.linux-amd64.tar.gz

# Download and extract Zig compiler
# RUN wget https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.2458+10282eae6.tar.xz -P /root \
#     && tar -xf /root/zig-linux-x86_64-0.14.0-dev.2458+10282eae6.tar.xz -C /root \
#     && rm /root/zig-linux-x86_64-0.14.0-dev.2458+10282eae6.tar.xz

# Append Nim's bin directory to PATH in .bashrc
RUN echo 'export PATH=$PATH:/root/nim-2.2.0/bin' >> /root/.bashrc
RUN echo 'export PATH=$PATH:/root/go/bin' >> /root/.bashrc
RUN echo 'export PATH=$PATH:/root/.nimble/bin' >> /root/.bashrc
# RUN echo 'export PATH=$PATH:/root/zig-linux-x86_64-0.14.0-dev.2458+10282eae6' >> /root/.bashrc

# Source .bashrc to update the environment
RUN echo "source /root/.bashrc" >> /root/.bash_profile

# Start with an interactive bash shell
CMD ["/bin/bash"]

