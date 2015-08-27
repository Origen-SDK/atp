require 'origen'
require_relative '../config/application.rb'
module ATP
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
  autoload :Processor, 'atp/processor'

  module AST
    autoload :Node, 'atp/ast/node'
    autoload :Builder, 'atp/ast/builder'
  end

  # Processors actually modify the AST to clean and optimize the user input
  # and to implement the flow control API
  module Processors
    autoload :Condition,    'atp/processors/condition'
    autoload :Relationship, 'atp/processors/relationship'
  end

  # Validators are run on the processed AST to check it for common errors or
  # logical issues that will prevent it being rendered to a test program format
  module Validators
    autoload :Condition, 'atp/validators/condition'
  end

  # Outputters are run on the processed AST to display the flow or to render
  # it to a different format
  module Outputters
  end
end
