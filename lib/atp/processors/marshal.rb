module ATP
  module Processors
    # Makes the AST safe for Marshaling
    class Marshal < Processor
      def on_object(node)
        if node.value.is_a?(String)
          node
        else
          node.updated(nil, [node.value.name])
        end
      end
    end
  end
end
