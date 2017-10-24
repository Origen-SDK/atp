module ATP
  module FlowAPI
    def atp=(atp)
      @atp = atp
    end

    def atp
      @atp
    end

    ([:test, :bin, :pass, :continue, :cz, :log, :sub_test, :volatile, :set_flag, :enable, :disable] +
      ATP::Flow::CONDITION_KEYS.keys).each do |method|
      define_method method do |*args, &block|
        atp.send(method, *args, &block)
      end
    end

    alias_method :logprint, :log
  end
end
