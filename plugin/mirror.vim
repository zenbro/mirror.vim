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
  let current_project = split(getcwd(), '/')[-1]
  if has_key(g:mirror#config, current_project)
    call mirror#init(current_project)
    return 1
  endif
endfunction

augroup updateMirrorConfig
  autocmd!
  autocmd VimEnter * call mirror#read_config()
  execute 'autocmd BufWritePost' g:mirror#config_path
    \ 'call mirror#read_config() | '
    \ 'call DetectProjectWithMirror()'
augroup END

augroup projectWithMirrorDetect
  autocmd!
  autocmd BufNewFile,BufReadPost * call DetectProjectWithMirror()
augroup END

" TODO
" MirrorEnvironment <env> - set default environment for this session
" MirrorEnvironment! <env> - set default environment and save it
" MirrorRun <env> - run shell command remotely
" MirrorPush <env> - update remote file from local changes
" MirrorPull <env> - update local file from remote changes
" MirrorParentDirectory <env> - like MirrorOpen, but for currently open file
" MirrorDiff <env>
" MirrorSDiff <env>
" MirrorVDiff <env>
" command! MirrorEdit   call mirror#open(1, 'edit')
" command! MirrorVEdit  call mirror#open(1, 'vsplit')
" command! MirrorSEdit  call mirror#open(1, 'split')
" command! MirrorOpen   call mirror#open(0, g:mirror#open_with)
command! MirrorConfig call mirror#edit_config()
command! MirrorDetect call DetectProjectWithMirror()

" vim: foldmethod=marker
