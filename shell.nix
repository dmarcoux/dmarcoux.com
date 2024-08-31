# To ensure this nix-shell is reproducible, we pin the packages index to a commit SHA taken from a channel on https://status.nixos.org/
# This commit is from nixos-unstable, somewhere between NixOS 22.05 and the next version
with (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/667e5581d16745bcda791300ae7e2d73f49fff25.tar.gz) {});

mkShell {
  buildInputs = [
    # Fast and flexible static site generator
    hugo
    # Locales
    glibcLocales
    # Install linters for Markdown files with NPM
    nodejs
  ];

  shellHook = ''
    # Set LANG for locales, otherwise it is unset when running "nix-shell --pure"
    export LANG="C.UTF-8"

    # Remove duplicate commands from Bash shell command history
    export HISTCONTROL=ignoreboth:erasedups

    # Install NPM packages inside the project
    export NPM_CONFIG_PREFIX="$PWD/.npm-packages"

    # Put executables from NPM packages in $PATH
    export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

    # Install Markdown linter if it's not already installed
    #
    # To update this linter:
    # - Remove the installed NPM packages with `rm -r $NPM_CONFIG_PREFIX`
    # - Update the pinned version
    # - Restart this nix-shell
    command -v markdownlint-cli2 1> /dev/null || npm install markdownlint-cli2@0.5.1 --global

    # Create alias to lint Markdown files
    alias lint="markdownlint-cli2 '**/*.md' '#themes' '#node_modules' '#$NPM_CONFIG_PREFIX'"

    # TODO: This would be nice once configuration by file is available for Cloudflare Pages
    # Ensure `HUGO_VERSION` in `netlify.toml` matches the installed version of Hugo. This is a safeguard, since it's too easy to forget doing this...
    # hugo version | sed -e "s|hugo v\(.*\)+extended .*|\1|g" | xargs -I % sh -c "sed --in-place -e 's|HUGO_VERSION = .*|HUGO_VERSION = \"%\"|g' netlify.toml"
  '';

  # Without this, there are warnings about LANG, LC_ALL and locales.
  # This solution is from: https://gist.github.com/aabs/fba5cd1a8038fb84a46909250d34a5c1
  LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
}
