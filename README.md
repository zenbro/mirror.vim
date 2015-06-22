# mirror.vim

If some of your projects have multiple environments (e.g. development, staging, production - with nearly the same directory and files structure), then there is a situations when you need to connect to one of this environments via ssh and remotely edit project-related files. Usually you will do something like this:

```bash
ssh user@host
cd path/to/you/project
vim /some/file
and so on...
```

This plugin was created to simplify this process by maintaining special config file (*mirrors*) and adding different commands for quickly doing remote actions for each environment of project you working with. This remote actions use [netrw](http://www.vim.org/scripts/script.php?script_id=1075) under the hood. You don't need to install netrw - it's part of vim distribution and it used as default file explorer (e.g. `:edit .`).

## Installation

Use your favourite plugin manager.

### Pathogen

Run the following in a terminal:

```bash
cd ~/.vim/bundle
git clone https://github.com/zenbro/mirror.vim
```

### Vundle

Place this in your *.vimrc*:

`Plugin 'zenbro/mirror.vim'`

then run the following in Vim:

```
:source %
:PluginInstall
```

### VimPlug

Place this in your *.vimrc*:

`Plug 'zenbro/mirror.vim'`

then run the following in Vim:

```
:source %
:PlugInstall
```

### NeoBundle

Place this in your *.vimrc*:

`NeoBundle 'zenbro/mirror.vim'`

then run the following in Vim:

```
:source %
:NeoBundleInstall
```

## Usage

First, you need to add information about your project to *mirrors* config. Open Vim and run this command:  `:MirrorConfig`

Example of *mirrors* config:

```yaml
project1:
  staging: project1@staging_host/current
  production: project1@production_host/current
project2:
  staging: project2@staging_host/path/to/project2
```

This configuration use simplified [YAML](https://en.wikipedia.org/wiki/YAML) format.

* *project1*, *project2* - names of working directories for each project (e.g. *~/work/project1*, *~/work/project2*)
* *staging*, *production* - names of environments for each projects. You can use whatever name you want when adding environments.
* *project1@staging_host/current* - remote path for your project. It should be available by doing these commands:

```
ssh project1@staging_host
cd current
```

If your currently working directory is in the config file (e.g. *~/work/project1*), then you should be able to do environment-specific remote actions.

All these actions have following syntax: `:CommandName <environment>` (e.g. `:MirrorEdit staging`). When your project have only one environment, then it will be used automatically for all commands as default - you don't need to pass it. When your project have multiply environments - you need to pass it explicitly.

You can manually choose default environment for current project by this command:

* `:MirrorEnvironment <environment>` - set default `<environment>` for current session.
* `:MirrorEnvironment! <environment>` - set default `<environment>` globally.
* `:MirrorEnvironment` - show default environment for this project.

Available commands:

* `:MirrorEdit` - open remote version of a file you are currently editing.
  * `:MirrorSEdit` - open in horizontal split
  * `:MirrorVEdit` - open in vertical split
* `:MirrorDiff` - open vertical split (layout can be configured by `g:mirror#diff_layout`) with difference between remote and local file.
  * `:MirrorSDiff` - open diff in horizontal split
  * `:MirrorVEdit` - open diff in vertical split
* `:MirrorPush` - overwrite remote version of file by local version you currently working with.
* `:MirrorPull` - overwrite local version of file by remote version.
* `:MirrorOpen` - open remote project directory in file explorer (netrw).
* `:MirrorRoot` - open remote system root path in file explorer.
* `:MirrorParentDir` - open remote parent directory of file you currently working with.


## Configuration

This is all available options with their defaults:

```vim
let g:mirror#config_path = '~/.mirrors'
let g:mirror#open_with = 'Explore'
let g:mirror#diff_layout = 'vsplit'
let g:mirror#cache_dir = '~/.cache/mirror.vim'
```

* `g:mirror#config_path` - where to store mirrors config.
* `g:mirror#open_with` - file explorer command that used in `:MirrorOpen`, `:MirrorRoot`, `:MirrorParentDir`. If you want to open file explorer in horizontal split - use `'Sexplore'` (`:h netrw-explore`).
* `g:mirror#diff_layout` - default split layout for `:MirrorDiff` command.
* `g:mirror#cache_dir` - directory where cache is stored. Currently used for saving default environments, that set via `:MirrorEnvironment! <env>`.

## FAQ

**Q. Why should I always enter password when executing one of the remote actions?**

A. Use [SSH config](http://nerderati.com/2011/03/17/simplify-your-life-with-an-ssh-config-file/) or passwordless authentication with [SSH-keys](https://wiki.archlinux.org/index.php/SSH_keys).

**Q. I change directory to my project root in Vim (`:cd ~/work/project`), but`Mirror*` commands still unavailable. How can I fix that?**

A. This plugin will try to find project root when you opening some file. When you manually change current working directory by `:cd`, then use `:MirrorDetect`. This command will try to find you current directory in *mirrors* config.

## License

MIT
