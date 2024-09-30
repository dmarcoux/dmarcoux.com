+++
title = "Use lib.fakeHash as a Placeholder for Hashes in Nix Packages"
description = """\
                When you create a Nix package for a given software, you \
                sometimes need to enter a hash, which you might not \
                know. For such instances, use lib.fakeHash.\
              """
date = "2024-09-30"

[extra.meta]
type = "article"
keywords = "Nix, NixOS, packaging, packages, lib.fakeHash, hash, hashes"
+++

When you create a Nix package for a given software, you sometimes need to enter a
hash, which you might not know. An example of this is when you fetch the
software's source code from GitHub with `fetchFromGitHub`. For such instances,
temporarily import `lib` and use `lib.fakeHash`. Here's an example below for a
Rust package:

```nix
{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "caffeinate";
  version = "e20985a4b630eb5c76e16c2547da0aba65f097d5";

  src = fetchFromGitHub {
    owner = "rschmukler";
    repo = pname;
    rev = version;
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  meta = with lib; {
    description = "Command-line app bringing caffeinate functionality to xidlehook";
    homepage = "https://github.com/rschmukler/caffeinate";
    license = licenses.mit;
    maintainers = with maintainers; [ dmarcoux ];
  };
}
```

See the two instances of `lib.fakeHash` above? Try to build the package now,
like in your NixOS configuration with `callPackage ./your_package_file.nix {}`.
The build fails with an error message similar to this:

```bash
error: hash mismatch in fixed-output derivation '/nix/store/nkbm7cpsyz46bbzynk0bzc309wbmlszn-caffeinate-e20985a4b630eb5c76e16c2547da0aba65f097d5-vendor.tar.gz.drv':
         specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
            got:    sha256-ss0J+L3XWwV96AAuLScYl2FiK4K76XK35mPmDF/TAAg=
```

The last line of the error message contains the actual hash, see `got:
sha256-(...)`. You can now replace `lib.fakeHash` with that value. If everything
else is fine, the package will now successfully build. Do not forget to remove
the `lib` import if you have no other use for it.

Et voilà! I hope this helps you in your next Nix packaging endeavours.
