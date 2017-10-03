module ATP
  module AST
    class Builder
      include Factories

      # Ensures the given flow ast has a volatile node, then adds the
      # given flags to it
      def add_volatile_flags(flow, flags)
        name, *nodes = *flow
        if nodes[0] && nodes[0].type == :volatile
          v = nodes.shift
        else
          v = n0(:volatile)
        end
        existing = v.children.map { |f| f.type == :flag ? f.value : nil }.compact
        new = []
        flags.each do |flag|
          new << n(:flag, flag) unless existing.include?(flag)
        end
        v = v.updated(nil, v.children + new)
        flow.updated(nil, [name, v] + nodes)
      end

      def new_context
        @context = { conditions: [] }
        yield if block_given?
        @context
      end

      #      def apply_conditions(node, conditions)
      #        conditions.each do |key, value|
      #          # Sometimes conditions can be an array (in the case of the current context
      #          # being re-used), so rectify that now
      #          if key.is_a?(Hash)
      #            fail 'Something has gone wrong applying the test conditions' if key.size > 1
      #            key, value = key.first[0], key.first[1]
      #          end
      #          key = key.to_s.downcase.to_sym
      #          # Represent all condition values as lower cased strings internally
      #          if value.is_a?(Array)
      #            value = value.map { |v| (v[0] == '$') ? v.to_s : v.to_s.downcase }
      #          else
      #            value = (value[0] == '$') ? value.to_s : value.to_s.downcase
      #          end
      #          context[:conditions] << { key => value }
      #          case key
      #          when :if_enabled, :enabled, :enable_flag, :enable, :if_enable
      #            node = n(:if_enabled, value, node)
      #          when :unless_enabled, :not_enabled, :disabled, :disable, :unless_enable
      #            node = n(:unless_enabled, value, node)
      #          when :if_failed, :unless_passed, :failed
      #            if value.is_a?(Array)
      #              fail 'if_failed only accepts one ID, use if_any_failed or if_all_failed for multiple IDs'
      #            end
      #            node = n(:if_failed, value, node)
      #          when :if_passed, :unless_failed, :passed
      #            if value.is_a?(Array)
      #              fail 'if_passed only accepts one ID, use if_any_passed or if_all_passed for multiple IDs'
      #            end
      #            node = n(:if_passed, value, node)
      #          when :if_any_failed, :unless_all_passed
      #            node = test_result(value, false, node)
      #          when :if_all_failed, :unless_any_passed
      #            node = value.reduce(nil) do |nodes, val|
      #              test_result(val, false, nodes ? nodes : node)
      #            end
      #          when :if_any_passed, :unless_all_failed
      #            node = test_result(value, true, node)
      #          when :if_all_passed, :unless_any_failed
      #            node = value.reduce(nil) do |nodes, val|
      #              test_result(val, true, nodes ? nodes : node)
      #            end
      #          when :if_ran, :if_executed
      #            node = test_executed(value, true, node)
      #          when :unless_ran, :unless_executed
      #            node = test_executed(value, false, node)
      #          when :job, :jobs, :if_job, :if_jobs
      #            node = job(value, true, node)
      #          when :unless_job, :unless_jobs
      #            node = job(value, false, node)
      #          when :if_flag
      #            if value.is_a?(Array)
      #              fail 'if_flag only accepts one flag'
      #            end
      #            node = run_flag(value, true, node)
      #          when :unless_flag
      #            if value.is_a?(Array)
      #              fail 'unless_flag only accepts one flag'
      #            end
      #            node = run_flag(value, false, node)
      #          else
      #            fail "Unknown test condition attribute - #{key} (#{value})"
      #          end
      #        end
      #        node
      #      end
    end
  end
end
