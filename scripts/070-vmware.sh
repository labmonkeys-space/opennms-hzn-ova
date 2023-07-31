#!/bin/sh -eux
apt-get install -y open-vm-tools;
mkdir /mnt/hgfs;
systemctl enable open-vm-tools
systemctl start open-vm-tools
