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
        unless @testing
          exit 1 if on_completion
        end
      end
    end

    # For test purposes, returns true if validation failed rather
    # than exiting the process
    def test_process(node)
      @testing = true
      process(node)
      on_completion
    end

    def setup
    end
  end
end
