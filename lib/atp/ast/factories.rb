module ATP
  module AST
    module Factories
      def n(type, children, options = {})
        options[:file] ||= options.delete(:source_file) || try(:source_file)
        options[:line_number] ||= options.delete(:source_line_number) || try(:source_line_number)
        options[:description] ||= options.delete(:description) || try(:description)
        options[:id] = ATP.next_id
        ATP::AST::Node.new(type, children, options)
      end

      def n0(type, options = {})
        n(type, [], options)
      end

      def n1(type, arg, options = {})
        n(type, [arg], options)
      end

      def n2(type, arg1, arg2, options = {})
        n(type, [arg1, arg2], options)
      end
    end
  end
end
