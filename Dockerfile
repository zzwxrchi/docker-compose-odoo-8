FROM debian:jessie
MAINTAINER zzwxrchi

# create the working directory and a place to set the logs (if wanted)
RUN adduser --system --home=/opt/odoo --group odoo
ENV odoo8_path /opt/odoo/8.0
COPY ./backup/server ${odoo8_path}/server
COPY ./pip_requirements ${odoo8_path}/pip_requirements
COPY ./install ${odoo8_path}/install

# Set Locale it needs to be present when installing python packages.
# Otherwise it can lead to issues. eg. when reading the setup.cfg
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# build and dev packages
ENV BUILD_PACKAGE \
    build-essential \
    python-dev \
    libffi-dev \
    libfreetype6-dev \
    libxml2-dev \
    libxslt1-dev \
    libsasl2-dev \
    libldap2-dev \
    libssl-dev \
    libjpeg-dev \
    libcups2-dev \
    zlib1g-dev \
    libfreetype6-dev \
    git

#ENV PURGE_PACKAGE npm

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        ${odoo8_path}/install/package_odoo_8.sh \
        && ${odoo8_path}/install/disable_dst_root_cert-jessie.sh \
        && ${odoo8_path}/install/setup-pip.sh \
        && ${odoo8_path}/install/dev_package.sh

RUN set -x; \
        pip install -U "pip<21.0" "setuptools<45" \
        && find ${odoo8_path}/pip_requirements -name "*requirements.txt" -type f -exec pip install -r '{}' ';'
        #&& ${odoo8_path}/install/purge_dev_package_and_cache.sh

RUN set -x; \
        apt-get update \
        && npm install -y --force-yes -g less less-plugin-clean-css \
        && ln -s /usr/bin/nodejs /usr/bin/node \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/deb/jessie/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y --force-yes install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# change /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es path for user native l10n_es in /mnt/extra-addons
# RUN mv /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es_org

COPY ./entrypoint.sh /
COPY ./config/odoo8-server.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo8-server.conf

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons
RUN mkdir -p /var/lib/odoo
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

RUN mkdir -p ${odoo8_path}/logs

# config file
RUN chown -R odoo:odoo /etc/odoo
# data files
RUN chown -R odoo:odoo /var/lib/odoo
# extra addons
RUN chown -R odoo:odoo /mnt/extra-addons
# server source home
RUN chown -R odoo:odoo ${odoo8_path}

EXPOSE 8069 8071

ENV OPENERP_SERVER /etc/odoo/odoo8-server.conf

USER odoo

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/opt/odoo/8.0/server/openerp-server"]
