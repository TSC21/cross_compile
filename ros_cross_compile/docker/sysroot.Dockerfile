# This file describes an image that has everything necessary installed to build a target ROS workspace

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG ROS_VERSION

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# # Add the ros apt repo
RUN apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        dirmngr \
        gnupg2 \
        lsb-release \
    && rm -rf /var/lib/apt/lists/*
RUN if [[ "${ROS_VERSION}" == "ros2" ]]; then \
      curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg; \
      echo "deb [signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/${ROS_VERSION}/ubuntu `lsb_release -cs` main" | \
          tee /etc/apt/sources.list.d/ros2.list > /dev/null; \
    else \
      curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - ; \
      echo "deb http://packages.ros.org/${ROS_VERSION}/ubuntu `lsb_release -cs` main" \
          > /etc/apt/sources.list.d/${ROS_VERSION}-latest.list; \
    fi

# ROS dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
      python3-pip \
      python3-colcon-common-extensions \
      python3-colcon-mixin \
      python3-dev \
      libssl-dev \
      symlinks \
    && rm -rf /var/lib/apt/lists/*

# Install Fast-RTPS dependencies for ROS 2
RUN if [[ "${ROS_VERSION}" == "ros2" ]]; then \
    apt-get update && apt-get install --no-install-recommends -y \
        libasio-dev \
        libtinyxml2-dev \
    && rm -rf /var/lib/apt/lists/* \
  ; fi

# Run arbitrary user setup (copy data and run script)
COPY user-custom-data/ custom-data/
COPY user-custom-setup .
RUN chmod +x ./user-custom-setup && \
    ./user-custom-setup && \
    rm -rf /var/lib/apt/lists/*

ARG DEPENDENCY_SCRIPT
# Use generated rosdep installation script
COPY ${DEPENDENCY_SCRIPT} .
RUN chmod +x ${DEPENDENCY_SCRIPT}
RUN apt-get update && \
    ./${DEPENDENCY_SCRIPT} && \
    rm -rf /var/lib/apt/lists/*

# Make all absolute symlinks in the filesystem relative, so that we can use it for cross-compilation
RUN symlinks -rc /
