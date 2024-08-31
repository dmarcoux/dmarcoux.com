# [dmarcoux/dmarcoux.com](https://github.com/dmarcoux/dmarcoux.com)

## Development

Reproducible development environment for [Hugo](https://github.com/gohugoio/hugo)
which relies on [Nix](https://github.com/NixOS/nix), a purely functional and
cross-platform package manager.

Start with `nix-shell --pure`.

### Create Blog Post

```bash
hugo new posts/my-new-post.md
```

### Web Server

Start web server for development on localhost:1313

```bash
hugo server -F
```

### Lint Markdown Files

```bash
lint
```

### Pull Changes From Git Submodules

```bash
git submodule update --remote
```

## Production

### Host

The application is hosted on [Cloudflare](https://www.cloudflare.com/) and configured
via the web UI.

[Preview
deployments](https://developers.cloudflare.com/pages/configuration/preview-deployments)
are commenting in pull requests whenever the deploy preview is ready.

### Domain

The domain `dmarcoux.com` is managed on
[Cloudflare](https://www.cloudflare.com/) with a `CNAME` record for `@` pointing
to the default site name provided by Cloudflare Pages.

### Settings

#### Build Configurations

- Build command: `hugo --gc --minify`
- Build output directory: `/public`
- Root directory: `/`
- Build comments on pull requests: `Enabled`

#### Environment Variables

The following environment variables are set for both `production` and `preview`.

- `HUGO_ENV` with the value `production`
- `HUGO_VERSION` with the value `0.105.0`
