# mirror.vim [![GitHub release](https://img.shields.io/github/release/zenbro/mirror.vim.svg)](https://github.com/zenbro/mirror.vim/releases) [![GitHub issues](https://img.shields.io/github/issues/zenbro/mirror.vim.svg)](https://github.com/zenbro/mirror.vim/issues)

* [Live demo](#live-demo)
* [Introduction](#introduction)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Commands](#commands)
* [Variables](#variables)
* [FAQ](#faq)
* [License](#license)

## Live demo

[![asciicast](https://asciinema.org/a/22407.png)](https://asciinema.org/a/22407)

## Introduction

If some of your projects have multiple environments (e.g. development, staging,
production - with nearly the same directory and files structure), then there is
a situations when you need to connect to one of this environments via ssh and
remotely edit project-related files. Usually you will do something like this:

```bash
ssh user@host
cd path/to/you/project
vim /some/file
and so on...
```

This plugin was created to simplify this process by maintaining special
configuration file and adding different commands for quickly doing remote
actions for each environment of project you working with. This remote actions
use [netrw](http://www.vim.org/scripts/script.php?script_id=1075) under the
hood. You don't need to install netrw - it's part of vim distribution and it
used as default file explorer (e.g. `:edit .`). To get more information about
editing remote files with netrw - refer to `:h netrw-start`.

## Requirements

* Vim with [netrw](http://www.vim.org/scripts/script.php?script_id=1075) support (any version greater than 7.0).
* Unix-based system with [scp](https://en.wikipedia.org/wiki/Secure_copy) and ssh client installed.

## Installation

Use your favourite plugin manager: [Pathogen](https://github.com/tpope/vim-pathogen), [Vundle](https://github.com/gmarik/Vundle.vim), [NeoBundle](https://github.com/Shougo/neobundle.vim) or [VimPlug](https://github.com/junegunn/vim-plug). Add `zenbro/mirror.vim` to the list of plugins, source that and issue your manager's install command.

Add this lines to *.vimrc* (probably they already there):

```vim
set nocompatible    " disable backward compatibility with Vi
filetype plugin on  " plugins are enabled
```


## Usage

Let's assume that you have a project */home/user/work/my_project*.
This project have multiple environments - development, staging and production.
Development - is your current local environment. Staging and production -
remote environments, each placed on their own remote server. Project structure
on each environments is nearly similar (from here comes the name of this
plugin). If you want to get access to multiple environment-related remote
actions, you need to add information about this project to configuration file.
Run this command `:MirrorConfig` and edit configuration file.

For our example it should look like this:

```yaml
/home/user/work/my_project:
  staging: my_project@staging_host/current
  production: my_project@production_host/current
```
See [Configuration](#configuration) for more details about format and structure of this file.

From now, if you open any file inside */home/user/work/my_project* then
multiple remote commands should be available.
For example, if you want to edit some file on remote server in staging
environment (*my_project@staging_host*), then open this file locally and run
`:MirrorEdit staging`. You should be able to edit this remote file here,
locally, with your own vim settings. If you want to see difference between
file, you currently edit and version of this file on production server - use
this command: `:MirrorDiff production`.

There are many other [remote actions](#remote-actions) available.

## Configuration

Default path of configuration file is *~/.mirrors*.
Use `g:mirror#config_path` if you want to change location of configuration
file. To open configuration file use `:MirrorConfig` command. Use `q` to close it.

Configuration file use simplified [YAML](https://en.wikipedia.org/wiki/YAML)
format and doesn't support things like &links, arrays, inline objects.

Example of mirrors config:

```yaml
/home/user/work/project1:
  staging: project1@staging_host/current
  production: project1@production_host/current
/home/user/work/project2:
  staging: project2@another_host:23//opt/project2
```

* */home/user/work/project1*, */home/user/work/project2* - names of working directories for each project. See also [Project discovery](#project-discovery).
* *staging*, *production* - names of environments for each projects. You can use whatever name you want when adding environments.
* *project1@staging_host/current* - remote path for environment "*staging*" of project "*project1*". Path "*current*" is related to home directory of user "*project1*" on host "*staging_host*".
It should be available by doing these commands:

```bash
ssh project1@staging_host
cd current
```

* *project2@another_host:23//opt/project2* - remote path for environment "*staging*" of project "*project2*". Path "*/opt/project2*" is related to system root directory on host "*another_host*".
It should be available by doing these commands:

```bash
ssh -p 23 project2@another_host
cd /opt/project2
```

If you open any file inside your projects directories, then you should be able
to do environment-specific remote actions.

## Commands

### Global

This command is available everywhere.

 * `:MirrorConfig` - open configuration file in split. Use `q` to close it.  
 Configuration file path can be changed by `g:mirror#config_path`.

### Local

Local commands are only available when you open a file inside one of the
projects from configuration.

#### Project discovery

When you open a file and absolute path of this file containing one of the path
from configuration then project discovery succeeded and local commands will be
available for current buffer.

In summary, project discovery will be done after following actions:

 * `BufNewFile` 
 * `BufReadPost` 
 * `BufWritePost g:mirror#config_path` (saving configuration file)

#### Default environment

When your project have only one environment, then it will be used automatically
for all local commands as default - you don't need to pass it as argument. When
  your project have multiply environments - you need to pass it explicitly.

To change default environment for current project use one of the following commands.

 * `:MirrorEnvironment` - show default environment for current project.
 * `:MirrorEnvironment <environment>` - set default `<environment>` for current session.
 * `:MirrorEnvironment! <environment>` - set default `<environment>` globally.  
 Path, where default environments is saved can be changed by `g:mirror#cache_dir`.

#### Remote actions

Local file - file you are currently editing.  
Remote file - version of local file on remote server.

* `:MirrorEdit <environment>` - open remote version of a local file.
  * `:MirrorSEdit <environment>` - open remote version of a local file in horizontal split.
  * `:MirrorVEdit <environment>` - open remote version of a local file in vertical split.
* `:MirrorDiff <environment>` - open vertical split with difference between remote and local file. Use `:diffoff` to exit diff mode.  Use `g:mirror#diff_layout` to change default split layout for this command.
  * `:MirrorSDiff <environment>` - open horizontal split with difference between remote and local file.
  * `:MirrorVEdit <environment>` - open vertical split with difference between remote and local file.
* `:MirrorPush <environment>` - overwrite remote file by local file.
* `:MirrorPull <environment>` - overwrite local file by remote file.
* `:MirrorOpen <environment>` - open remote project directory in file explorer (netrw).
* `:MirrorRoot <environment>` - open remote system root directory in file explorer.
* `:MirrorParentDir <environment>` - open remote parent directory of local file.
* `:MirrorSSH <environment>` - establish ssh connection with selected `<environment>`.
* `:MirrorInfo <environment>` - get information about remote file.


## Variables

This is all available options with their defaults:

```vim
let g:mirror#config_path = '~/.mirrors'
let g:mirror#open_with = 'Explore'
let g:mirror#diff_layout = 'vsplit'
let g:mirror#cache_dir = '~/.cache/mirror.vim'
let g:netrw_silent = 1
```

* `g:mirror#config_path` - location of configuration file.
* `g:mirror#open_with` - file explorer command that used in `:MirrorOpen`, `:MirrorRoot`, `:MirrorParentDir`. If you want to open file explorer in horizontal split - you can use `'Sexplore'`. See also `:h netrw-explore`.
* `g:mirror#diff_layout` - split layout for `:MirrorDiff` command.
* `g:mirror#cache_dir` - directory where cache is stored. Currently used for saving default environments, that set via `:MirrorEnvironment! <environment>`.
* `g:netrw_silent` - this variable is related to netrw configuration.  
Possible values:
  * 0 - transfers done normally (you should see what's going on under the hood when using `:MirrorEdit` or `:MirrorDiff` commands)
  * 1 - transfers done silently  
Silent mode will be used by default.

## FAQ

**Q. Why should I always enter password when executing one of the remote actions?**

A. Use [SSH config](http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file/)
or passwordless authentication with [SSH-keys](https://wiki.archlinux.org/index.php/SSH_keys).

## License

mirror.vim is released under the [MIT License](http://opensource.org/licenses/MIT).
