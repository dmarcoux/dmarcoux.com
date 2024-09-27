+++
title = "Reproducible Development Environment for Elixir with Nix"
description = """\
                Did someone ever tell you "But it works on my computer!", \
                while it doesn't on yours? Rely on Nix for your development \
                environments to avoid this altogether!\
              """
date = "2022-11-09"

[extra.meta]
type = "article"
keywords = "Nix, Elixir, development environment, reproducible, nix-shell, NixOS"
+++

Recently, I started learning about *Elixir* and at first, I was somewhat unsure
about how to setup my development environment. After reading the various
recommendations from the *Elixir* community, my questions remained. This is when
I asked on *Twitter* to gather more thoughts on the matter. It led me to
research further how I could setup a reproducible development environment for
Elixir. I will share with you how I achieved this with *Nix*.

## What Is *Nix*?

Did a colleague or a friend ever tell you *"But it works on my computer!"* ?
No...? Well consider yourself lucky then! For the unlucky ones, you know how
this sucks... you simply want to run some application on your computer and it
doesn't work. It's perhaps a missing undocumented dependency or some dependency
version mismatch.

You don't have to go through this. Do not rely on system packages, this is
asking for trouble. Leave your runtime versions manager like *asdf* behind. They
aren't much better. Those approaches aren't reliable and reproducible. This is
where *Nix* comes in. It's a purely functional and cross-platform package manager.
It can be [installed](https://nixos.org/download.html) in various ways, this
will depend on your operating system.

Once you have *Nix* on your computer, you can create reproducible development
environment with *nix-shell*.

## The *nix-shell* Command

One of the commands provided by *Nix* is `nix-shell`.

Whenever executing `nix-shell --pure` in your terminal, the command looks for
the file *shell.nix* in the current working directory. This file contains *Nix*
code to create a shell or if you prefer, your development environment. As for
the `--pure` flag, it ensures your system configuration and its packages do not
interfere with the shell you created just now. Everything else stays the same in
this shell, you can freely navigate your filesystem, run a *Phoenix* application
or start *IEx*, the world is yours!

## Show Me the Money

Let's have a look at a real-world *shell.nix* example. The comments will walk
you through what happens. You can horizontally scroll in the code block below if
it's not fully visible on your device.

<!-- markdownlint-disable -->
```nix
# To ensure this nix-shell is reproducible, we pin the packages index
# to a commit SHA taken from a channel on https://status.nixos.org/.
# This commit is from the nixos-22.05 channel, the current stable channel.
with (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/8de8b98839d1.tar.gz) {});

let
  # Set the version of Erlang/OTP you want to use, this is Erlang/OTP 25.
  # `erlang` is a variable referring to a Nix package
  erlang = beam.packages.erlangR25;
in
  mkShell {
    # Install Nix packages you want to use in your development environment
    buildInputs = [
      # Elixir with Erlang/OTP specified in the `erlang` variable defined above.
      # Relying on the package `elixir` alone isn't enough, as the version
      # of Erlang cannot be specified.
      erlang.elixir_1_14
      # The package manager for Erlang
      erlang.hex
      # The build tool for Erlang.
      # If changing this package, do not forget to replicate the change
      # below in `shellHook`.
      erlang.rebar3
      # For the Live Reloading feature in Phoenix
      inotify-tools
      # Locales
      glibcLocales
    ];

    # Prepare your development environment here
    shellHook = ''
      # Set LANG for locales
      # Otherwise it is unset when running "nix-shell --pure"
      export LANG="C.UTF-8"

      # Keep Mix and Hex data in the project
      # Be sure to ignore those directories in your `.gitignore`
      export MIX_HOME="$PWD/.nix-mix"
      export HEX_HOME="$PWD/.nix-hex"
      mkdir -p "$MIX_HOME" "$HEX_HOME"
      # Put executables from Mix and Hex directories in $PATH
      export PATH="$MIX_HOME/bin:$MIX_HOME/escripts:$HEX_HOME/bin:$PATH"

      # Set development environment for Mix
      export MIX_ENV=dev

      # Persist history of the IEx (Elixir) and erl (Erlang) shells
      export ERL_AFLAGS="-kernel shell_history enabled"

      # Set the path to the rebar3 package from Nix
      mix local.rebar --if-missing rebar3 ${erlang.rebar3}/bin/rebar3
    '';

    # Without this, there are warnings about LANG, LC_ALL and locales.
    # Many tests fail due those warnings showing up in test outputs too...
    # This is from https://gist.github.com/aabs/fba5cd1a8038fb84a46909250d34a5c1
    LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
  }
```
<!-- markdownlint-enable -->

Give this *nix-shell* a try by copying it in one of your *Elixir* projects, then
running `nix-shell --pure`. Adapt it to your needs, perhaps you want to change
the *Elixir* or *Erlang* version. There is a **lot** of information on the *Nix*
packages available for *Elixir* and *Erlang* on
[*GitHub*](https://github.com/NixOS/nixpkgs/blob/f26896669bc5a92d879f7d34c9458e8c44635ab5/doc/languages-frameworks/beam.section.md).
Regarding other *Nix* packages, you can find them with the [*Nix* Search](https://search.nixos.org/packages).

## Will You Reproduce This?

Give it a try!
