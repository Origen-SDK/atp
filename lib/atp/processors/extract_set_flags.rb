module ATP
  module Processors
    # Extracts all flags which are set within the given flow, returning
    # them in an array
    class ExtractSetFlags < ATP::Processor
      def run(nodes)
        @results = []
        process_all(nodes)
        @results.uniq
      end

      def on_set_flag(node)
        flag = node.value
        @results << flag
      end
    end
  end
end
