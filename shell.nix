# To ensure this nix-shell is reproducible, we pin the packages index to a commit SHA taken from a channel on https://status.nixos.org/
# This commit is from nixos-unstable, somewhere between NixOS 24.05 and the next version
with (import (fetchTarball https://github.com/NixOS/nixpkgs/archive/12228ff1752d7b7624a54e9c1af4b222b3c1073b.tar.gz) {});

mkShell {
  buildInputs = [
    # Static site generator
    zola
    # Locales
    glibcLocales
    # Install linters for Markdown files with NPM
    nodejs
    # Bundle of SSL certificates
    cacert
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
    # - Update the pinned version here and in GitHub Actions workflow
    # - Restart this nix-shell
    command -v markdownlint-cli2 1> /dev/null || npm install markdownlint-cli2@0.14.0 --global

    # Create alias to lint Markdown files
    alias lint="markdownlint-cli2 '**/*.md' '#node_modules' '#$NPM_CONFIG_PREFIX'"

    # For the bundle of SSL certificates to be used in applications (like curl and others...)
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

    # TODO: This would be nice once configuration by file is available for Cloudflare Pages.
    # Ensure `ZOLA_VERSION` in `netlify.toml` matches the installed version of Zola. This is a safeguard, since it's too easy to forget doing this...
    # zola --version | sed -e "s|zola \(.*\)|\1|g" | xargs -I % sh -c "sed --in-place -e 's|ZOLA_VERSION = .*|ZOLA_VERSION = \"%\"|g' netlify.toml"
  '';

  # Without this, there are warnings about LANG, LC_ALL and locales.
  # This solution is from: https://gist.github.com/aabs/fba5cd1a8038fb84a46909250d34a5c1
  LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
}
