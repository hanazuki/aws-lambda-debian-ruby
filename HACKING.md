# Hacking

## Local builds and testing
```
export DEBIAN_VERSION=buster
export RUBY_VERSION=3.0

scripts/build
test/test-example
```

## Public registry
GitHub Actions build images from the master branch and push them to ECR Public.

- https://gallery.ecr.aws/exapico/lambda-ruby
- https://gallery.ecr.aws/exapico/lambda-ruby-builder
