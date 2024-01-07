#!/bin/bash


# If you want to provision multiple vms you can create multiple user data files for each


# Updating the os
apt update -y && apt upgrade -y

# Installing Apache2
apt install -y apache2

# Starting and enabling apache2 service
systemctl start apache2
systemctl enable apache2

# Change directory to user home

cd /home/ubuntu

# Cloning my website from github, Clone any website you have if you want
git clone https://github.com/MoamenZyan/Zyan-Website.git

# Copying my website files into base directory for apache to be published
cp -r Zyan-Website/* /var/www/html/

# Deleting my website directory in user home
rm -rf Zyan-Website/
