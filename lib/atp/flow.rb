module ATP
  # Implements the main user API for building and interacting
  # with an abstract test program
  class Flow
    attr_reader :program
    # Returns the raw AST
    attr_reader :raw

    def initialize(program)
      @program = program
      @builder = AST::Builder.new
      @raw = builder.flow
    end

    # Returns a processed/optimized AST, this is the one that should be
    # used to build and represent the given test flow
    def ast
      ast = Processors::PreCleaner.new.process(raw)
      ast = Processors::Condition.new.process(ast)
      ast = Processors::Relationship.new.process(ast)
      ast = Processors::PostCleaner.new.process(ast)
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
      groups = ([options.delete(:group) || options.delete(:groups)] + open_groups).flatten.compact
      options[:group] = groups unless groups.empty?
      append builder.test(name, options)
    end

    # Group all tests generated within the given block
    #
    # @example
    #   flow.group "RAM Tests" do
    #     flow.test ...
    #     flow.test ...
    #   end
    def group(name)
      open_groups.push name
      yield
      open_groups.pop
    end

    private

    def open_groups
      @open_groups ||= []
    end

    def append(node)
      @raw = (@raw << node)
    end

    def builder
      @builder
    end
  end
end
