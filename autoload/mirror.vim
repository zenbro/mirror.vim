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

if exists('g:autoloaded_mirror')
  finish
endif
let g:autoloaded_mirror = 1

let g:mirror#config_path = get(g:, 'mirror#config_path', $HOME . '/.mirrors')
let g:mirror#open_with = get(g:, 'mirror#open_with', 'Unite')
let g:mirror#config = {}

function! s:parse_mirrors(list)
  let result = {}
  let current_node = ''
  for line in a:list
    if empty(line) || match(line, '\s\*#') != -1
      continue
    endif
    if match(line, '^\s\+') == -1
      let current_node = substitute(line, ':$', '', '')
      let result[current_node] = {}
    else
      let [env, remote_path] = s:get_environment_and_path(line)
      let result[current_node][env] = remote_path
    endif
  endfor
  return result
endfunction

function! s:get_environment_and_path(line)
  let [environment, remote_path] = split(a:line)
  let environment = substitute(environment, ':$', '', '')
  let remote_path = substitute(remote_path, '\s', '', 'g')
  let remote_path = substitute(remote_path, '/$', '', '')
  return [environment, remote_path]
endfunction

function! mirror#read_config()
  if filereadable(g:mirror#config_path)
    let g:mirror#config = s:parse_mirrors(readfile(g:mirror#config_path))
  endif
  return g:mirror#config
endfunction

function! s:current_project()
  return 
endfunction

function! s:prepend_ssh(string)
  if stridx(a:string, 'ssh://') == -1
    return 'ssh://' . a:string
  endif
  return a:string
endfunction

function! s:find_remote_path(project, env, mirrors)
  if has_key(a:mirrors, a:project)
    let project_mirrors = get(a:mirrors, a:project)
    if has_key(project_mirrors, a:env)
      return s:prepend_ssh(get(project_mirrors, a:env))
    elseif a:env ==# 'default' && len(project_mirrors) == 1
      return s:prepend_ssh(values(project_mirrors)[0])
    endif
  endif
endfunction

function! s:get_default_env(project)
  " TODO implement Menv and cache for default env
  return 'default'
endfunction

function! mirror#open(is_file, command)
  let local_path = '/' . expand(@%)
  let project = s:current_project()
  let mirrors = s:find_global_mirrors()
  let env = s:get_default_env(project)

  let remote_path = s:find_remote_path(project, env, mirrors)
  if !empty(remote_path)
    let full_path = a:is_file ? remote_path . local_path : remote_path
    echo 'Opening' full_path . '...'
    execute ':' . a:command full_path
    echo
  else
    echo 'Can''t find any mirror for this project' '('.project.')...'
  endif
endfunction

function! mirror#edit_config()
  execute ':botright split' g:mirror#config_path
endfunction

function! mirror#init(current_project)
  echo 'init! for ' . a:current_project
  command! -buffer MirrorEdit   call mirror#open(1, 'edit')
  command! -buffer MirrorVEdit  call mirror#open(1, 'vsplit')
  command! -buffer MirrorSEdit  call mirror#open(1, 'split')
  command! -buffer MirrorOpen   call mirror#open(0, g:mirror#open_with)
endfunction

" vim: foldmethod=marker
