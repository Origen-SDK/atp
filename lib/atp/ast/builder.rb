module ATP
  module AST
    class Builder
      include Factories

      attr_reader :context

      def flow
        n0(:flow)
      end

      def name(str)
        n(:name, str.to_s)
      end

      def log(str)
        n(:log, str.to_s)
      end

      def render(str)
        n(:render, str.to_s)
      end

      def description(str)
        n(:description, str.to_s)
      end

      def id(symbol)
        n(:id, symbol.to_sym)
      end

      def flow_flag(name, enabled, node)
        n(:flow_flag, name, enabled, node)
      end

      def test_result(id, passed, node)
        n(:test_result, id, passed, node)
      end

      def test_executed(id, executed, node)
        n(:test_executed, id, executed, node)
      end

      def group(name, node)
        n(:group, name, node)
      end

      def cz(setup, node)
        n(:cz, setup, node)
      end

      def new_context
        @context = { conditions: {} }
        yield if block_given?
        @context
      end

      CONDITION_KEYS = [
        :if_enabled, :enabled, :enable_flag, :enable, :if_enable,
        :unless_enabled, :not_enabled, :disabled, :disable, :unless_enable,
        :if_failed, :unless_passed, :failed,
        :if_passed, :unless_failed, :passed,
        :if_ran, :if_executed,
        :unless_ran, :unless_executed,
        :job, :jobs, :if_job, :if_jobs,
        :unless_job, :unless_jobs,
        :if_any_failed, :if_all_failed
      ]

      def apply_conditions(node, conditions)
        conditions.each do |key, value|
          key = key.to_s.downcase.to_sym
          context[:conditions][key] = value
          case key
          when :if_enabled, :enabled, :enable_flag, :enable, :if_enable
            node = flow_flag(value, true, node)
          when :unless_enabled, :not_enabled, :disabled, :disable, :unless_enable
            node = flow_flag(value, false, node)
          when :if_failed, :unless_passed, :failed
            if value.is_a?(Array)
              fail 'if_failed only accepts one ID, use if_any_failed or if_all_failed for multiple IDs'
            end
            node = test_result(value, false, node)
          when :if_passed, :unless_failed, :passed
            if value.is_a?(Array)
              fail 'if_passed only accepts one ID, use if_any_passed or if_all_passed for multiple IDs'
            end
            node = test_result(value, true, node)
          when :if_any_failed
            node = test_result(value, false, node)
          when :if_all_failed
            node = value.reduce(nil) do |nodes, val|
              test_result(val, false, nodes ? nodes : node)
            end
          when :if_ran, :if_executed
            node = test_executed(value, true, node)
          when :unless_ran, :unless_executed
            node = test_executed(value, false, node)
          when :job, :jobs, :if_job, :if_jobs
            # Make sure these are wrapped by an OR, AND jobs doesn't make sense anyway
            unless value.is_a?(OR)
              value = ATP.or(value)
            end
            node = n(:job, apply_boolean(value), node)
          when :unless_job, :unless_jobs
            # Make sure these are wrapped by an OR, AND jobs doesn't make sense anyway
            unless value.is_a?(OR)
              value = ATP.or(value)
            end
            node = n(:job, apply_boolean(ATP.not(value)), node)
          else
            fail "Unknown test condition attribute - #{key} (#{value})"
          end
        end
        node
      end

      def apply_boolean(value)
        if value.is_a?(OR)
          n(:or, *value.map { |v| apply_boolean(v) })
        elsif value.is_a?(AND)
          n(:and, *value.map { |v| apply_boolean(v) })
        elsif value.is_a?(NOT)
          n(:not, apply_boolean(value.value))
        else
          value
        end
      end

      def test(object, options = {})
        children = [n(:object, object)]

        if n = (options[:name] || options[:tname] || options[:test_name])
          children << name(n)
        end
        if n = (options[:number] || options[:num] || options[:tnum] || options[:test_number])
          children << number(n)
        end
        d = options[:description] || options[:desc]
        children << description(d) if d
        children << id(options[:id].to_s.downcase.to_sym) if options[:id]

        children << on_fail(options[:on_fail]) if options[:on_fail]
        children << on_pass(options[:on_pass]) if options[:on_pass]

        test = n(:test, *children)
        if options[:group]
          options[:group].each { |g| test = group(g, test) }
        end

        if options[:conditions]
          apply_conditions(test, options[:conditions])
        else
          test
        end
      end

      def on_fail(options = {})
        children = []
        children << bin(options[:bin]) if options[:bin]
        children << softbin(options[:softbin]) if options[:softbin]
        children << continue if options[:continue]
        n(:on_fail, *children)
      end

      def on_pass(options = {})
        children = []
        children << bin(options[:bin]) if options[:bin]
        children << softbin(options[:softbin]) if options[:softbin]
        children << continue if options[:continue]
        n(:on_pass, *children)
      end

      def bin(val)
        n(:bin, val.to_i)
      end

      def softbin(val)
        n(:softbin, val.to_i)
      end

      def number(val)
        n(:number, val.to_i)
      end

      def continue
        n0(:continue)
      end
    end
  end
end
