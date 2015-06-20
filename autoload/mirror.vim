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
let g:mirror#diff_layout = get(g:, 'g:mirror#diff_layout', 'vsplit')
let g:mirror#cache_dir = get(
      \ g:, 'mirror#cache_dir',
      \ $HOME . '/.cache/mirror.vim'
      \ )

let g:mirror#config = {}
let g:mirror#local_default_environments = {}
let g:mirror#global_default_environments = {}

" Parse line like 'environment: remote_path'
function! s:GetEnvironmentAndPath(line)
  let [environment, remote_path] = split(a:line)
  let environment = substitute(environment, ':$', '', '')
  let remote_path = substitute(remote_path, '\s', '', 'g')
  let remote_path = substitute(remote_path, '/$', '', '')
  return [environment, remote_path]
endfunction

" Parse lines from mirrors config, return dictionary
function! s:ParseMirrors(list)
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
      let [env, remote_path] = s:GetEnvironmentAndPath(line)
      let result[current_node][env] = remote_path
    endif
  endfor
  return result
endfunction

" Read mirrors config into memory
function! mirror#ReadConfig()
  if filereadable(g:mirror#config_path)
    let g:mirror#config = s:ParseMirrors(readfile(g:mirror#config_path))
  endif
  return g:mirror#config
endfunction

" Read cache file into memory
function! mirror#ReadCache()
  let path = g:mirror#cache_dir . '/default_environments'
  if filereadable(path)
    let default_environments = eval(readfile(path)[0])
    if type(default_environments) ==# type({})
      let g:mirror#global_default_environments = default_environments
    endif
  endif
endfunction

" Save global environment sessions into cache file
function! s:UpdateCache()
  if !isdirectory(g:mirror#cache_dir)
    call mkdir(g:mirror#cache_dir, 'p')
  endif
  call writefile(
        \ [string(g:mirror#global_default_environments)],
        \ g:mirror#cache_dir . '/default_environments'
        \ )
endfunction

" Add ssh:// to given string
function! s:PrependProtocol(string)
  if stridx(a:string, 'ssh://') == -1
    return 'ssh://' . a:string
  endif
  return a:string
endfunction

" Find local path of current file and remote path for current project
function! s:FindPaths(env)
  let local_path = '/' . expand(@%)
  let remote_path = s:PrependProtocol(get(s:CurrentMirrors(), a:env))
  return [remote_path, local_path]
endfunction

" Open file via ssh for given env
function! s:OpenFile(env, command)
  let [remote_path, local_path] = s:FindPaths(a:env)
  let full_path = remote_path . local_path
  execute ':' . a:command full_path
endfunction

" Find buffer that starts with 'ssh://' and delete it
function! mirror#CloseRemoteBuffer()
  execute ':bdelete' bufnr('^ssh://')
endfunction

" Open diff with remote file for given env
function! s:OpenDiff(env, command)
  call s:OpenFile(a:env, a:command)
  windo diffthis
endfunction

" Open directory via ssh for given env
function! s:OpenDir(env, command)
  let [remote_path, _] = s:FindPaths(a:env)
  " TODO check g:mirror#open_with existence
  execute ':' . a:command remote_path
endfunction

" Overwrite remote file with currently opened file
function! s:PushFile(env)
  let local_file = fnamemodify(expand(@%), ':p')
  let local_dir = fnamemodify(expand(@%), ':h')
  let remote_path = s:PrependProtocol(get(s:CurrentMirrors(), a:env))
  let remote_path .= '/' . local_dir
  let [port, dest_dir] = unite#sources#ssh#parse_action_path(remote_path)

  " scp -P PORT -q local_file remote_file
  if unite#kinds#file_ssh#external('copy_file', port, dest_dir, [local_file])
    echo unite#util#get_last_errmsg()
  else
    echo 'Pushed to' join(s:FindPaths(a:env), '')
  endif
endfunction

" Overwrite local file by remote_file
function! s:PullFile(env)
  let [remote_path, local_path] = s:FindPaths(a:env)
  let full_path = remote_path . local_path
  let [port, remote_file] = unite#sources#ssh#parse_action_path(full_path)
  let local_file = fnamemodify(expand(@%), ':p')

  " scp -P PORT -q remote_file local_file
  if unite#kinds#file_ssh#external('copy_file', port, local_file,
        \[remote_file])
    echo unite#util#get_last_errmsg()
  else
    " reopen file
    edit!
    echo 'Pulled from' full_path
  endif
endfunction

" Do remote action of given type
function! mirror#Do(env, type, command)
  let env = s:ChooseEnv(a:env)
  if !empty(env)
    if a:type ==# 'file'
      call s:OpenFile(env, a:command)
    elseif a:type ==# 'dir'
      call s:OpenDir(env, a:command)
    elseif a:type ==# 'diff'
      call s:OpenDiff(env, a:command)
    elseif a:type ==# 'push'
      call s:PushFile(env)
    elseif a:type ==# 'pull'
      call s:PullFile(env)
    endif
  endif
endfunction

" Open mirrors config in split
function! mirror#EditConfig()
  execute ':botright split' g:mirror#config_path
endfunction

" Set default environment for current session or globally
function! mirror#SetDefaultEnv(env, global)
  let env = s:ChooseEnv(a:env)
  if !empty(env)
    let g:mirror#local_default_environments[b:project_with_mirror] = env
    if a:global
      let g:mirror#global_default_environments[b:project_with_mirror] = env
      call s:UpdateCache()
    endif
    let remote_path = get(s:CurrentMirrors(), env)
    echo b:project_with_mirror . ':' env '(' . remote_path . ')'
  endif
endfunction

" Return dictionary from current project config
function! s:CurrentMirrors()
  return get(g:mirror#config, b:project_with_mirror, {})
endfunction

" Check selected environment for existence and return it
function! s:ChooseEnv(env)
  let default_env = s:FindDefaultEnv()
  if empty(s:CurrentMirrors())
    echo 'Project' '"' . b:project_with_mirror . '"'
          \ 'doesn''t have any environments'
          \ '(' . g:mirror#config_path . ')'
  elseif empty(a:env) && empty(default_env)
    echo 'Can''t find default environment for'
          \'"' . b:project_with_mirror . '"...'
  " env is not given - using default env for current project
  elseif empty(a:env) && !empty(default_env)
    return default_env
  elseif !empty(a:env)
    if has_key(s:CurrentMirrors(), a:env)
      return a:env
    else
      echo 'Environment with name' '"' . a:env . '"'
            \ 'not found in project' '"' . b:project_with_mirror . '"'
            \ '(' . g:mirror#config_path . ')'
    endif
  endif
endfunction

" Find default environment for current project
function! s:FindDefaultEnv()
  let default = ''
  if !empty(s:CurrentMirrors())
    " look for local defaults environments
    let default = get(g:mirror#local_default_environments, b:project_with_mirror, '')
    if empty(default)
      " look for global defaults environments
      let default = get(g:mirror#global_default_environments, b:project_with_mirror, '')
    endif
    if empty(default) && len(keys(s:CurrentMirrors())) ==# 1
      " if project contain only 1 environment - use it as default
      let default = keys(s:CurrentMirrors())[0]
    endif
  endif
  return default
endfunction

" Return list of available environments for current projects
function! s:EnvCompletion(...)
  return keys(s:CurrentMirrors())
endfunction

" Add Mirror* commands for current buffer
function! mirror#InitForBuffer(current_project)
  let b:project_with_mirror = a:current_project
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorEdit
        \ call mirror#Do(<q-args>, 'file', 'edit')
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorVEdit
        \ call mirror#Do(<q-args>, 'file', 'vsplit')
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorSEdit
        \ call mirror#Do(<q-args>, 'file', 'split')

  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorOpen
        \ call mirror#Do(<q-args>, 'dir', g:mirror#open_with)

  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorDiff
        \ call mirror#Do(<q-args>, 'diff', g:mirror#diff_layout)
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorVDiff
        \ call mirror#Do(<q-args>, 'diff', 'vsplit')
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorSDiff
        \ call mirror#Do(<q-args>, 'diff', 'split')

  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorPush
        \ call mirror#Do(<q-args>, 'push', '')
  command! -buffer -complete=customlist,s:EnvCompletion -nargs=? MirrorPull
        \ call mirror#Do(<q-args>, 'pull', '')

  command! -buffer -bang -complete=customlist,s:EnvCompletion -nargs=?
        \ MirrorEnvironment call mirror#SetDefaultEnv(<q-args>, <bang>0)
endfunction

" vim: foldmethod=marker
