# 1password-env

Store Environment Variables in your 1Password secrets and retrieve them on-demand for use in temporary shells. Good for using AWS credentials from your terminal without having to store them on disk.

## Installation

```sh
brew tap jagregory/tools
brew install 1password-env
```

The `1password-cli` is required. You can install it with Homebrew Cask: `brew cask install
1password-cli`

## Setting up your secrets

Before you can use `op-env` you need to set up your secrets. In your 1Password vault, create or edit a secret and add a new section called "env". Any fields you add in this "env" section will be exported as Environment Variables in your Terminal when you use `op-env`.

![](./docs/example-1password-env-section.png)

## Usage

`op-env` takes one argument: the name of a 1Password secret.

```sh
$ op-env my-secret
```

When you run `op-env` it will try to read the secret from your 1Password vault. If you haven't used `op-env` before (or for a while) you will need to supply your Vault credentials. `op-env` will re-use your 1Password session for as long as it can, but eventually it will be locked out and you'll need to re-authenticate.

After unlocking your vault and locating the secret, `op-env` will launch a new sub-shell (using your `$SHELL`) which has the variables from your secret exported. The variables are not available anywhere outside of this sub-shell.

```
🔒 Temporary shell for my-secret 🔒

~/dev $ echo $A_SECRET
this is in 1Password
```

## How it works

`op-env` uses the 1Password CLI for most of the heavy lifting. The procedure `op-env` runs through
when it launches a shell is as follows:

  1. Try to restore a previously used `op-env` session by reading and exporting the contents of `~/.1password-env/session` and `~/.1password-env/defaults`
  2. Check to see if there's an active 1Password CLI session. Call `op get account` which will
     return successfully if there's an active session
  3. If no active session, prompt the user for their preferred Vault, Email Address, and the Secret
     Key for the vault. Sign in to the 1Password CLI with these values: `op signin <vault> <email> <secretkey>`. Store the resulting session token in `~/.1password-env/session`, and the Vault and Email in `~/.1password-env/defaults`
  4. Retrieve the requested secret from 1Password with `op get item <secret>`, perform some jq JSON
     manipulation to turn the "env" section into key-value environment variable pairs.
  5. Launch a new shell using `env $vars $SHELL`

## Security notes

The intention of this tool is to reduce the exposure of your environment variables by making them
short lived and not permanently persistent on disk. It is not intended to protect you from active
snooping.

### Environment Variable leaking

`op-env` creates a subshell with `env` for injecting variables. The injected variables are only
visible inside the subshell, once the shell is closed they are gone. There are a couple of
exceptions to this (and hence the above caveat about snooping):

  1. The `root` user of your system and the user who executed `op-env` can call `ps` and inspect the
     environment variables of the processes they launched (or all if you're `root`)
  2. The `root` user can inspect `/proc/$pid/environ` and list the environment variables of a running process.

In both these cases, the environment variables of the sub-shell created by `op-env` will include the
dynamically created variables from your 1Password secret.

On modern operating systems, only your own user and `root` have these privileges, and therefore this
is a low risk.

### ~/.1password-env

`op-env` will try to reuse the 1Password session it used previously, so it can try to avoid making
you enter your Secret Key too frequently. To reuse a session, `op-env` persists the 1Password
session token and reads it on next run.

The following files are created:

  1. `~/.1password-env/session` which contains your `OP_SESSION_<vault>` token
  2. `~/.1password-env/defaults` which contains the Vault name and the Email Address for the vault
     you last accessed

The files in `~/.password-env` are readable only the user who executed `op-env`. The token is valid
for roughly 30 minutes after last use. The Vault name and Email address are useless without your
Secret Key (which isn't persisted anywhere).

You may store `~/.1password-env/defaults` in a dotfiles repository. Storing
`~/.1password-env/session` is unnecessary.
