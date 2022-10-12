ARG DEBIAN_VERSION

### Build unreleased version of aws_lambda_ric from source
FROM debian:${DEBIAN_VERSION}-slim as gem

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates ruby wget

ARG REV=4dea33c0c3d1c148db7d9a5813e18b5643e395af

WORKDIR /src/aws-lambda-ruby-runtime-interface-client
RUN wget -q https://github.com/aws/aws-lambda-ruby-runtime-interface-client/archive/$REV.tar.gz -O /tmp/src.tar.gz
RUN tar xf /tmp/src.tar.gz --strip=1
RUN sed -i "/VERSION/s/$/+'.1.git-$REV'/" ./lib/aws_lambda_ric/version.rb
RUN gem build aws_lambda_ric.gemspec

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

COPY --from=gem /src/aws-lambda-ruby-runtime-interface-client/*.gem /tmp
RUN gem install -N /tmp/*.gem

ENTRYPOINT ["/usr/local/bin/aws_lambda_ric"]

### Builder image
FROM base as builder

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ruby-dev build-essential git gpg && \
    find /var/lib/apt/lists -type f -delete

ENTRYPOINT ["/bin/sh"]
