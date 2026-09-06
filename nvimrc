" System-wide Neovim preferences installed by Debian-fix.sh.

" Enable mouse support in every mode.
set mouse=a

" Complete the longest common match, list alternatives, then cycle matches.
set wildmode=longest,list,full

" Use four-column indentation when editing C source and header files.
augroup vimrcEx
  au!
  autocmd FileType text setlocal textwidth=78
  autocmd FileType c setlocal shiftwidth=4 softtabstop=4
augroup END
