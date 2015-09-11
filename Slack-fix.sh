#!/bin/sh

echo "Fixing /etc/rc.d/rc.inet1"
cat > /etc/rc.d/rc.inet1 << EOF
#! /bin/sh
#
# rc.inet1      This shell script boots up the base INET system.
#
# Version:      Slack-fix 0.1
#

/sbin/ifconfig lo down
/sbin/ifconfig eth0 down

# Attach the loopback device.
/sbin/ifconfig lo 127.0.0.1
/sbin/route add -net 127.0.0.0 netmask 255.0.0.0 lo

/sbin/ifconfig eth0 IP netmask NETMASK

/sbin/route add default gw GATEWAY

# End of rc.inet1
EOF

echo "Fixing /etc/resolv.conf"
cat > /etc/resolv.conf << EOF
nameserver 217.8.168.244
nameserver 157.25.5.18
search clubbing.pl
EOF

echo "Adding /etc/csh.cshrc"
cat >> /etc/csh.cshrc << EOF
alias la 'ls -la'
set autolist
unset autologout
bindkey "^R" i-search-back
EOF

echo "Fixing /etc/csh.login"
patch /etc/csh.login - << EOF
--- ./csh.login~	2007-08-09 14:45:35.000000000 +0200
+++ /etc/csh.login	2007-08-09 14:49:47.000000000 +0200
@@ -11,7 +11,7 @@
 	setenv HOSTNAME "`cat /etc/HOSTNAME`"
 	setenv LESS "-M"
 	setenv LESSOPEN "|lesspipe.sh %s"
-	set path = ( /usr/local/bin /usr/bin /bin /usr/games )
+	set path = ( \$path /usr/X11R6/bin )
 endif
 
 # If the user doesn't have a .inputrc, use the one in /etc.
@@ -30,14 +30,15 @@
 if ("$TERM" == "unknown") setenv TERM linux
 
 # Set default POSIX locale:
-setenv LC_ALL POSIX
+#setenv LC_ALL POSIX
+setenv LC_CTYPE polish
 
 # Set the default shell prompt:
 set prompt = "%n@%m:%~%# "
 
 # Notify user of incoming mail.  This can be overridden in the user's
 # local startup file (~/.login)
-biff y >& /dev/null
+#biff y >& /dev/null
 
 # Set an empty MANPATH if none exists (this prevents some profile.d scripts
 # from exiting from trying to access an unset variable):
EOF

echo "Adding /usr/share/vim/vimrc"
cat > /usr/share/vim/vimrc << EOF
" Emsi vim rc file

" Use Vim settings, rather then Vi settings (much better!).
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup  		" keep a backup file
endif

set history=50		" keep 50 lines of command line history
set undolevels=100	" keep 100 undo operations

syntax on		" Switch syntax highlighting on and...
"set hlsearch		" highlighting the last used search pattern

set incsearch		" do incremental searching
set background=dark	" tell vim that your background is dark

set wildmode=longest,list,full	" shell like autocomplete

set mouse=a		" enable mouse

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  " Remove ALL autocommands for the current group.
  au!			

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text		setlocal textwidth=78

  " C files indentation format compatible with indent:
  " -i4 -ts8 -di0 -br -ce -nbad -nbap -nbbb -sob
  autocmd BufRead,BufNewFile *.[ch]	setlocal softtabstop=4 shiftwidth=4

  autocmd BufRead,BufNewFile *.rules	setlocal filetype=sh

  " make crontab work better!
  autocmd BufRead,BufNewFile crontab.*  set compatible

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")
EOF

echo "Fixing vi to be vim"
ln -sf /usr/bin/vim /usr/bin/vi

echo "Fixing /etc/passwd"
sed -i -e 's#/root:/bin/bash#/root:/bin/tcsh#' /etc/passwd

echo "Removing bogus packages"
removepkg /var/adm/packages/loadlin*

echo "Testing Fix."
echo "Please test your commands."
echo "Don't forget to edit crontab."
echo "Executing su -"
su -
