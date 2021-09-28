# [dmarcoux/blog.dmarcoux.com](https://github.com/dmarcoux/blog.dmarcoux.com)

![Netlify Status](https://api.netlify.com/api/v1/badges/5065c943-d1ba-49c8-942a-4ceea3e5dd80/deploy-status)

## Development

### Create New Blog Post

```bash
hugo new posts/my-new-post.md
```

### Web Server

Start web server for development on localhost:1313

```bash
hugo server -F
```

### Lint Markdown Files

Install linter:

```bash
npm install markdownlint-cli2 --global
```

Update linter:

```bash
npm update -g markdownlint-cli2
```

Run linter:

```bash
markdownlint-cli2 "**/*.md" "#themes" "#node_modules"
```

### Pull Changes From Git Submodules

```bash
git submodule update --remote
```

## Production

### Host

The application is hosted on [Netlify](https://www.netlify.com/) and configured
with [netlify.toml](./netlify.toml).

[Deploy
notifications](https://docs.netlify.com/site-deploys/notifications/#github-pull-request-comments)
are commenting in pull requests whenever the deploy preview is ready. The
notification's event is `Deploy Preview succeeded`.

### Domain

The domain `dmarcoux.com` is managed on
[Cloudflare](https://www.cloudflare.com/) with a `CNAME` record for `blog`
pointing to the default site name provided by Netlify. A custom domain is then
set for `blog.dmarcoux.com` on Netlify.
