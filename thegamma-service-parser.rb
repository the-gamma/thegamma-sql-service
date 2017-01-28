module Parser

  def self.trim_indent(s)
    if s.start_with?("'") && s.end_with?("'")
      s[1..-2]
    else
      s
    end
  end

  OPS = {
    "count-dist" => :count_distinct,
    "unique" => :return_unique,
    "concat-vals" => :concat_values,
    "sum" => :sum,
    "mean" => :mean
  }

  def self.parse_agg_op(op)
    case op
    when "key"
      :group_key
    when "count-all"
      :count_all
    else
      parsed = OPS.find { |k, f|
        op.start_with?(k)
      }
      unless parsed.nil?
        [parsed[1], op[parsed[0].size+1..-1]]
      else
        raise "Unknown operation"
      end
    end
  end


  def self.parse_action(a)
    op, args = a

    case op
    when "metadata"
      [[:metadata], true]

    when "series"
      [[:get_series, args], true]
    when "range"
      [[:get_range, args], true]
    else
      [[:get_the_data], false]
    end
  end

  def self.parse_condition(cond)
    cond = cond.strip

    start = if cond.start_with?("'")
              cond[1..-1].index("'") + 1
            else
              0
            end
    neq, eq = cond[start..-1].index(" neq "), cond[start..-1].index(" eq ")

    unless neq.nil?
      return [trim_indent(cond[0..neq+start-1]), false, cond[neq+start+5..-1]]
    end
    unless eq.nil?
      return [trim_indent(cond[0..eq+start-1]), true, cond[eq+start+4..-1]]
    end

    raise "Incorrectly formatted condition"
  end

  def self.parse_transform(a)
    op, args = a
    case op
    when "drop"
      [:drop_columns, args.map { |col| trim_indent(col) }]
    when "sort"
      [:sort_by,
       args.map { |col|
         if col.end_with?(" asc")
           [trim_indent(col[0..-5]), :asc]
         elsif col.end_with?(" desc")
           [trim_indent(col[0..-6]), :desc]
         else
           [trim_indent(col), :asc]
         end
       }]
    when "filter"
      [:filter_by, args.map { |cond| parse_condition(cond) }]
    when "groupby"
      keys = args.take_while { |s| s.start_with?("by ") }
               .map { |s| trim_indent(s[3..-1])}
      aggs = args.drop_while { |s| s.start_with?("by ") }
               .map { |s| parse_agg_op(s) }
      [:group_by, [keys, aggs]]
    when "take"
      [:take, args.first.to_i]
    when "skip"
      [:skip, args.first.to_i]
    end
  end

  def self.parse_args(s)
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

  def self.parse_chunk(s)
    open_par, close_par = s.index('('), s.rindex(')')
    if open_par.nil? || close_par.nil?
      [s, []]
    else
      [s[0..(open_par-1)], parse_args(s[(open_par+1)..(close_par-1)])]
    end
  end

  def self.parse_qs(qs)
    chunks = qs.split('$').map { |c| parse_chunk(c) }
    if chunks.size == 0
      {
        transformations: [],
        action: [:get_the_data]
      }
    else
      action, explicit = parse_action(chunks.last)
      chunks = if explicit
                 chunks[0..-2]
               else
                 chunks
               end
      {
        transformations: chunks.map { |c| parse_transform(c) },
        action: action
      }
    end
  end
end
