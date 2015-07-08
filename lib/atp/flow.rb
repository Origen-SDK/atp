module ATP
  class Flow
    attr_reader :program
    attr_reader :ast

    def initialize(program)
      @program = program
      @builder = AST::Builder.new
      @ast = builder.flow
    end

    def test(name, options)
      test = builder.test(name)
      test << builder.bin(options[:bin]) if options[:bin]
      test << builder.softbin(options[:softbin]) if options[:softbin]
      test << builder.continue if options[:continue]
      ast << test
    end

    private

    def builder
      @builder
    end
  end
end
