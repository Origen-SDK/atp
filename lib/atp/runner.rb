module ATP
  # This class is responsible for executing the given test flow based on a given
  # set of runtime conditions.
  # A subset of the input AST will be returned containing only the nodes that would
  # be hit when the flow is executed under the given conditions.
  class Runner < Processor
    def run(node, options = {})
      @options = options
      process(node)
    end

    def on_flow(node)
      @flow = []
      process_all(node.children)
      node.updated(nil, @flow)
    end

    def on_flow_flag(node)
      flag, enabled, *nodes = *node
      if (enabled && flow_flags.include?(flag)) ||
         (!enabled && !flow_flags.include?(flag))
        process_all(nodes)
      end
    end

    def on_test(node)
      if id = node.find(:id)
        id = id.to_a[0]
        if failed_test_ids.include?(id)
          node = node.add(n0(:failed))
        end
      end
      @flow << node
    end

    def on_test_result(node)
      id, passed, *nodes = *node
      if (passed && !failed_test_ids.include?(id)) ||
         (!passed && failed_test_ids.include?(id))
        process_all(nodes)
      end
    end

    def failed_test_ids
      @failed_test_ids ||= [@options[:failed_test_id] || @options[:failed_test_ids]].flatten.compact
    end

    # Returns an array of enabled flow flags
    def flow_flags
      @flow_flags ||= [@options[:flow_flag] || @options[:flow_flags]].flatten.compact
    end
  end
end
