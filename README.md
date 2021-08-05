# <a href="https://github.com/dmarcoux/blog.dmarcoux.com">dmarcoux/blog.dmarcoux.com</a>

![Netlify Status](https://api.netlify.com/api/v1/badges/5065c943-d1ba-49c8-942a-4ceea3e5dd80/deploy-status)

## Development

Start web server for development on localhost:1313
```
hugo server -D
```

## Production

### Host

The application is hosted on [Netlify](https://www.netlify.com/) and configured with [netlify.toml](./netlify.toml).

[Deploy notifications](https://docs.netlify.com/site-deploys/notifications/#github-pull-request-comments)
are commenting in pull requests whenever the deploy preview is ready. The notification's event is `Deploy Preview succeeded`.

### Domain

The domain `dmarcoux.com` is managed on [Cloudflare](https://www.cloudflare.com/) with a `CNAME` record for `blog`
pointing to the default site name provided by Netlify. A custom domain is then set for `blog.dmarcoux.com` on Netlify.
