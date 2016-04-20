FROM python:2-alpine

MAINTAINER Rachid Zarouali <rzarouali@gmail.com>

# Install required packages
RUN apk add --update supervisor nginx expect sqlite nodejs memcached pkgconf pkgconfig make gcc net-tools musl-dev libffi-dev openldap-dev libsasl
COPY conf/requirements.txt /tmp/requirements.txt
RUN	pip install -r /tmp/requirements.txt
RUN	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon==0.9.15
RUN	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web==0.9.15

# Create system service config
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/supervisord.conf /etc/supervisor/conf.d/grafana.conf

# Create graphite config
COPY conf/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
COPY conf/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
COPY conf/carbon.conf /var/lib/graphite/conf/carbon.conf
COPY conf/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
RUN	mkdir -p /var/lib/graphite/storage/whisper
RUN touch /var/lib/graphite/storage/graphite.db /var/lib/graphite/storage/index
RUN	chmod 0775 /var/lib/graphite/storage /var/lib/graphite/storage/whisper
RUN python /var/lib/graphite/webapp/graphite/manage.py migrate --noinput --pythonpath=/var/lib/graphite/webapp/graphite --settings=settings
RUN	chmod 0664 /var/lib/graphite/storage/graphite.db

# Specify the volumes
VOLUME /opt/graphite/storage/whisper

# Expose the ports
EXPOSE 80
EXPOSE 2003
EXPOSE 2004
EXPOSE 7002

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["/bin/sh"]
