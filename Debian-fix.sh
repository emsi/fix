#!/bin/bash

#"Debian" "fix" script

# preserver home in sudo (ubuntu behavior)
# https://unix.stackexchange.com/questions/91384/how-is-sudo-set-to-not-change-home-in-ubuntu-and-how-to-disable-this-behavior
echo 'Defaults	env_keep+="HOME"' >> /etc/sudoers

# Infinite history
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups:erasedups/' /etc/skel/.bashrc
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups:erasedups/' ~/.bashrc
sed -i -e 's/HISTCONTROL=.*/HISTCONTROL=ignoredups:erasedups/' /root/.bashrc
sed -i -e 's/HISTSIZE=.*/HISTSIZE=100000/' /etc/skel/.bashrc
sed -i -e 's/HISTSIZE=.*/HISTSIZE=100000/' ~/.bashrc
sed -i -e 's/HISTSIZE=.*/HISTSIZE=100000/' /root/.bashrc
sed -i -e 's/HISTFILESIZE=.*/HISTFILESIZE=100000/' /etc/skel/.bashrc
sed -i -e 's/HISTFILESIZE=.*/HISTFILESIZE=100000/' ~/.bashrc
sed -i -e 's/HISTFILESIZE=.*/HISTFILESIZE=100000/' /root/.bashrc

# vi editor
echo "export EDITOR=vi" >> /etc/skel/.bashrc
echo "export EDITOR=vi" >> ~/.bashrc
echo "export EDITOR=vi" >> /root/.bashrc

# History preservance
cat >> /etc/skel/.bashrc << EOF
shopt -s histappend                      # append to history, don't overwrite it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
EOF

# History preservance
cat >> ~/.bashrc << EOF
shopt -s histappend                      # append to history, don't overwrite it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
EOF

# History preservance
cat >> /root/.bashrc << EOF
shopt -s histappend                      # append to history, don't overwrite it
export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
EOF

# vimrc file
wget -qO- https://raw.githubusercontent.com/emsi/fix/master/vimrc > /usr/share/vim/vimrc

# Perhaps a local alternative alias ls='LC_COLLATE=C.UTF-8 ls'
echo 'LC_COLLATE="C.UTF-8"' >> /etc/default/locale
