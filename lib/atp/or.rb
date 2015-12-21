module ATP
  class OR < ::Array
    def initialize(*vals)
      vals.flatten.each { |v| self << v }
    end

    def inspect
      "OR#{super}"
    end
  end
end
