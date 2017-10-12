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

        def on_if_failed(node)
          ids, *children = *node
          unless ids.is_a?(Array)
            ids = [ids]
          end
          ids.each do |id|
            results[id] ||= {}
            results[id][:failed] = true
          end
          process_all(children)
        end
        alias_method :on_if_any_failed, :on_if_failed
        alias_method :on_if_all_failed, :on_if_failed

        def on_if_passed(node)
          ids, *children = *node
          unless ids.is_a?(Array)
            ids = [ids]
          end
          ids.each do |id|
            results[id] ||= {}
            results[id][:passed] = true
          end
          process_all(children)
        end
        alias_method :on_if_any_passed, :on_if_passed
        alias_method :on_if_all_passed, :on_if_passed

        def on_if_ran(node)
          id, *children = *node
          results[id] ||= {}
          results[id][:ran] = true
          process_all(children)
        end
        alias_method :on_unless_ran, :on_if_ran

        def results
          @results ||= {}.with_indifferent_access
        end
      end

      def run(node)
        t = ExtractTestResults.new
        t.process(node)
        @test_results = t.results || {}
        process(node)
      end

      def add_pass_flag(id, node)
        node = node.ensure_node_present(:on_pass)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_pass
            n = n.add n2(:set_flag, "#{id}_PASSED", :auto_generated)
          elsif n.type == :on_fail
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
            n = n.add n2(:set_flag, "#{id}_FAILED", :auto_generated)
            n.ensure_node_present(:continue)
          else
            n
          end
        end)
      end

      def add_ran_flags(id, node)
        node = node.ensure_node_present(:on_fail)
        node = node.ensure_node_present(:on_pass)
        node.updated(nil, node.children.map do |n|
          if n.type == :on_pass || n.type == :on_fail
            n = n.add n2(:set_flag, "#{id}_RAN", :auto_generated)
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
          node = add_ran_flags(nid, node) if test_results[nid][:ran]
        end
        if node.type == :group
          node.updated(nil, process_all(node))
        else
          node
        end
      end
      alias_method :on_group, :on_test

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_if_failed(node)
        id, *children = *node
        n(:if_flag, [id_to_flag(id, 'FAILED')] + process_all(children))
      end
      alias_method :on_if_any_failed, :on_if_failed
      alias_method :on_if_all_failed, :on_if_failed

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_if_passed(node)
        id, *children = *node
        n(:if_flag, [id_to_flag(id, 'PASSED')] + process_all(children))
      end
      alias_method :on_if_any_passed, :on_if_passed
      alias_method :on_if_all_passed, :on_if_passed

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_if_ran(node)
        id, *children = *node
        n(:if_flag, [id_to_flag(id, 'RAN')] + process_all(children))
      end

      # Remove test_result nodes and replace with references to the flags set
      # up stream by the parent node
      def on_unless_ran(node)
        id, *children = *node
        n(:unless_flag, [id_to_flag(id, 'RAN')] + process_all(children))
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
