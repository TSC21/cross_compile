FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Common for all
RUN apt-get update && apt-get install --no-install-recommends -q -y \
    build-essential \
    cmake \
    python3-pip \
    wget

RUN pip3 install colcon-common-extensions colcon-mixin

# Specific at the end (layer sharing)
RUN apt-get update && apt-get install --no-install-recommends -q -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu

RUN apt-get update && apt-get install -q -y --no-install-recommends rsync

RUN pip3 install lark-parser numpy

# Set up build tools for the workspace
COPY mixins/ mixins/
RUN colcon mixin add cc_mixin file://$(pwd)/mixins/index.yaml && colcon mixin update cc_mixin
# In case the workspace did not actually install any dependencies, add these for uniformity
COPY build_workspace.sh /root
COPY toolchains/ /toolchains/
WORKDIR /ros_ws
COPY user-custom-post-build /
RUN chmod +x /user-custom-post-build
ENTRYPOINT ["/root/build_workspace.sh"]
