module Parser

  def self.parse_transform(a)
    op, args = a
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
