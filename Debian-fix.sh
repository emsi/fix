#!/bin/bash

#"Debian" "fix" script

# Infinite history
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups/' /etc/skel/.bashrc
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups/' ~/.bashrc

# vi editor
echo "export EDITOR=vi" >> /etc/skel/.bashrc
echo "export EDITOR=vi" >> ~/.bashrc

# vimrc file
wget -qO- https://raw.githubusercontent.com/emsi/fix/master/vimrc > /usr/share/vim/vimrc

# Perhaps a local alternative alias ls='LC_COLLATE=C.UTF-8 ls'
echo 'LC_COLLATE="C.UTF-8"' >> /etc/default/locale
