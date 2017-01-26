require 'json'

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
  ActiveRecord::Base.connection.columns(table_name).reduce({}) { |h, c|
    t = TYPE_MAP[c.type.to_s]
    unless t.nil?
      h[c.name] = t
    end
    h
  }
end

Cuba.define do

  on get do

    on ":table" do |table|
      tbl = ActiveRecord::Base.connection.tables
        .find { |t| t == table }

      return if tbl.nil?

      res.write table_metadata(tbl).to_json
    end

  end

end
