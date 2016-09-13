module ATP
  module Processors
    # Makes the AST safe for Marshaling
    class Marshal < Processor
      def on_object(node)
        if node.value.is_a?(String)
          node.updated(nil, [{ 'Test' => node.value }])
        elsif node.value.is_a?(Hash)
          node.updated(nil, [node.value])
        elsif node.value.respond_to?(:to_meta)
          node.updated(nil, [node.value.to_meta])
        else
          meta = { 'Test' => node.value.name }
          meta['Pattern'] = node.value.try(:pattern)
          node.updated(nil, [meta])
        end
      end

      def on_render(node)
        node.updated(nil, [node.value.to_s])
      end
    end
  end
end
