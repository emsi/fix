#!/bin/bash

#"Debian" "fix" script

sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups/' /etc/skel/.bashrc
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups/' ~/.bashrc

# Perhaps a local alternative alias ls='LC_COLLATE=C.UTF-8 ls'
echo 'LC_COLLATE="C.UTF-8"' >> /etc/default/locale
