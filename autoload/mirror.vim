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

if exists('g:autoloaded_mirrors')
  finish
endif
let g:autoloaded_mirrors = 1

let g:mirrors_file =  $HOME . '/.mirrors'
let g:mirrors_dir_command = 'Unite'

function! s:parse_global_mirrors(list)
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

function! s:parse_local_mirrors(list)
  let result = {}
  for line in a:list
    if empty(line) || match(line, '\s\*#') != -1
      continue
    endif
      let [env, remote_path] = s:get_environment_and_path(line)
      let result[env] = remote_path
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

function! s:find_global_mirrors()
  if filereadable(g:mirrors_file)
    return s:parse_global_mirrors(readfile(g:mirrors_file))
  endif
  return {}
endfunction

function! s:find_local_mirrors()
  let local_mirrors = getcwd() . '/.mirrors'
  if filereadable(local_mirrors)
    return s:parse_local_mirrors(readfile(local_mirrors))
  endif
  return {}
endfunction

function! s:current_project()
  return split(getcwd(), '/')[-1]
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

function! mirror#open(is_file, command, ...)
  let env = empty(a:0) ? 'default' : a:0
  let local_path = '/' . expand(@%)
  let project = s:current_project()
  let mirrors = s:find_global_mirrors()
  let local_mirrors = s:find_local_mirrors()

  if has_key(mirrors, project)
    call extend(mirrors[project], local_mirrors)
  else
    let mirrors[project] = local_mirrors
  endif

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

function! mirror#edit_global_mirrors()
  execute ':botright split' g:mirrors_file
endfunction

function! mirror#edit_local_mirrors()
  let local_mirrors = getcwd() . '/.mirrors'
  execute ':botright split' local_mirrors
endfunction

" vim: foldmethod=marker
