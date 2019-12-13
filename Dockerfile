FROM nikolaik/python-nodejs:python3.7-nodejs12-alpine

ADD . /app
WORKDIR /app

RUN apk add --no-cache git gcc linux-headers musl-dev coreutils && \
	yarn global add surge && \
	pip install psaw psutil && \
	git clone https://github.com/chid/snudown /tmp/snudown && \
	cd /tmp/snudown && \
	python setup.py install && \
	rm -fr /tmp/snudown && \
  mv /app/netrc /root/.netrc && \
  mv /app/entrypoint.sh /entrypoint.sh && \
	chmod +x /app/*.py

ADD netrc /root/.netrc
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


