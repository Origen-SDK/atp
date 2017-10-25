module ATP
  module FlowAPI
    def atp=(atp)
      @atp = atp
    end

    def atp
      @atp
    end

    ([:test, :bin, :pass, :continue, :cz, :log, :sub_test, :volatile, :set_flag, :enable, :disable, :render] +
      ATP::Flow::CONDITION_KEYS.keys).each do |method|
      define_method method do |*args, &block|
        options = args.pop if args.last.is_a?(Hash)
        options ||= {}
        add_meta!(options) if respond_to?(:add_meta!)
        add_description!(options) if respond_to?(:add_description!)
        args << options
        atp.send(method, *args, &block)
      end
    end

    alias_method :logprint, :log
  end
end
