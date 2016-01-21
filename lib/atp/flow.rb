module ATP
  # Implements the main user API for building and interacting
  # with an abstract test program
  class Flow
    attr_reader :program, :name
    # Returns the raw AST
    attr_reader :raw

    def initialize(program, name = nil)
      @program = program
      @name = name
      @builder = AST::Builder.new
      @raw = builder.flow
    end

    # Returns a processed/optimized AST, this is the one that should be
    # used to build and represent the given test flow
    def ast
      ast = Processors::PreCleaner.new.process(raw)
      Validators::DuplicateIDs.new(self).process(ast)
      Validators::MissingIDs.new(self).process(ast)
      ast = Processors::Condition.new.process(ast)
      ast = Processors::Relationship.new.process(ast)
      ast = Processors::PostCleaner.new.process(ast)
    end

    # Group all tests generated within the given block
    #
    # @example
    #   flow.group "RAM Tests" do
    #     flow.test ...
    #     flow.test ...
    #   end
    def group(name, options = {})
      open_groups.push([])
      yield
      append builder.group(name, open_groups.pop, options)
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
    def test(instance, options = {})
      extract_meta!(options)
      r = options.delete(:return)
      if options[:context] == :current
        options[:conditions] = builder.context[:conditions]
      end
      # Allows any continue, bin, or soft bin argument passed in at the options top-level to be assumed
      # to be the action to take if the test fails
      if b = options.delete(:bin)
        options[:on_fail] ||= {}
        options[:on_fail][:bin] = b
      end
      if b = options.delete(:softbin) || b = options.delete(:sbin) || b = options.delete(:soft_bin)
        options[:on_fail] ||= {}
        options[:on_fail][:softbin] = b
      end
      if options.delete(:continue)
        options[:on_fail] ||= {}
        options[:on_fail][:continue] = true
      end
      builder.new_context

      t = builder.test(instance, options)
      unless options[:context] == :current
        open_conditions.each do |conditions|
          t = builder.apply_conditions(t, conditions)
        end
      end
      append(t) unless r
      t
    end

    def bin(number, options = {})
      extract_meta!(options)
      fail 'A :type option set to :pass or :fail is required when calling bin' unless options[:type]
      options[:bin] = number
      options[:softbin] ||= options[:soft_bin] || options[:sbin]
      append builder.set_result(options[:type], options)
    end

    def cz(instance, cz_setup, options = {})
      extract_meta!(options)
      options[:return] = true
      append(builder.cz(cz_setup, test(instance, options)))
    end
    alias_method :characterize, :cz

    # Append a log message line to the flow
    def log(message, options = {})
      extract_meta!(options)
      append builder.log(message)
    end

    # Insert explicitly rendered content in to the flow
    def render(str, options = {})
      extract_meta!(options)
      append builder.render(str)
    end

    def with_condition(options)
      extract_meta!(options)
      open_conditions.push(options)
      yield
      open_conditions.pop
    end
    alias_method :with_conditions, :with_condition

    # Execute the given flow in the console
    def run(options = {})
      Formatters::Datalog.run_and_format(ast, options)
      nil
    end

    private

    def extract_meta!(options)
      builder.source_file = options.delete(:source_file) if options[:source_file]
      builder.source_line_number = options.delete(:source_line_number) if options[:source_line_number]
    end

    # For testing
    def raw=(ast)
      @raw = ast
    end

    def open_conditions
      @open_conditions ||= []
    end

    def open_groups
      @open_groups ||= []
    end

    def append(node)
      if open_groups.empty?
        @raw = @raw.updated(nil, @raw.children + [node])
      else
        open_groups.last << node
      end
    end

    def builder
      @builder
    end
  end
end
