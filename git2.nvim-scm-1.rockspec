local git_ref = '$git_ref'
local modrev = '$modrev'
local specrev = '$specrev'

local repo_url = '$repo_url'

rockspec_format = '3.0'
package = '$package'
if modrev:sub(1, 1) == '$' then
  modrev = "scm"
  specrev = "1"
  repo_url = "https://github.com/Freed-Wu/git2.nvim"
  package = repo_url:match("/([^/]+)/?$")
end
version = modrev .. '-' .. specrev

description = {
  summary = '$summary',
  detailed = '',
  labels = { "neovim", "git2" },
  homepage = '$homepage',
  license = 'GPL3',
}

dependencies = { 'lua >= 5.1', 'mega.argparse', 'vim', 'lua-git2-tmp' }

test_dependencies = {}

source = {
  url = repo_url .. '/archive/' .. git_ref .. '.zip',
  dir = '$repo_name-' .. '$archive_dir_suffix',
}

if modrev == 'scm' or modrev == 'dev' then
  source = {
    url = repo_url:gsub('https', 'git')
  }
end

build = {
  type = 'builtin',
  copy_directories = { 'scripts', 'plugin' },
  install = {
    bin = {
      git2 = 'bin/git2',
    },
    conf = {
      ['..'] = 'shell.nix',
    },
  },
}
