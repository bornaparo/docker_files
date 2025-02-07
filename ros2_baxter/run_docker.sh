#!/bin/bash

CONTAINER_NAME=ros2_baxter
IMAGE_NAME=ros2_baxter_img:latest

# Hook to the current SSH_AUTH_LOCK - since it changes
# https://www.talkingquickly.co.uk/2021/01/tmux-ssh-agent-forwarding-vs-code/
ln -sf $SSH_AUTH_SOCK ~/.ssh/ssh_auth_sock

docker run \
  -it \
  --network host \
  --add-host=011404P0015.local=192.168.2.69 \
  --privileged \
  --volume /dev:/dev \
  --volume /tmp/.x11-unix:/tmp/.x11-unix \
  --volume ~/.ssh/ssh_auth_sock:/ssh-agent \
  --env SSH_AUTH_SOCK=/ssh-agent \
  --env DISPLAY=$DISPLAY \
  --env TERM=xterm-256color \
  --name $CONTAINER_NAME \
  $IMAGE_NAME \
  /bin/bash
