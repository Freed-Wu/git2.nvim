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

dependencies = { 'lua >= 5.1', 'mega.argparse', 'vim', 'luabitop', 'yaml', 'lua-git2-temp' }
build = {
  type = 'builtin',
  copy_directories = { 'scripts', 'plugin', 'autoload' },
  install = {
    bin = {
      git2 = 'bin/git2',
    },
    conf = {
      ['..'] = 'shell.nix',
    },
  },
}
