module ATP
  module Processors
    # Makes the AST safe for Marshaling
    class Marshal < Processor
      def on_object(node)
        o = node.value
        if o.is_a?(String)
          node.updated(nil, [{ 'Test' => o }])
        elsif o.is_a?(Hash)
          node.updated(nil, [o])
        elsif o.respond_to?(:to_meta) && o.to_meta && !o.to_meta.empty?
          node.updated(nil, [o.to_meta])
        else
          meta = { 'Test' => o.name }
          meta['Pattern'] = o.try(:pattern)
          node.updated(nil, [meta])
        end
      end

      def on_render(node)
        node.updated(nil, [node.value.to_s])
      end
    end
  end
end
