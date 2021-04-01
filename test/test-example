#!/usr/bin/env ruby
require 'pathname'
require 'uri'
require 'open-uri'
require 'tempfile'
require 'tmpdir'
require 'json'
require 'shellwords'
require 'net/http'

%w[DEBIAN_VERSION RUBY_VERSION].each do |key|
  fail "#{key} is not defined" unless ENV.key?(key)
end

ENV['DOCKER_BUILDKIT'] = '1'
@mountable_tmp = Pathname(__dir__).join('.tmp').tap(&:mkpath)
@rie_path = @mountable_tmp + 'aws-lambda-rie'

RIE_URI = URI('https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie')
def download_rie(uri = RIE_URI)
  return if @rie_path.exist?
  uri.open('rb') do |c|
    @rie_path.open('wb') do |f|
      IO.copy_stream(c, f)
    end
  end
  @rie_path.chmod(0755)
end

download_rie

Dir.chdir Pathname(__dir__).join('..', 'example')

Dir.mktmpdir do |tmpdir|
  tmpdir = Pathname(tmpdir)

  iidfile = tmpdir + 'iid'
  system *%W[docker build --iidfile=#{iidfile} --build-arg DEBIAN_VERSION --build-arg RUBY_VERSION .], exception: true
  iid = iidfile.read

  inspect = JSON.parse(IO.popen(%W[docker inspect #{iid}], &:read)).first
  entrypoint = inspect['Config']['Entrypoint']
  command = inspect['Config']['Cmd']

  Tempfile.open(['entrypoint-', '.sh'], @mountable_tmp) do |entrypoint_sh|
    script = "\#!/bin/sh\n" + ['exec', '/aws-lambda-rie', *entrypoint].shelljoin + ' "$@"'
    entrypoint_sh.write(script)
    entrypoint_sh.close
    File.chmod(0755, entrypoint_sh.path)

    port = 8080

    cidfile = tmpdir + 'cid'
    system *%W[docker run --cidfile=#{cidfile} -d -v #{@rie_path}:/aws-lambda-rie -v #{entrypoint_sh.path}:/entrypoint.sh -p #{port}:8080 --entrypoint /entrypoint.sh #{iid}], *command, exception: true
    cid = cidfile.read

    Net::HTTP.start('localhost', port) do |http|
      res = http.post('/2015-03-31/functions/function/invocations', '{}')
      result = JSON.parse(res.body)

      p result
      puts 'OK'
    end

  ensure
    if cid
      system *%W[docker logs #{cid}]
      system *%W[docker rm -f #{cid}]
    end
  end
ensure
  system *%W[docker rmi -f #{iid}] if iid
end
