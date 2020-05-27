FROM ubuntu:20.04

WORKDIR /app
EXPOSE 80

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt update

# config selections for install
RUN echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections; \
    echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

RUN apt install -y --no-install-recommends php php-dev php-cli php-fpm \
        php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml \
        php-pear php-bcmath php-memcache php-memcached php-apcu php-xdebug \
        libapache2-mod-php7.4 apache2 wget dumb-init \
        sudo curl ca-certificates

# enable apache2 mods
RUN a2enmod rewrite proxy proxy_http proxy_wstunnel proxy_fcgi

# setup user
RUN adduser --gecos '' --disabled-password coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd && \
    curl -sSL "https://github.com/boxboat/fixuid/releases/download/v0.4.1/fixuid-0.4.1-linux-amd64.tar.gz" \
        | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: coder\ngroup: coder\n" > /etc/fixuid/config.yml

# setup composer
RUN wget -q https://getcomposer.org/download/1.10.6/composer.phar -O /usr/bin/composer && \
    chmod +x /usr/bin/composer

# setup vscode
RUN wget -q https://github.com/cdr/code-server/releases/download/v3.3.1/code-server_3.3.1_amd64.deb && \
    dpkg -i code-server_3.3.1_amd64.deb && \
    rm -f code-server_3.3.1_amd64.deb

# clean all temporary parts
RUN rm -rf /var/www && \
    rm -rf /var/lib/apt/lists/*

# setup xdebug
RUN echo "zend_extension=xdebug.so" > /etc/php/7.4/mods-available/xdebug.ini && \
    echo "[XDebug]" >> /etc/php/7.4/mods-available/xdebug.ini && \
    echo "xdebug.remote_enable = 1" >> /etc/php/7.4/mods-available/xdebug.ini && \
    echo "xdebug.remote_autostart = 1" >> /etc/php/7.4/mods-available/xdebug.ini

# setup workdir
RUN chown -R coder:coder /app

# add config files
ADD files/home/coder/.local /home/coder/.local
ADD files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown -R coder:coder /home/coder/.local

USER coder

# setup vscode extensions
RUN code-server --install-extension felixfbecker.php-intellisense \
        --install-extension felixfbecker.php-debug \
        --install-extension whatwedo.twig \
        --install-extension junstyle.php-cs-fixer

ENTRYPOINT ["dumb-init", "fixuid", "/entrypoint.sh"]