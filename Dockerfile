# CardDavMATE as static files behind nginx. The client speaks CardDAV straight
# from the browser, so it is normally served from the same origin as the DAV
# server — see helm/carddavmate/README.md.
FROM nginx:1.29-alpine

COPY docker/default.conf /etc/nginx/conf.d/default.conf
COPY docker/20-carddavmate-config.sh /docker-entrypoint.d/20-carddavmate-config.sh
COPY . /usr/share/nginx/html/

RUN set -eux; \
    cd /usr/share/nginx/html; \
    # The build context needs these; the web root does not.
    rm -rf docker Dockerfile .dockerignore; \
    # Kept pristine: the entrypoint rebuilds config.js from this on every start,
    # so a container that restarts does not append its overrides twice.
    cp config.js /usr/share/nginx/carddavmate-config.js.dist; \
    # HTML5 AppCache is gone from every current browser, and cache_handler.js
    # does an unguarded `window.applicationCache.addEventListener` that throws
    # on load. The manifest would also pin config.js, which the entrypoint
    # rewrites on every start.
    sed -i 's/ manifest="cache.manifest"//' index.html; \
    sed -i '/cache_handler\.js/d' index.html; \
    grep -q 'cache.manifest' index.html && exit 1 || true

EXPOSE 80
