"=============================================================================
" FILE: mirror.vim
" AUTHOR:  Alexander Tsygankov <capybarov@gmail.com>
" License: MIT {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

function! DetectProjectWithMirror()
  let cwd = getcwd()
  " sorting projects path by its lengths in desc order
  " it helps to avoid discovery of wrong projects in following situation:
  " current working directory: /home/user/work/project
  " configuration include two projects:
  " /home/user/work         <= without sorting, this project will be used
  " /home/user/work/project
  let projects = reverse(sort(keys(g:mirror#config)))
  for project in projects
    let m = matchlist(cwd, '\(' . project . '\)')
    if !empty(m)
      call mirror#InitForBuffer(project)
      return 1
    endif
  endfor
endfunction

augroup updateMirrorConfigAndCache
  autocmd!
  autocmd VimEnter * call mirror#ReadConfig() |
        \ call mirror#ReadCache() |
        \ call DetectProjectWithMirror()
  execute 'autocmd BufWritePost' g:mirror#config_path
    \ 'call mirror#ReadConfig() | '
    \ 'call DetectProjectWithMirror()'
augroup END

augroup projectWithMirrorDetect
  autocmd!
  autocmd BufNewFile,BufReadPost * call DetectProjectWithMirror()
augroup END

command! MirrorConfig call mirror#EditConfig()
command! MirrorDetect call DetectProjectWithMirror()

nnoremap <silent> <Plug>(mirror_close_remote_buffer)
      \ :call mirror#CloseRemoteBuffer()<CR>

" vim: foldmethod=marker
