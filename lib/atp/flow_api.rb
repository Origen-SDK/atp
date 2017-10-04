module ATP
  module FlowAPI
    def flow=(flow)
      @flow = flow
    end

    def flow
      @flow
    end

    ([:test, :bin, :pass, :continue, :cz, :log, :sub_test] +
      ATP::Flow::CONDITION_KEYS.keys).each do |method|
      define_method method do |*args, &block|
        flow.send(method, *args, &block)
      end
    end
  end
end
