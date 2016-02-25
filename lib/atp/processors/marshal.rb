module ATP
  module Processors
    # Makes the AST safe for Marshaling
    class Marshal < Processor
      def on_object(node)
        if node.value.is_a?(String) || node.value.is_a?(Hash)
          node.updated(nil, [{ 'Test' => node.value }])
        elsif node.value.respond_to?(:to_meta)
          node.updated(nil, [node.value.to_meta])
        else
          node.updated(nil, [{ 'Test' => node.value.name }])
        end
      end
    end
  end
end
