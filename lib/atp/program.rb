module ATP
  # Program is the top-level container for a collection of test flows
  class Program
    def flow(name)
      flows[name] ||= Flow.new(self, name)
    end

    def flows
      @flows ||= {}
    end

    def respond_to?(*args)
      flows.key?(args.first) || super
    end

    def method_missing(method, *args, &block) # :nodoc:
      if f = flows[method]
        define_singleton_method method do
          f
        end
        f
      else
        super
      end
    end
  end
end
