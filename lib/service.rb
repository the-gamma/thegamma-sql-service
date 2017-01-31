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

PREVIEW_SIZE = 10

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

      qs = URI.unescape(env['QUERY_STRING'])
      qp = Parser.parse_qs(qs)
      is_preview =  qs.end_with?('&preview')

      arel_tbl = Arel::Table.new(tbl.intern)

      action, args = qp[:action]

      res['Content-Type'] = 'application/json'

      resp = case action
             when :metadata
               table_metadata(tbl).to_json
             when :get_range
               col = args.first
               q = arel_tbl.project(arel_tbl[col])
               q.distinct # .distinct doesn't seem to be chainable :(

               ActiveRecord::Base.connection.execute(q.to_sql)
                 .map { |r| r[col] }
                 .to_json
             when :get_series
               q = Interpreter.query(arel_tbl,
                                     qp[:transformations])
               if is_preview
                 q = q.take(PREVIEW_SIZE)
               end

               puts "Executing query: `#{q.to_sql}`"
               ActiveRecord::Base.connection.execute(q.to_sql).map { |r|
                 args.map { |col| r[col] }
               }.to_json

             when :get_the_data
               q = Interpreter.query(arel_tbl,
                                     qp[:transformations])

               if is_preview
                 q = q.take(PREVIEW_SIZE)
               end

               puts "Executing query: `#{q.to_sql}`"
               ActiveRecord::Base.connection.execute(q.to_sql).to_json

             end

      res.write resp
    end
  end
end
