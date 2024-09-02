# [dmarcoux/dmarcoux.com](https://github.com/dmarcoux/dmarcoux.com)

## Development

Reproducible development environment for [Zola](https://github.com/getzola/zola)
which relies on [Nix](https://github.com/NixOS/nix), a purely functional and
cross-platform package manager.

Start with `nix-shell --pure`.

### Create Page / Blog Post

There is no built-in command for this in Zola, simply copy from one of the
existing pages or create a file with only the frontmatter like:

```markdown
+++
title = "My page"
(...)
+++
```

### Web Server

Start web server for development on localhost:1111

```bash
zola serve
```

### Lint Markdown Files

```bash
lint
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

- Build command: `zola build`
- Build output directory: `/public`
- Root directory: `/`
- Build comments on pull requests: `Enabled`

#### Environment Variables

The following environment variables are set for both `production` and `preview`.

- `ZOLA_VERSION` with the value `0.19.2`

## Credits

- I've based my theme on [Apollo](https://github.com/not-matthias/apollo).
