module ATP
  # Implements the main user API for building and interacting
  # with an abstract test program
  class Flow
    attr_reader :program
    attr_reader :ast

    def initialize(program)
      @program = program
      @builder = AST::Builder.new
      @ast = builder.flow
    end

    # Add a test line to the flow
    #
    # @param [String, Symbol] the name of the test
    # @param [Hash] options a hash to describe the test's attributes
    # @option options [Symbol] :id A unique test ID
    # @option options [String] :description A description of what the test does, usually formatted in markdown
    # @option options [Hash] :on_fail What action to take if the test fails, e.g. assign a bin
    # @option options [Hash] :on_pass What action to take if the test passes
    # @option options [Hash] :conditions What conditions must be met to execute the test
    def test(name, options = {})
      append builder.test(name, options)
    end

    private

    def append(node)
      @ast = (@ast << node)
    end

    def builder
      @builder
    end
  end
end
