" Author: liuchengxu <xuliuchengxlc@gmail.com>
" Description: List the marks.

let s:save_cpo = &cpo
set cpo&vim

let s:marks = {}

function! s:format_mark(line)
  return substitute(a:line, '\S', '\=submatch(0)', '')
endfunction

function! s:marks.source() abort
  call g:clap.start.goto_win()
  redir => cout
  silent marks
  redir END
  call g:clap.input.goto_win()
  let list = split(cout, "\n")
  return extend(list[0:0], map(list[1:], 's:format_mark(v:val)'))
endfunction

function! s:marks.sink(line) abort
  execute 'normal! `'.matchstr(a:line, '\S').'zz'
endfunction

function! s:matchaddpos(lnum) abort
  if exists('w:clap_mark_hi_id')
    call matchdelete(w:clap_mark_hi_id)
  endif
  let w:clap_mark_hi_id = matchaddpos('Search', [[a:lnum]])
endfunction

if has('nvim')
  function! s:execute_matchaddpos(lnum) abort
    noautocmd call win_gotoid(g:clap.preview.winid)
    call s:matchaddpos(a:lnum)
    noautocmd call win_gotoid(g:clap.input.winid)
  endfunction

  function! s:render_syntax(ft) abort
    call g:clap.preview.setbufvar('&ft', a:ft)
  endfunction
else
  function! s:execute_matchaddpos(lnum) abort
    call win_execute(g:clap.preview.winid, 'noautocmd call s:matchaddpos(a:lnum)')
  endfunction

  function! s:render_syntax(ft) abort
    " vim using noautocmd in win_execute, hence we have to load the syntax file manually.
    call win_execute(g:clap.preview.winid, 'runtime syntax/'.a:ft.'.vim')
  endfunction
endif

function! clap#provider#marks#common_impl(line, col, file_text) abort
  let line = a:line
  let col = a:col
  let file_text = a:file_text

  if line - 5 > 0
    let start = line - 5
    let hi_lnum = 5+1
  else
    let start = 1
    let hi_lnum = line
  endif

  let should_add_hi = v:true

  let origin_line = getbufline(g:clap.start.bufnr, line)
  " file_text is the origin line with leading white spaces trimmed.
  if !empty(origin_line)
        \ && clap#util#trim_leading(origin_line[0]) == file_text
    let lines = getbufline(g:clap.start.bufnr, start, line + 5)
    let origin_bufnr = g:clap.start.bufnr
  else
    let bufnr = clap#util#try_load_file(file_text)
    if bufnr isnot v:null
      " FIXME lines is empty at times.
      let lines = getbufline(bufnr, start, line + 5)
      let origin_bufnr = bufnr
    else
      let lines = [file_text]
      let should_add_hi = v:false
    endif
  endif

  call g:clap.preview.show(lines)

  if should_add_hi
    if exists('l:origin_bufnr')
      let ft = getbufvar(l:origin_bufnr, '&filetype')
      if empty(ft)
        let ft = fnamemodify(expand(bufname(origin_bufnr)), ':e')
      endif
      if !empty(ft)
        call s:render_syntax(ft)
      endif
    endif
    call s:execute_matchaddpos(hi_lnum)
  endif
endfunction

function! s:marks.on_move() abort
  let curline = g:clap.display.getcurline()

  if 'mark line  col file/text' == curline
    return
  endif

  let matched = matchlist(curline, '^.*\([a-zA-Z0-9[`''"\^\]\.]\)\s\+\(\d\+\)\s\+\(\d\+\)\s\+\(.*\)$')

  if len(matched) < 5
    return
  endif

  let line = matched[2]
  let col = matched[3]
  let file_text = matched[4]
  call clap#provider#marks#common_impl(line, col, file_text)
endfunction

let s:marks.on_enter = { -> g:clap.display.setbufvar('&ft', 'clap_marks') }

let g:clap#provider#marks# = s:marks

let &cpo = s:save_cpo
unlet s:save_cpo
