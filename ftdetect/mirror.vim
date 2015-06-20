" autocmd BufRead,BufNewFile *.mirrors set ft=yaml
execute 'autocmd BufRead' g:mirror#config_path 'set ft=yaml'
