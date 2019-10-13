" Author: liuchengxu <xuliuchengxlc@gmail.com>
" Description: List the files.

let s:save_cpo = &cpo
set cpo&vim

let s:files = {}

let s:find_exe = v:null

let s:tools = {
      \ 'fd': '--type f',
      \ 'rg': '--files',
      \ 'git': 'ls-tree -r --name-only HEAD',
      \ 'find': '. -type f',
      \ }

let s:find_exe = v:null

for [exe, opt] in ['fd', 'rg', 'git', 'find']
  if executable(exe)
    let s:find_exe = join([exe, opt], ' ')
    let s:find_cmd = join([s:find_exe, s:tools[s:find_exe]], ' ')
    break
  endif
endfor

if s:find_exe is v:null
  let s:find_cmd = ['No usable tools found for the files provider']
endif

function! s:files.source() abort
  if has_key(g:clap.context, 'hidden')
    if s:find_exe == 'fd' || s:find_exe == 'rg'
      return join([s:find_exe, '--hidden', s:tools[s:find_exe]], ' ')
    else
      return s:find_cmd
    endif
  endif
  return s:find_cmd
endfunction

let s:files.source = s:find_exe
let s:files.sink = 'e'

let g:clap#provider#files# = s:files

let &cpo = s:save_cpo
unlet s:save_cpo
