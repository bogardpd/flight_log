# Provides utilities for interacting with tables of data.
module Table

  # Character to use in the counter column when multiple adjacent items have
  # the same rank in a sorted table.
  SAME_RANK = "⋮"

  # Accept a sort querystring in the format "category" or "-category", and
  # return a hash of sort category and direction.
  # 
  # @param query [String] a sort querystring in the format "category" or
  #   "-category"
  # @param default_category [Symbol] the sort category to return if no category
  #   is specified
  # @param default_direction [:asc, :desc] the sort direction to return if no
  #   direction is specified
  # @return [Array<Symbol>] an array containing a symbol for sort category and
  #   a symbol for sort direction
  def self.sort_parse(query, default_category, default_direction)
    return [default_category, default_direction] if query.nil?
    
    # Extract category and direction
    if query[0] == "-"
      category = query[1..-1].to_sym
      direction = :desc
    else
      category = query.to_sym
      direction = :asc
    end
    
    return [category, direction]
  end

end