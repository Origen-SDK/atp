module ATP
  module Processors
    # Runs at the very end of a processor run, to do some final cleanup,
    # e.g. to assign generated IDs to tests that don't have one
    class PostCleaner < Processor
      # Returns a hash containing the IDs of all tests that have
      # been used
      attr_reader :ids

      # Extracts all ID values of tests within the given AST
      class ExtractTestIDs < Processor
        attr_reader :results

        def on_test(node)
          id = node.children.find { |n| n.type == :id }
          if id
            @results ||= {}
            @results[id] = true
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
          t = ExtractTestIDs.new
          t.process(node)
          @ids = t.results || {}
          result = super
          @first_call_done = false
        end
        result
      end

      def on_test(node)
      end
    end
  end
end
