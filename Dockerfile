FROM debian:jessie
MAINTAINER zzwxrchi

# create the working directory and a place to set the logs (if wanted)
COPY ./odoo_requirements /odoo_requirements
COPY ./install /install

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
    libfreetype6-dev
#    git

#ENV PURGE_PACKAGE npm

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        /install/package_odoo_8.sh \
        && /install/disable_dst_root_cert-jessie.sh \
        && /install/setup-pip.sh \
        #&& /install/postgres.sh \
        #&& /install/kwkhtml_client.sh \
        && /install/dev_package.sh \
        && pip install -U "pip<21.0" "setuptools<45"

RUN set -x; \
        find /odoo_requirements -name "*requirements.txt" -type f -exec pip install -r '{}' ';' #\
        #&& /install/purge_dev_package_and_cache.sh

RUN set -x; \
        apt-get update \
        npm install -y --force-yes -g less less-plugin-clean-css \
        && ln -s /usr/bin/nodejs /usr/bin/node #\
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/deb/jessie/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y --force-yes install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

ENV ODOO_VERSION 8.0
ENV ODOO_RELEASE 20171001
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
				&& echo 'c41c6eaf93015234b4b62125436856a482720c3d odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y --force-yes install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

# change /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es path for user native l10n_es in /mnt/extra-addons
RUN mv /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es /usr/lib/python2.7/dist-packages/openerp/addons/l10n_es_org

COPY ./entrypoint.sh /
COPY ./config/openerp-server.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/openerp-server.conf

RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

EXPOSE 8069 8071

ENV OPENERP_SERVER /etc/odoo/openerp-server.conf

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openerp-server"]
