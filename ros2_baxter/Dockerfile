FROM ubuntu:jammy as ros2

# Setup environment
ENV LANG C.UTF-8
ENV LC_AL C.UTF-8
ENV ROS2_DISTRO humble
ENV DEBIAN_FRONTEND noninteractive
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES graphics,utility,compute
ENV TZ=Europe/Zagreb
# Not sure this is same in ROS and ROS 2 
# ENV ROSCONSOLE_FORMAT '[${severity}] [${time}] [${node}]: ${message}'

# Mitigate interactive prompt for choosing keyboard type
COPY ./to_copy/keyboard /etc/default/keyboard

# Setup timezone (fix interactive package installation)
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Install necessary packages for ROS and Gazebo
RUN apt-get update &&  apt-get install -q -y \
    apt-utils \
    build-essential \
    bc \
    cmake \
    curl \
    git \
    gnupg \
    lsb-release \
    libboost-dev \
    sudo \
    nano \
    net-tools \
    tmux \
    tmuxinator \
    wget \
    ranger \
    htop \
    gedit \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libeigen-stl-containers-dev 

# Prepare for ROS2
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN apt update

# Install ROS2
RUN apt-get update && \
    apt install -y \
    ros-${ROS2_DISTRO}-desktop-full \
    ros-${ROS2_DISTRO}-test-msgs 


# Install ROS2 tools
RUN apt install -y \
    python3-argcomplete \
    ros-dev-tools \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-vcstool 

# Colcon setup according to moveit tutorial 
RUN colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml
RUN colcon mixin update default

RUN apt-get install -y \
    ros-${ROS2_DISTRO}-generate-parameter-library \
    ros-${ROS2_DISTRO}-backward-ros \
    ros-${ROS2_DISTRO}-ackermann-msgs \
    ros-${ROS2_DISTRO}-gazebo-ros \
    ros-${ROS2_DISTRO}-gazebo-dev 

# Add user and add it to sudo group
RUN adduser --disabled-password --gecos '' developer 
RUN adduser developer sudo 
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER developer 
WORKDIR /home/developer

# Copy configuration files
COPY --chown=developer:developer ./to_copy/aliases /home/developer/.bash_aliases
COPY --chown=developer:developer ./to_copy/nanorc /home/developer/.nanorc
COPY --chown=developer:developer ./to_copy/tmux /home/developer/.tmux.conf
COPY --chown=developer:developer ./to_copy/ranger /home/developer/.config/ranger/rc.conf

# Build ROS control 
RUN mkdir -p /home/developer/ros2_ws/src
WORKDIR /home/developer/ros2_ws
RUN vcs import --input https://raw.githubusercontent.com/ros-controls/ros2_control_ci/master/ros_controls.humble.repos src
RUN sudo rosdep init && rosdep update --rosdistro=${ROS2_DISTRO}
RUN sudo apt-get update
RUN rosdep install --from-paths src --ignore-src -r -y
RUN bash -c ". /opt/ros/${ROS2_DISTRO}/setup.sh; colcon build --symlink-install"

# Modify .bashrc
RUN echo "" >> ~/.bashrc
RUN echo "source /opt/ros/${ROS2_DISTRO}/setup.bash" >> ~/.bashrc
RUN echo "source /home/developer/ros2_ws/install/local_setup.bash" >> ~/.bashrc

# Gazebo installation 
RUN sudo apt-get update
RUN sudo apt-get install ros-${ROS2_DISTRO}-ros-gz -y

# ros2_gz --> go through this!
RUN sudo apt-get update && \
    sudo apt-get install -y \
    ros-${ROS2_DISTRO}-ros-ign-bridge \
    ros-${ROS2_DISTRO}-vision-msgs \
    ros-${ROS2_DISTRO}-ign-ros2-control

# Install gazebo ignition fortress: https://gazebosim.org/docs/fortress/install_ubuntu/
RUN sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
RUN sudo apt-get update && sudo apt-get install -y ignition-fortress

# MoveIt 2 ws
WORKDIR /home/developer
ENV COLCON_WS /home/developer/ws_moveit2
RUN mkdir -p ${COLCON_WS}/src
WORKDIR ${COLCON_WS}/src

# Download moveit2 source code
#my moveit2 fork with fix for multiarm simultaneous planning
RUN git clone https://github.com/bornaparo/moveit2.git -b ${ROS2_DISTRO}
RUN git clone https://github.com/moveit/py_binding_tools.git -b ros2
RUN for repo in moveit2/moveit2.repos $(f="moveit2/moveit2_${ROS2_DISTRO}.repos"; test -r $f && echo $f); do vcs import < "$repo"; done
RUN rosdep install -r --from-paths . --ignore-src --rosdistro ${ROS2_DISTRO} -y

# Install middleware 
RUN sudo apt install ros-${ROS2_DISTRO}-rmw-cyclonedds-cpp -y
RUN export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc

# Build MoveIt!
WORKDIR ${COLCON_WS}
RUN sudo apt install ros-${ROS2_DISTRO}-ament-cmake-python
RUN sudo apt-get install ros-${ROS2_DISTRO}-rviz-visual-tools 
# RUN bash -c "source /opt/ros/humble/setup.sh; source ~/.bashrc; MAKEFLAGS="-j${nproc-1}" colcon build --event-handlers desktop_notification- status- --cmake-args -DCMAKE_BUILD_TYPE=Release"
RUN bash -c "source /opt/ros/humble/setup.sh; source ~/.bashrc; colcon build --executor parallel --parallel-workers 2 --event-handlers desktop_notification- status- --cmake-args -DCMAKE_BUILD_TYPE=Release"
# WORKDIR ${COLCON_WS}/src
WORKDIR ${COLCON_WS}/src
RUN git clone https://github.com/moveit/moveit2_tutorials.git -b ${ROS2_DISTRO} \
    && git clone https://github.com/moveit/moveit_visual_tools.git -b ros2 \
    && git clone https://github.com/PickNikRobotics/graph_msgs.git -b ros2 \
    && git clone https://github.com/moveit/moveit_task_constructor.git -b ${ROS2_DISTRO}
WORKDIR ${COLCON_WS}
# RUN bash -c "source /opt/ros/humble/setup.sh; source ~/.bashrc; MAKEFLAGS="-j${nproc-1}" colcon build --event-handlers desktop_notification- status- --cmake-args -DCMAKE_BUILD_TYPE=Release"
RUN bash -c "source /opt/ros/humble/setup.sh; source ~/.bashrc; colcon build --executor parallel --parallel-workers 2 --event-handlers desktop_notification- status- --cmake-args -DCMAKE_BUILD_TYPE=Release"
RUN echo "source ${COLCON_WS}/install/setup.bash" >> ~/.bashrc

# Download minimal ros1 files needed for creating ros1<->ros2 bridge
WORKDIR /home/developer
RUN wget -O minimal_ros1_files.deb "https://box.ec-nantes.fr/index.php/s/s7rbFwAeTqwoe6e/download?path=%2F&files=ros-baxter%5Bjammy%5D_1.3.1.deb" \
    && sudo apt-get update \
    && sudo apt-get install -y ./minimal_ros1_files.deb \
    && rm minimal_ros1_files.deb

# Necessary packages for controlling the baxter
WORKDIR /home/developer/baxter_ws/src
RUN git clone https://github.com/bornaparo/baxter_common_ros2.git \
    && git clone https://github.com/bornaparo/rviz_gazebo_bridge.git \
    && git clone https://github.com/bornaparo/baxter_moveit2_examples.git \
    && git clone https://github.com/bornaparo/baxter_moveit_config.git \
    && git clone https://github.com/bornaparo/baxter_moveit2_adapter.git \
    && rosdep install -r --from-paths . -y --ignore-src
WORKDIR /home/developer/baxter_ws
RUN bash -c "source /opt/ros/humble/setup.sh; source ${COLCON_WS}/install/setup.bash; colcon build" \
    && echo "source /home/developer/baxter_ws/install/setup.bash" >> ~/.bashrc

# Add address resolution so the container can get baxter's topics
RUN bash -c "echo '192.168.2.69 011404P0015.local' | sudo tee -a /etc/hosts"

# Add exports to the .bashrc
RUN bash -c "echo 'export ROS_MASTER_URI=http://192.168.2.69:11311' >> ~/.bashrc && \
             echo 'export ROS_IP=192.168.2.101' >> ~/.bashrc"

WORKDIR /home/developer

CMD ["bash"]
