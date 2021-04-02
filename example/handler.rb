require 'mysql2'

def main(event:, context:)
  info = Mysql2::Client.info
  fail 'Version mismatch for mysqlclient' unless info['version'] == info['header_version']

  {ok: true}
end
