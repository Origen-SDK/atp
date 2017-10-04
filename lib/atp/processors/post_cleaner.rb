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

      def run(node)
        t = ExtractTestIDs.new
        t.process(node)
        @ids = t.results || {}
        process(node)
      end

      def on_test(node)
      end
    end
  end
end
