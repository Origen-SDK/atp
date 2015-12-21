module ATP
  module Processors
    # This processor will apply the relationships between tests, e.g. if testB should only
    # execute if testA passes, then this processor will update the AST to make testA set
    # a flag on pass, and then update testB to only run if that flag is set.
    class Relationship < Processor
      # Returns a hash containing the IDs of all tests that have dependents
      attr_reader :test_results

      # Extracts all test-result nodes from the given AST
      class ExtractTestResults < Processor
        attr_reader :results

        def on_test_result(node)
          ids, state, *children = *node
          unless ids.is_a?(Array)
            ids = [ids]
          end
          ids.each do |id|
            results[id] ||= {}
            if state
              results[id][:passed] = true
            else
              results[id][:failed] = true
            end
          end
          process_all(children)
        end

        def on_test_executed(node)
          id, state, *children = *node
          id, state = *node
          results[id] ||= {}
          results[id][:executed] = true
          process_all(children)
        end

        def results
          @results ||= {}.with_indifferent_access
        end
      end

      def process(node)
        # On first call extract the test_result nodes from the given AST,
        # then process as normal thereafter
        if @first_call_done
          result = super
        else
          @first_call_done = true
          t = ExtractTestResults.new
          t.process(node)
          @test_results = t.results || {}
          result = super
          @first_call_done = false
        end
        result
      end

      def add_pass_flag(id, node)
        node = node.ensure_node_present(:on_pass)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_pass
            n = n.add n1(:set_run_flag, "#{id}_PASSED")
            n.ensure_node_present(:continue)
          else
            n
          end
        end)
      end

      def add_fail_flag(id, node)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_fail
            n = n.add n1(:set_run_flag, "#{id}_FAILED")
            n.ensure_node_present(:continue)
          else
            n
          end
        end)
      end

      def add_executed_flag(id, node)
        node = node.ensure_node_present(:on_fail)
        node = node.ensure_node_present(:on_pass)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_pass
            n = n.add n1(:set_run_flag, "#{id}_RAN")
          else
            n
          end
        end)
      end

      # Set flags depending on the result on tests which have dependents later
      # in the flow
      def on_test(node)
        nid = id(node)
        # If this test has a dependent
        if test_results[nid]
          node = add_pass_flag(nid, node) if test_results[nid][:passed]
          node = add_fail_flag(nid, node) if test_results[nid][:failed]
          node = add_executed_flag(nid, node) if test_results[nid][:executed]
        end
        node
      end

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_test_result(node)
        children = node.children.dup
        id = children.shift
        state = children.shift
        if state
          n(:run_flag, [id_to_flag(id, 'PASSED'), true] + process_all(children))
        else
          n(:run_flag, [id_to_flag(id, 'FAILED'), true] + process_all(children))
        end
      end

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_test_executed(node)
        children = node.children.dup
        id = children.shift
        state = children.shift
        n(:run_flag, [id_to_flag(id, 'RAN'), state] + children)
      end

      # Returns the ID of the give test node (if any), caller is responsible
      # for only passing test nodes
      def id(node)
        if n = node.children.find { |c| c.type == :id }
          n.children.first
        end
      end

      def id_to_flag(id, type)
        if id.is_a?(Array)
          id.map { |i| "#{i}_#{type}" }
        else
          "#{id}_#{type}"
        end
      end
    end
  end
end
