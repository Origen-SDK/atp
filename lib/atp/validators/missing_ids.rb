module ATP
  module Validators
    class MissingIDs < Validator
      def setup
        @referenced_ids = {}
        @present_ids ||= {}.with_indifferent_access
        @referenced_early = {}.with_indifferent_access
      end

      def on_completion
        failed = false
        @referenced_ids.each do |id, nodes|
          unless @present_ids[id]
            Origen.log.error "Test ID #{id} is referenced in flow #{flow.name} in the following lines, but it is never defined:"
            nodes.each do |node|
              Origen.log.error "  #{node.source}"
            end
            failed = true
            @referenced_early.delete(id)
          end
        end
        @referenced_early.each do |id, nodes|
          Origen.log.error "Test ID #{id} is referenced in flow #{flow.name} in the following line(s):"
          nodes.each do |node|
            Origen.log.error "  #{node.source}"
          end
          Origen.log.error 'but it was not defined until later:'
          Origen.log.error "  #{@present_ids[id].first.source}"
          failed = true
        end
        failed
      end

      def on_id(node)
        id = node.value
        @present_ids[id] ||= []
        @present_ids[id] << node
      end

      def on_test_executed(node)
        ids = node.to_a[0]
        [ids].flatten.each do |id|
          unless id =~ /^extern/
            @referenced_ids[id] ||= []
            @referenced_ids[id] << node
            unless @present_ids[id]
              @referenced_early[id] ||= []
              @referenced_early[id] << node
            end
          end
        end
        process_all(node)
      end
      alias_method :on_test_result, :on_test_executed
    end
  end
end
