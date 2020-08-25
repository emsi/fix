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
  
  " yaml 2-space 
  autocmd FileType yaml                 setlocal ts=2 sts=2 sw=2 expandtab


  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")
