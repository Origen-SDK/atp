module ATP
  class NOT
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def inspect
      "NOT[#{value}]"
    end
  end
end
