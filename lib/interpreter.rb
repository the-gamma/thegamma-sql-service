module Interpreter

  def self.query(table, transformations)
    query = transformations.reduce(table) do |query, transformation|
      tr, args = transformation
      case tr
      when :filter_by
        args.reduce(query) do |query, arg|
          col, eq, val = arg
          query.where(table[col.intern].send(eq ? :eq : :not_eq, val))
        end
      when :sort_by
        args.reduce(query) do |query, arg|
          col, dir = arg
          query.order(Arel.sql("#{col} #{dir}"))
        end
      when :take
        query.take(args)
      when :skip
        query.skip(args)
      when :group_by
        groups, aggs = args

        aggs.reduce(query.group(groups.map { |g| table[g.intern] })) do |query, agg|
          if agg.is_a?(Array)
            aggfunc, aggarg = agg
            case aggfunc
            when :count_distinct
              query.project(Arel.sql("COUNT(DISTINCT #{aggarg}) as #{aggarg}"))
            when :unique
              raise "TODO: unique not implemented"
            when :concat_vals
              raise "TODO: concat-vals not implemented"
            when :sum
              query.project(table[agg[1].intern].sum.as(agg[1]))
            when :mean
              query.project(table[agg[1].intern].avg.as(agg[1]))
            end
          else
            case agg
            when :group_key
              query.project(groups.map { |g| table[g.intern] })
            when :count_all
              query.project(Arel.star.count.as('count'))
            else
              # TODO implement
              query
            end
          end
        end
      else
        # TODO implement
        query.project(Arel.star)
      end
    end

    if query.projections.empty?
      query = query.project(Arel.star)
    end

    query
  end
end
