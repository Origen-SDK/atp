module ATP
  # Program is the top-level container for a collection of test flows
  class Program

    # Returns an example test program with some pre-built test flows,
    # this can be used as test data when developing new outputters.
    def self.example
      p = new
      p.flow
    end

    def flow(name)
      flows[name] ||= Flow.new(self)
    end

    def flows
      @flows ||= {}
    end
  end
end
