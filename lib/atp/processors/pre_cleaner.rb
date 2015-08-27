module ATP
  module Processors
    # Modifies the AST by performing some basic clean up, mainly to sanitize
    # user input. For example it will ensure that all IDs are symbols, and that
    # all names are lower-cased strings.
    class PreCleaner < Processor
      def on_id(node)
        id = node.to_a.first
        id = id.to_s.downcase.to_sym
        node.updated(nil, [id])
      end
    end
  end
end
