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

The application is hosted on [Cloudflare](https://www.cloudflare.com/).

### Domain

The domain `dmarcoux.com` is managed on
[Cloudflare](https://www.cloudflare.com/) with a `CNAME` record for `@` pointing
to the default site name provided by Cloudflare Pages.

### Settings

Everything is configured via Wrangler in [wrangler.toml](./wrangler.toml).

I use Cloudflare Pages with static HTML since Zola isn't supported in
[Cloudflare Pages
v2+](https://developers.cloudflare.com/pages/configuration/build-image/).

## Credits

- I've based my theme on [Apollo](https://github.com/not-matthias/apollo).
