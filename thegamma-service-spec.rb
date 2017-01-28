require 'active_record'
require 'activerecord-jdbc-adapter'

require './thegamma-service-parser.rb'
require './thegamma-service-interpreter.rb'

describe "Parser" do

  it 'should parse transforms' do
    # drop
    expect(Parser.parse_transform(["drop", ["Gold", "'Broze'", "Silver"]])).to eq([:drop_columns, ["Gold", "Broze", "Silver"]])

    # sort
    expect(Parser.parse_transform(["sort", ["Gold desc"]])).to eq([:sort_by, [["Gold", :desc]]])
    expect(Parser.parse_transform(["sort", ["Gold"]])).to eq([:sort_by, [["Gold", :asc]]])

    # filter
    expect(Parser.parse_transform(["filter", ["Games eq Rio (2016)"]])).to eq([:filter_by, [["Games", true, "Rio (2016)"]]])
    expect(Parser.parse_transform(["filter", ["Games neq Rio (2016)"]])).to eq([:filter_by, [["Games", false, "Rio (2016)"]]])

    # groupby
    expect(Parser.parse_transform(["groupby", ["by Athlete","sum Gold","key"]])).to eq([:group_by, [["Athlete"], [[:sum, "Gold"], :group_key]]])

    # take
    expect(Parser.parse_transform(["take", ["8"]])).to eq([:take, 8])
  end

  it 'should parse a query string' do
    expected = {
      :transformations =>
      [
        [:filter_by, [["Games", true, "Rio (2016)"]]],
        [:group_by, [["Athlete"], [[:sum, "Gold"], :group_key]]],
        [:sort_by, [["Gold", :desc]]],
        [:take, 8]
      ],
      :action => [:get_series, ["Athlete", "Gold"]]
    }
    expect(Parser.parse_qs("filter(Games eq Rio (2016))$groupby(by Athlete,sum Gold,key)$sort(Gold desc)$take(8)$series(Athlete,Gold)")).to eq(expected)
  end
end

describe "Interpreter" do

  before (:all) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: File.join(File.dirname(__FILE__), 'db', 'medals.db')
    )
    @table = Arel::Table.new(:medals)
  end

  it "should generate a SQL query" do
    parsed = Parser.parse_qs("filter(Games eq Rio (2016))$groupby(by Athlete,count-all,sum Gold,key)$sort(Gold desc)$take(8)$series(Athlete,Gold)")
    expect(Interpreter.query(@table, parsed[:transformations]).to_sql).to eq("SELECT  COUNT(*) AS count, SUM(\"medals\".\"Gold\") AS Gold, \"medals\".\"Athlete\" FROM \"medals\"  WHERE \"medals\".\"Games\" = 'Rio (2016)' GROUP BY \"medals\".\"Athlete\" ORDER BY Gold desc LIMIT 8")

    parsed = Parser.parse_qs("groupby(by Athlete,count-all,sum Gold,key)$sort(Gold desc)$take(8)$series(Athlete,Gold)")
    puts parsed.inspect
    expected = "SELECT  COUNT(*) AS count, SUM(\"medals\".\"Gold\") AS Gold, \"medals\".\"Athlete\" FROM \"medals\"  GROUP BY \"medals\".\"Athlete\" ORDER BY Gold desc LIMIT 8"
    query = Interpreter.query(@table, parsed[:transformations]).to_sql

    expect(query).to eq(expected)

  end
end
