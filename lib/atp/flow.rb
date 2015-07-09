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
