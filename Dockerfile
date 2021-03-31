ARG DEBIAN_VERSION

### Fetch and verify archive signing key
FROM debian:${DEBIAN_VERSION}-slim as repokey

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gpg ca-certificates curl
RUN curl -fsS https://sorah.jp/packaging/debian/3F0F56A8.pub.txt -o /tmp/sorah-rbpkg.key
RUN test "$(gpg --with-colons --with-fingerprint </tmp/sorah-rbpkg.key | grep ^fpr: | cut -d: -f10)" = 805E57E2327EE86EB8180E0669CEB9D53F0F56A8
RUN gpg --dearmor </tmp/sorah-rbpkg.key >/tmp/sorah-rbpkg.gpg

### Base for runtime and builder images
FROM debian:${DEBIAN_VERSION}-slim as base

ARG DEBIAN_VERSION
ARG RUBY_VERSION

RUN echo "deb [signed-by=/usr/share/keyrings/sorah-rbpkg.gpg] http://cache.ruby-lang.org/lab/sorah/deb/ $(printenv DEBIAN_VERSION | cut -d- -f1) main" | \
    tee /etc/apt/sources.list.d/sorah-rbpkg.list
RUN echo -n 'Package: *\nPin: origin "cache.ruby-lang.org"\nPin-Priority: 500\n\nPackage: ruby ruby-dev libruby\nPin: version /^1:'"$(printenv RUBY_VERSION | sed 's/\./\\./')"'\..*nkmi/\nPin-Priority: 600' | \
    tee /etc/apt/preferences.d/sorah-rbpkg.pref

COPY --from=repokey /tmp/sorah-rbpkg.gpg /usr/share/keyrings/sorah-rbpkg.gpg

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates ruby && \
    find /var/lib/apt/lists -type f -delete

RUN useradd -d /var/task -s /sbin/nologin app

RUN mkdir /var/task
WORKDIR /var/task

### Runtime image
FROM base as runtime

RUN gem install -N aws_lambda_ric

ENTRYPOINT ["/usr/local/bin/aws_lambda_ric"]

### Bilder image
FROM base as builder

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ruby-dev build-essential gpg && \
    find /var/lib/apt/lists -type f -delete

ENTRYPOINT ["/bin/sh"]
