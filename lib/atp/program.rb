module ATP
  class Program

    def flow(name)
      flows[name] ||= Flow.new(self)
    end

    def flows
      @flows ||= {}
    end
  end
end
