module ATP
  class AND < ::Array
    def initialize(*vals)
      vals.flatten.each { |v| self << v }
    end

    def inspect
      "AND#{super}"
    end
  end
end
