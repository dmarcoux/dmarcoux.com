# <a href="https://github.com/dmarcoux/blog.dmarcoux.com">dmarcoux/blog.dmarcoux.com</a>

![Netlify Status](https://api.netlify.com/api/v1/badges/5065c943-d1ba-49c8-942a-4ceea3e5dd80/deploy-status)

## Development

Setup npm to install packages in home directory:
```
mkdir "$HOME/.npm-packages"
npm config set prefix "$HOME/.npm-packages"
```

Install [Gridsome CLI](https://www.npmjs.com/package/@gridsome/cli):
```
npm install --global @gridsome/cli
```

### Project setup
```
npm install
```

### Start web server for development on localhost:8080
```
gridsome develop
```

### Compiles and minifies for production
```
gridsome build
```

## Production

### Host

The application is hosted on [Netlify](https://www.netlify.com/) with the following settings:
- Build command: `gridsome build`
- Publish directory: `dist`

[Deploy notifications](https://docs.netlify.com/site-deploys/notifications/#github-pull-request-comments)
are commenting in pull requests whenever the deploy preview is ready. The notification's event is `Deploy Preview succeeded`.

### Domain

The domain is managed on [Cloudflare](https://www.cloudflare.com/).
