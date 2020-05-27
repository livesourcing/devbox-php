#!/bin/sh
set -e

# starting php-fpm
echo "Starting php-fpm"
sudo service php7.3-fpm restart

# starting apache2
echo "Starting apache"
sudo service apache2 restart

# if user provides a settings.json to override, use it
if [ -f /app/.settings.json ]
then
    mkdir -p ~/.local/share/code-server/User/
    rm -f ~/.local/share/code-server/User/settings.json
    ln -s /app/.settings.json ~/.local/share/code-server/User/settings.json
fi

# starting vscode
echo "Starting vscode"
code-server --auth=none --bind-addr 0.0.0.0:8000