module ATP
  # Implements the main user API for building and interacting
  # with an abstract test program
  class Flow
    attr_reader :program, :name
    # Returns the raw AST
    attr_reader :raw
    attr_accessor :id

    def initialize(program, name = nil)
      @program = program
      @name = name
      @raw = builder.flow
    end

    # @api private
    def marshal_dump
      [@name, @program, Processors::Marshal.new.process(@raw)]
    end

    # @api private
    def marshal_load(array)
      @name, @program, @raw = array
    end

    # Returns a processed/optimized AST, this is the one that should be
    # used to build and represent the given test flow
    def ast
      ast = Processors::PreCleaner.new.process(raw)
      # File.open("a1.txt", "w") { |f| f.write(ast) }
      ast = Processors::FlowID.new.run(ast, id) if id
      # File.open("a2.txt", "w") { |f| f.write(ast) }
      Validators::DuplicateIDs.new(self).process(ast)
      Validators::MissingIDs.new(self).process(ast)
      ast = Processors::Condition.new.process(ast)
      ast = Processors::Relationship.new.process(ast)
      ast = Processors::PostCleaner.new.process(ast)
      Validators::Jobs.new(self).process(ast)
      ast
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
      t = apply_open_conditions(options) do |options|
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
        if f = options.delete(:flag_pass)
          options[:on_pass] ||= {}
          options[:on_pass][:set_run_flag] = f
        end
        if f = options.delete(:flag_fail)
          options[:on_fail] ||= {}
          options[:on_fail][:set_run_flag] = f
        end
        builder.test(instance, options)
      end
      append(t) unless r
      t
    end

    def bin(number, options = {})
      extract_meta!(options)
      t = apply_open_conditions(options) do |options|
        fail 'A :type option set to :pass or :fail is required when calling bin' unless options[:type]
        options[:bin] = number
        options[:softbin] ||= options[:soft_bin] || options[:sbin]
        builder.set_result(options[:type], options)
      end
      append(t)
    end

    def cz(instance, cz_setup, options = {})
      extract_meta!(options)
      t = apply_open_conditions(options) do |options|
        conditions = options.delete(:conditions)
        options[:return] = true
        builder.cz(cz_setup, test(instance, options), conditions: conditions)
      end
      append(t)
    end
    alias_method :characterize, :cz

    # Append a log message line to the flow
    def log(message, options = {})
      extract_meta!(options)
      t = apply_open_conditions(options) do |options|
        builder.log(message, options)
      end
      append(t)
    end

    # Enable a flow control variable
    def enable(var, options = {})
      extract_meta!(options)
      t = apply_open_conditions(options) do |options|
        builder.enable_flow_flag(var, options)
      end
      append(t)
    end

    # Disable a flow control variable
    def disable(var, options = {})
      extract_meta!(options)
      t = apply_open_conditions(options) do |options|
        builder.disable_flow_flag(var, options)
      end
      append(t)
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

    # Returns true if the test context generated from the supplied options + existing condition
    # wrappers, is different from that which was applied to the previous test.
    def context_changed?(options)
      a = context
      b = build_context(options)
      !context_equal?(a, b)
    end

    def context
      builder.context
    end

    def context_equal?(a, b)
      if a.size == b.size
        a = clean_condition(a[:conditions])
        b = clean_condition(b[:conditions])
        if a.keys.sort == b.keys.sort
          a.all? do |key, value|
            value.flatten.uniq.sort == b[key].flatten.uniq.sort
          end
        end
      end
    end

    private

    def clean_condition(h)
      c = {}
      h.each do |hash|
        key, value = hash.first[0], hash.first[1]
        key = clean_key(key)
        value = clean_value(value)
        c[key] ||= []
        c[key] << value unless c[key].include?(value)
      end
      c
    end

    def clean_value(value)
      if value.is_a?(Array)
        value.map { |v| v.to_s.downcase }.sort
      else
        value.to_s.downcase
      end
    end

    def clean_key(key)
      case key.to_sym
      when :if_enabled, :enabled, :enable_flag, :enable, :if_enable
        :if_enable
      when :unless_enabled, :not_enabled, :disabled, :disable, :unless_enable
        :unless_enable
      when :if_failed, :unless_passed, :failed
        :if_failed
      when :if_passed, :unless_failed, :passed
        :if_passed
      when :if_any_failed, :unless_all_passed
        :if_any_failed
      when :if_all_failed, :unless_any_passed
        :if_all_failed
      when :if_any_passed, :unless_all_failed
        :if_any_passed
      when :if_all_passed, :unless_any_failed
        :if_all_passed
      when :if_ran, :if_executed
        :if_ran
      when :unless_ran, :unless_executed
        :unless_ran
      when :job, :jobs, :if_job, :if_jobs
        :if_job
      when :unless_job, :unless_jobs
        :unless_job
      else
        fail "Unknown test condition attribute - #{key}"
      end
    end

    def build_context(options)
      c = open_conditions.dup
      if options[:conditions]
        options[:conditions].each do |key, value|
          c << { key => value }
        end
      end
      { conditions: c }
    end

    def builder
      @builder ||= AST::Builder.new
    end

    def apply_open_conditions(options)
      if options[:context] == :current
        options[:conditions] = builder.context[:conditions]
      end
      builder.new_context
      t = yield(options)
      unless options[:context] == :current
        open_conditions.each do |conditions|
          t = builder.apply_conditions(t, conditions)
        end
      end
      t
    end

    def extract_meta!(options)
      builder.source_file = options.delete(:source_file) if options[:source_file]
      builder.source_line_number = options.delete(:source_line_number) if options[:source_line_number]
      builder.description = options.delete(:description) if options[:description]
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
  end
end
