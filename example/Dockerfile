#syntax=docker/dockerfile:1.2

ARG DEBIAN_VERSION=buster
ARG RUBY_VERSION=3.0


FROM public.ecr.aws/exapico/lambda-debian-ruby:builder-${DEBIAN_VERSION}-${RUBY_VERSION} as builder

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmariadb-dev && \
    find /var/lib/apt/lists -type f -delete

RUN bundle config set --local deployment true && \
    bundle config set --local path vendor/bundle && \
    bundle config set --local without development:test

COPY Gemfile Gemfile.lock ./

ENV BUNDLE_GLOBAL_GEM_CACHE=true \
    BUNDLE_USER_CACHE=/cache/bundler \
    BUNDLE_CLEAN=true

RUN --mount=type=cache,target=/cache/bundler \
    MAKEFLAGS=-j$(nproc) bundle install --verbose


FROM public.ecr.aws/exapico/lambda-debian-ruby:runtime-${DEBIAN_VERSION}-${RUBY_VERSION}

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmariadb3 && \
    find /var/lib/apt/lists -type f -delete

COPY ./ ./
COPY --from=builder /var/task/ ./

USER app
CMD ["handler.main"]
