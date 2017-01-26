require 'cuba'
require 'cuba/safe'

require 'active_record'
require 'activerecord-jdbc-adapter'


ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  encoding: "unicode",
  database: "datachile",
  username: "datachile",
  password: "yapoweon",
  host: "hermes",
  port: "5433"
)

TYPE_MAP = {
  'integer' => 'number',
  'string' => 'string'
}

def table_metadata(table_name)

end

Cuba.define do

  on get do

    on ":table" do |table|
      tbl = ActiveRecord::Base.connection.tables
        .find { |t| t == table }

      return if tbl.nil?

      res.write ActiveRecord::Base.connection.columns(tbl).map { |c|
        [c.name, c.type.to_s]
      }.inspect


    end

  end

end
