# Hacking

## Local builds and testing
```
export DEBIAN_VERSION=buster
export RUBY_VERSION=3.0

docker build --build-arg DEBIAN_VERSION --build-arg RUBY_VERSION --target builder -t "public.ecr.aws/exapico/lambda-ruby-builder:$DEBIAN_VERSION-$RUBY_VERSION" .
docker build --build-arg DEBIAN_VERSION --build-arg RUBY_VERSION --target runtime -t "public.ecr.aws/exapico/lambda-ruby:$DEBIAN_VERSION-$RUBY_VERSION" .

test/test-example
```

## Public registry
GitHub Actions build images from the master branch and push them to ECR Public.

- https://gallery.ecr.aws/exapico/lambda-ruby
- https://gallery.ecr.aws/exapico/lambda-ruby-builder
