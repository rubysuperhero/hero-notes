autocmd BufNewFile,BufRead */notes/*
      \ if &ft =~# '^\%(markdown\)$' |
      \   set ft=notes |
      \ else |
      \   setf notes |
      \ endif

autocmd BufNewFile,BufRead *hero/notes/*
      \ if &ft =~# '^\%(rb\)$' |
      \   set ft=notes2 |
      \ else |
      \   setf notes2 |
      \ endif
