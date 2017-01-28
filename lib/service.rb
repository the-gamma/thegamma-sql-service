require 'json'
require 'uri'

require 'cuba'
require 'cuba/safe'

require 'active_record'
require 'activerecord-jdbc-adapter'

require_relative './parser'
require_relative './interpreter'


ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: File.join(File.dirname(__FILE__), '..', 'db', 'medals.db')
)

TYPE_MAP = {
  'integer' => 'number',
  'string' => 'string',
  'text' => 'string'
}

def table_metadata(table_name)
  ActiveRecord::Base.connection.columns(table_name).reduce({}) { |h, c|
    puts c.type.to_s
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

      qp = Parser.parse_qs(URI.unescape(env['QUERY_STRING']))

      arel_tbl = Arel::Table.new(tbl.intern)

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
      when :get_series
        q = Interpreter.query(arel_tbl,
                              qp[:transformations])
        puts "Executing query: `#{q.to_sql}`"
        res.write ActiveRecord::Base.connection.execute(q.to_sql).to_json
      when :get_the_data
        raise "NotImplemented"
      end
    end
  end
end
