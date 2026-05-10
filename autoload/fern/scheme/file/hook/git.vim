function! fern#scheme#file#hook#git#init(...) abort
  if exists('s:ready')
    return
  endif
  let s:ready = 1
  let opts = [get(a:000, 0, v:true), get(a:000, 1, v:true), get(a:000, 2, v:true), get(a:000, 3, 'fern_git_status_processing')]
  call fern#hook#add('viewer:highlight', function('s:on_highlight'))
  call fern#hook#add('viewer:syntax', function('s:on_syntax'))
  call fern#hook#add('viewer:redraw', function('s:on_redraw', opts))
endfunction

function! s:on_highlight(...) abort
  highlight default link FernGitStatusBracket Comment
  highlight default link FernGitStatusIndex Special
  highlight default link FernGitStatusWorktree WarningMsg
  highlight default link FernGitStatusUnmerged ErrorMsg
  highlight default link FernGitStatusUntracked Comment
  highlight default link FernGitStatusIgnored Comment
endfunction

function! s:on_syntax(...) abort
  syntax match FernGitStatusBracket /.*/ contained containedin=FernBadge
  syntax match FernGitStatus /\[\zs..\ze\]/ contained containedin=FernGitStatusBracket
  syntax match FernGitStatusIndex     /./ contained containedin=FernGitStatus nextgroup=FernGitStatusWorktree
  syntax match FernGitStatusWorktree  /./ contained

  syntax match FernGitStatusUnmerged  /DD\|AU\|UD\|UA\|DU\|AA\|UU/ contained containedin=FernGitStatus

  syntax match FernGitStatusUntracked /??/ contained containedin=FernGitStatus
  syntax match FernGitStatusIgnored   /!!/ contained containedin=FernGitStatus
endfunction

function! s:on_redraw(include_directories, include_ignored, include_untracked, varname, helper) abort
  let bufnr = a:helper.bufnr
  let processing = getbufvar(bufnr, a:varname, 0)
  if a:helper.fern.scheme !=# 'file' || processing
    return
  endif
  let status_map = v:lua.require('git2.status').get_status_map(a:include_directories, a:include_ignored, a:include_untracked)
  for node in a:helper.fern.visible_nodes
    call s:update_node(status_map, node)
  endfor
  call s:redraw(a:helper, a:varname)
endfunction

function! s:update_node(status_map, node) abort
  let path = fern#internal#filepath#to_slash(a:node._path)
  let status = get(a:status_map, path, '')
  let a:node.badge = status ==# '' ? '' : printf(' [%s]', status)
  return a:node
endfunction

function! s:redraw(helper, varname) abort
  let bufnr = a:helper.bufnr
  call setbufvar(bufnr, a:varname, 1)
  return a:helper.async.redraw()
        \.then({ -> setbufvar(bufnr, a:varname, 0)})
endfunction
