#!/bin/bash
set -x
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8 >/dev/null 2>&1

#we install all in /
cd /

apt-get -yqq update > /dev/null 2>&1
apt-get -yqq install git wget curl > /dev/null 2>&1
rm -rf /sg-aws-demo
git clone https://github.com/floragunncom/sg-aws-demo.git
chmod +x /sg-aws-demo/scripts/*.sh
cd /sg-aws-demo

until /sg-aws-demo/scripts/install_sg.sh; do
  echo "something goes wrong, retrying in 60 seconds..."
  git pull
  sleep 60
done
