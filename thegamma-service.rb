require 'json'

require 'cuba'
require 'cuba/safe'

require 'active_record'
require 'activerecord-jdbc-adapter'

require './thegamma-service-parser.rb'


ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  encoding: "unicode",
  database: "data",
  username: "manuel",
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

      qp = Parser.parse_qs(env['QUERY_STRING'])

      arel_tbl = Arel::Table.new(tbl.intern)

      puts arel_tbl.inspect
      puts qp[:action].first.inspect

      action, args = qp[:action]

      case action
      when :metadata
        res.write table_metadata(tbl).to_json
      when :get_range
        col = args.first
        q = arel_tbl.project(arel_tbl[col])
        q.distinct # .distinct doesn't seem to be chainable :(

        res.write ActiveRecord::Base.connection.execute(q.to_sql)
                    .map { |r| r[col] }
                    .to_json
      when :series
        raise "NotImplemented"
      when :get_the_data
        raise "NotImplemented"
      end
    end
  end
end
