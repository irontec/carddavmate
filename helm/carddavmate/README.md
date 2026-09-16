# CardDavMATE Helm chart

Serves [CardDavMATE](https://www.inf-it.com/open-source/clients/carddavmate/) as static
files behind nginx. There is no backend: the client speaks CardDAV from the browser
straight to the DAV server.

## Serve it from the same origin as the DAV server

That is the whole deployment decision. The client issues `PROPFIND` from JavaScript, and
a DAV server on another origin has to answer CORS preflights — SabreDAV, which Baikal is
built on, sends no CORS headers at all, so every request is blocked by the browser and
the client reports no address books with nothing useful in the console.

Put it on a path of the host the DAV server already answers on:

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: contacts.example.com
      paths:
        - path: /carddavmate
          pathType: Prefix
  stripPrefixes:
    - /carddavmate
config:
  href: https://contacts.example.com/card.php/principals/
```

**`stripPrefixes` is not optional when the path is not `/`.** nginx serves from the root,
so without it `index.html` and every asset under it is a 404. The client's own URLs are
relative, so the browser keeps the prefix and Traefik takes it off on each request.
Traefik only; the chart renders a `stripPrefix` Middleware and references it from the
Ingress.

## `config.href` is a principal URL, not a collection

```
https://contacts.example.com/card.php/principals/     correct
https://contacts.example.com/card.php/principals/bob/ a user's principal, not the base
https://contacts.example.com/card.php/addressbooks/   a collection URL
```

With `globalNetworkCheckSettings`, which is what this chart configures, the value is the
principal URL **without the user part** — the client appends the username from the login
screen. A collection URL here fails as an empty client rather than as an error. The
trailing slash is required.

Leave `href` empty to keep the client's own default, which builds a same-origin URL from
`location`.

## Configuration is environment, not a ConfigMap

`config.*` becomes environment variables that the image's entrypoint appends to
`config.js` at start-up. Later assignments win in JavaScript, so anything not named here
keeps the client's shipped default.

That puts the configuration in the podspec, which means **changing it rolls the pods by
itself** — no checksum annotation, and no `subPath` mount that silently never updates.

`config.extraJs` is appended verbatim for anything the chart does not name. It is
JavaScript, not a value: a syntax error there takes the client down with a blank page and
nothing in the pod's logs.

## What the image leaves out

- **`auth/`**, the PHP module for setup type (c). This image has no PHP, so nginx would
  serve `config.inc` and the LDAP plugin as plain text.
- **HTML5 AppCache.** `cache.manifest` is dropped, along with the `manifest` attribute on
  `<html>` and the `cache_handler.js` script tag. AppCache is gone from every current
  browser, `cache_handler.js` calls `window.applicationCache.addEventListener` without
  checking and throws on load, and the manifest would pin the `config.js` the entrypoint
  rewrites on every start.

## Values

See [values.yaml](values.yaml). Notable ones:

| Key | Default | Description |
| --- | --- | --- |
| `image.tag` | `""` | Defaults to the chart's `appVersion`. |
| `ingress.stripPrefixes` | `[]` | Prefixes removed before nginx. Required when the path is not `/`. |
| `ingress.traefikApiVersion` | `traefik.io/v1alpha1` | `traefik.containo.us/v1alpha1` on Traefik v2. |
| `config.href` | `""` | Principal URL without the user part. Empty keeps the same-origin default. |
| `config.language` | `""` | e.g. `es_ES`. Empty keeps the client's default. |
| `config.extraJs` | `""` | Raw JavaScript, appended last. |

## Scaling

`replicaCount` above 1 is safe: the pods serve identical files and hold no state. All of
it — contacts, address books, sessions — lives on the DAV server.
