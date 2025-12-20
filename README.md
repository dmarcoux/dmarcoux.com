# [dmarcoux/dmarcoux.com](https://github.com/dmarcoux/dmarcoux.com)

## Development

Reproducible development environment for [Zola](https://github.com/getzola/zola)
which relies on [Mise](https://mise.jdx.dev/).

Install tools with:

```bash
mise install
```

See available tasks with:

```bash
mise run
```

### Create Page / Blog Post

There is no built-in command for this in Zola, simply copy from one of the
existing pages or create a file with only the frontmatter like:

```markdown
+++
title = "My page"
(...)
+++
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

Since Cloudflare Pages only support a single build configuration for all
environments (preview and production), I need to use a few tricks in order to
have the right base URL depending on the environment. Credits goes to this
[comment](https://github.com/NathanVaughn/blog.nathanv.me/discussions/210#discussioncomment-9629836).

As for the development environment, it isn't affected since `zola serve` already
overwrites the base URL to `localhost`.

In the preview environment, the environment variable `CF_PAGES_URL` is set to
the URL of the preview deployment, so this can be passed to the `zola build`
command with the `--base-url` flag. In production, we set the environment
variable `CF_PAGES_URL` to `https://dmarcoux.com`. This way, I can use the same
build command for both environments and have the right base URL in all
environments.

#### Build Configurations

- Build command: `zola build --base-url $CF_PAGES_URL`
- Build output directory: `/public`
- Root directory: `/`
- Build comments on pull requests: `Enabled`

#### Environment Variables

The following environment variables are set.

_Production & Preview_:

- `ZOLA_VERSION` with the value `0.19.2`

_Production_:

- `CF_PAGES_URL` with the value `https://dmarcoux.com`

## Credits

- I've based my theme on [Apollo](https://github.com/not-matthias/apollo).
