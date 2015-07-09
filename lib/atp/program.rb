module ATP
  # Program is the top-level container for a collection
  # of test flows
  class Program
    def flow(name)
      flows[name] ||= Flow.new(self)
    end

    def flows
      @flows ||= {}
    end
  end
end
