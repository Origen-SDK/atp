module ATP
  module Formatters
    # Returns the executed flow as a string of test names. This
    # is mainly intended to be used for testing the runner.
    class Basic < Formatter
      def format(node, options = {})
        @output = ''
        process(node)
        @output
      end

      def on_test(node)
        @output += node.find(:name).value
        @output += "\n"
      end
    end
  end
end
