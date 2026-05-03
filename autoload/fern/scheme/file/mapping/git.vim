function! fern#scheme#file#mapping#git#stage(...) abort
  call fern#mapping#call(function('fern#scheme#file#mapping#git#main', [v:true]))
endfunction

function! fern#scheme#file#mapping#git#unstage(...) abort
  call fern#mapping#call(function('fern#scheme#file#mapping#git#main', [v:false]))
endfunction

function! fern#scheme#file#mapping#git#main(stage, helper) abort
  if a:helper.sync.get_scheme() !=# 'file'
    throw printf("git action requires 'file' scheme")
  endif
  let root = a:helper.sync.get_root_node()
  let nodes = a:helper.sync.get_selected_nodes()
  let nodes = empty(nodes) ? [a:helper.sync.get_cursor_node()] : nodes
  let paths = map(copy(nodes), { -> v:val._path })

  if a:stage
    call v:lua.require('git2.reset').stage(root._path, paths)
  else
    call v:lua.require('git2.reset').unstage(root._path, paths)
  endif
  call a:helper.async.update_marks([])
  call a:helper.async.redraw()
endfunction
