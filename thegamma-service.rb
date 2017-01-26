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

def parse_action

end

def parse_args(s)
  p = s.chars.reduce([false, [], []]) { |memo, c|
    quoted, current, acc = memo
    if c == "'" && quoted
      [false, c + current, acc]
    elsif c == "'" && !quoted
      [true, c + current, acc]
    elsif c == "," && !quoted
      [quoted, [], [current.reverse.join] + acc]
    else
      [quoted, [c] + current, acc]
    end
  }

  ([p[1].reverse.join] + p[2]).reverse
end

def parse_chunk(s)
  open_par, close_par = s.index('('), s.rindex(')')
  if open_par.nil? || close_par.nil?
    [s, []]
  else
    [s[0..(open_par-1)], parse_args(s[(open_par+1)..(close_par-1)])]
  end
end

def parse_qs
  chunks = env['QUERY_STRING'].split('$').map { |c| parse_chunk(c) }
  if chunks.size == 0
  else

  end
end

Cuba.define do

  on get do

    on ":table" do |table|
      tbl = ActiveRecord::Base.connection.tables
        .find { |t| t == table }

      qs = env['QUERY_STRING']

      res.write table_metadata(tbl).to_json
    end

  end

end
