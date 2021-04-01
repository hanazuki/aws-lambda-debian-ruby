require 'mysql2'

def main(event:, context:)
  Mysql2::Client.info
end
