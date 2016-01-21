module ATP
  module AST
    module Factories
      def n(type, *children)
        options = children.last.is_a?(Hash) ? children.pop : {}
        options[:file] ||= options.delete(:source_file) || try(:source_file)
        options[:line_number] ||= options.delete(:source_line_number) || try(:source_line_number)
        ATP::AST::Node.new(type, children, options)
      end

      def n0(type, options = {})
        n(type, options)
      end
    end
  end
end
