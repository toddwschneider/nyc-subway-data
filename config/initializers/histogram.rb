module Enumerable
  def to_histogram
    each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }
  end
end
