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
          id, state = *node
          @results ||= {}
          @results[id] ||= {}
          if state
            @results[id][:passed] = true
          else
            @results[id][:failed] = true
          end
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
          @test_results = t.results 
          result = super
          @first_call_done = false
        end
        result
      end

      def add_pass_flag(id, node)
        node = node.ensure_node_present(:on_pass)
        node.updated(nil, node.children.map { |n|
          if n.type == :on_pass
            n.add n1(:set_run_flag, "#{id}_passed")
          else
            n
          end
        })
      end

      def add_fail_flag(id, node)
        node = node.ensure_node_present(:on_fail)
        node.updated(nil, node.children.map { |n|
          if n.type == :on_fail
            n = n.add n1(:set_run_flag, "#{id}_failed")
            n.ensure_node_present(:continue)
          else
            n
          end
        })
      end

      # Set flags depending on the result on tests which have dependents later
      # in the flow
      def on_test(node)
        nid = id(node)
        # If this test has a dependent
        if test_results[nid]
          node = add_pass_flag(nid, node) if test_results[nid][:passed]
          node = add_fail_flag(nid, node) if test_results[nid][:failed]
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
          n(:run_flag, ["#{id}_passed", true] + children)
        else
          n(:run_flag, ["#{id}_failed", true] + children)
        end
      end

      # Returns the ID of the give test node (if any), caller is responsible
      # for only passing test nodes
      def id(node)
        if n = node.children.find {|c| c.type == :id }
          n.children.first
        end
      end
    end
  end
end
