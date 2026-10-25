rockspec_format = '3.0'
description = {
  summary = '',
  detailed = '',
  labels = {},
  homepage = 'https://github.com/Freed-Wu/git2.nvim',
  license = 'GPL-3.0',
}
package = description.homepage:match('/([^/]+)/?$')
version = 'scm-1'
source = {
  url = description.homepage:gsub('https', 'git')
}
build = {
  type = 'builtin',
  copy_directories = { 'plugin', 'autoload' },
}

dependencies = { 'lua >= 5.1', 'mega.argparse', 'vim', 'luabitop', 'yaml', 'lua-git2-temp' }
