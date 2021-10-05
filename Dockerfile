ARG DEBIAN_VERSION

### Base for runtime and builder images
FROM debian:${DEBIAN_VERSION}-slim as base

ARG DEBIAN_VERSION
ARG RUBY_VERSION

RUN printf 'deb [signed-by=/usr/share/keyrings/sorah-rbpkg.asc] http://cache.ruby-lang.org/lab/sorah/deb/ %s main\n' "$(printenv DEBIAN_VERSION | cut -d- -f1)" | \
    tee /etc/apt/sources.list.d/sorah-rbpkg.list
RUN printf 'Package: *\nPin: origin "cache.ruby-lang.org"\nPin-Priority: 500\n\nPackage: ruby ruby-dev libruby\nPin: version /^1:%s\..*nkmi/\nPin-Priority: 600\n' "$(printenv RUBY_VERSION | sed 's/\./\\./')" | \
    tee /etc/apt/preferences.d/sorah-rbpkg.pref

COPY sorah-rbpkg.asc /usr/share/keyrings/

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates ruby && \
    find /var/lib/apt/lists -type f -delete

ENV LANG=C.UTF-8 \
    TZ=UTC \
    LAMBDA_TASK_ROOT=/var/task

WORKDIR /var/task

### Runtime image
FROM base as runtime

RUN gem install -N aws_lambda_ric

ENTRYPOINT ["/usr/local/bin/aws_lambda_ric"]

### Builder image
FROM base as builder

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ruby-dev build-essential git gpg && \
    find /var/lib/apt/lists -type f -delete

ENTRYPOINT ["/bin/sh"]
