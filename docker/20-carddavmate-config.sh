#!/bin/sh
# Rebuilds config.js from the shipped default plus the environment. Later
# assignments win in JavaScript, so everything the file already sets stays.
set -eu

html=/usr/share/nginx/html
cp /usr/share/nginx/carddavmate-config.js.dist "$html/config.js"

# Quote as a JavaScript string. Backslashes first, or the escapes are escaped.
jsstr() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/\\\\'/g")"
}

{
    echo ''
    echo '/* Appended by 20-carddavmate-config.sh from the environment. */'
    if [ -n "${CARDDAVMATE_HREF:-}" ]; then
        echo "globalNetworkCheckSettings.href=$(jsstr "$CARDDAVMATE_HREF");"
    fi
    if [ -n "${CARDDAVMATE_HREF_LABEL:-}" ]; then
        echo "globalNetworkCheckSettings.hrefLabel=$(jsstr "$CARDDAVMATE_HREF_LABEL");"
    fi
    if [ -n "${CARDDAVMATE_LANGUAGE:-}" ]; then
        echo "globalInterfaceLanguage=$(jsstr "$CARDDAVMATE_LANGUAGE");"
    fi
    # Anything else, verbatim. It is JavaScript, not a value: a syntax error
    # here takes the whole client down with a blank page.
    if [ -n "${CARDDAVMATE_EXTRA_JS:-}" ]; then
        echo "$CARDDAVMATE_EXTRA_JS"
    fi
} >> "$html/config.js"
