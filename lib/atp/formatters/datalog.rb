module ATP
  module Formatters
    # Outputs the given AST to something resembling an ATE datalog,
    # this can optionally be rendered to a file or the console (the default).
    class Datalog < Formatter
      def on_flow(node)
        puts 'Number     Result   Test Name                 Pin            Channel   Low            Measured       High           Force          Loc'
        process_all(node.children)
      end

      def on_test(node)
        t = node.to_h
        str = "#{t[:number]}".ljust(11)
        str += "#{t[:failed] ? 'FAIL' : 'PASS'}".ljust(9)
        str += "#{t[:name][0]}".ljust(20)
        puts str
      end
    end
  end
end
