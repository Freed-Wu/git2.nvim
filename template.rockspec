local git_ref = '$git_ref'
local modrev = '$modrev'
local specrev = '$specrev'

local repo_url = '$repo_url'

rockspec_format = '3.0'
package = '$package'
version = modrev ..'-'.. specrev

description = {
  summary = '$summary',
  detailed = $detailed_description,
  labels = $labels,
  homepage = '$homepage',
  $license
}

dependencies = { 'lua >= 5.1', 'argparse', 'mega.cmdparse >= 1.2.1', 'lua-git2-tmp', 'luafilesystem', 'platformdirs' }

test_dependencies = $test_dependencies

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
  copy_directories = {'scripts', 'plugin'},
  install = {
    bin = {
      git2 = 'bin/git2',
    },
    conf = {
      ['..'] = 'shell.nix',
    },
  },
}
