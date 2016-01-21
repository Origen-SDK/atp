require 'ast'
module ATP
  class Validator < Processor
    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def process(node)
      if @top_level_called
        super
      else
        @top_level_called = true
        setup
        super(node)
        exit 1 if on_completion
      end
    end

    def setup
    end
  end
end
