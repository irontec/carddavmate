# Container image

CardDavMATE as static files behind nginx. There is no backend: the client speaks CardDAV
from the browser straight to the DAV server.

```sh
docker build -t carddavmate .
docker run --rm -p 8080:80 \
  -e CARDDAVMATE_HREF='https://contacts.example.com/card.php/principals/' \
  -e CARDDAVMATE_LANGUAGE=es_ES \
  carddavmate
```

## Configuration

The entrypoint rebuilds `config.js` from a pristine copy on every start and appends the
overrides, so later assignments win and anything not named keeps the client's shipped
default. A restart cannot append twice.

| Variable | |
| --- | --- |
| `CARDDAVMATE_HREF` | The CardDAV **principal URL without the user part** — the client appends the username from its login screen. A collection URL here fails as an empty client rather than as an error, and the trailing slash is required. Unset keeps the client's default, which builds a same-origin URL |
| `CARDDAVMATE_HREF_LABEL` | Shown on the login screen |
| `CARDDAVMATE_LANGUAGE` | e.g. `es_ES` |
| `CARDDAVMATE_EXTRA_JS` | Raw JavaScript, appended last. Use it where the value has to be computed in the browser — serving on several hostnames, for one. It is code, not a value: a syntax error takes the client down with a blank page |

## Serve it from the DAV server's origin

The client issues `PROPFIND` from JavaScript, and SabreDAV — which Baikal is built on —
sends no CORS headers. From another origin every request is blocked by the browser and
the client reports no address books, with nothing useful in the console. Serve it on a
path of the host the DAV server already answers on.

## What the image leaves out

- **`auth/`**, the PHP module for setup type (c). There is no PHP here, so nginx would
  serve `config.inc` and the LDAP plugin as plain text.
- **HTML5 AppCache.** `cache_handler.js` calls `window.applicationCache.addEventListener`
  without checking, and that is `undefined` in every current browser, so it throws on
  load. The `manifest` attribute would also pin the `config.js` the entrypoint rewrites
  on each start. Both are stripped at build time.
