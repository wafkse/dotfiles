# Dotfiles

This is a repository containing the configuration for my personal Linux machines.

# Installation

To install these sets of *dotfiles*, the `stow` and `mirage` utilities must be installed.

For the desktop, the following must be installed:

* `niri`
* `waybar`
* `pwvucontrol`
* `bluetui`
* `nmtui`
* `ghostty`

*NOTE*: This list is not exhaustive, and some applications may not have been mentioned.

## Installation Process

First, clone the repository to `~/.dotfiles` (or any directory where the dotfiles shall reside, change the path accordingly), and execute:

```bash
$ DOTFILES_PATH="$HOME/.dotfiles"
$ cd $DOTFILES_PATH
$ stow static
$ # Once you've stow'd your static files, you must enable and start the Mirage daemon.
$ systemctl --user enable --now "mirage@$(systemd-escape "$DOTFILES_PATH").service"
$ # Now, enable all provided user services.
```

For provided systemd units, take a look at the [.config/systemd/user](dist/static/.config/systemd/user) directory.

### Potential Failure

If your home directory has been already populated, `stow` will complain about already-existent symbolic link targets.

To remediate this, you need to execute `stow` with the `--adopt` parameter, and reset the `~/.dotfiles` repository to the latest commit: `git restore $PWD`. 
This will keep the symbolic links active, but **will trash** any existing file that `stow` was unable to make a symbolic link to. 

### Finishing Up

Enable all user non-template `systemd` units provided.

Afterwards, re-login to the user, the complete environment should start automatically.

## Mirage-managed

These dotfiles are managed by `mirage`, which allow dynamic system-wide theming of terminal- and compositor-based user sessions.

# License

**All** files under this repository are licensed under the [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) license.

A copy of the license can be found in the repository root: [LICENSE](./LICENSE).
