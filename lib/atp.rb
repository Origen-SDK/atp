require 'origen'
require_relative '../config/application.rb'
module ATP
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
  autoload :Processor, 'atp/processor'
  autoload :Runner, 'atp/runner'
  autoload :Outputter, 'atp/outputter'
  autoload :Parser, 'atp/parser'

  module AST
    autoload :Node, 'atp/ast/node'
    autoload :Builder, 'atp/ast/builder'
    autoload :Factories, 'atp/ast/factories'
  end

  # Processors actually modify the AST to clean and optimize the user input
  # and to implement the flow control API
  module Processors
    autoload :Condition,    'atp/processors/condition'
    autoload :Relationship, 'atp/processors/relationship'
    autoload :PreCleaner, 'atp/processors/pre_cleaner'
    autoload :PostCleaner, 'atp/processors/post_cleaner'
  end

  # Summerizers extract summary data from the given AST
  module Summarizers
  end

  # Validators are run on the processed AST to check it for common errors or
  # logical issues that will prevent it being rendered to a test program format
  module Validators
    autoload :Condition, 'atp/validators/condition'
  end

  # Formatters are run on the processed AST to display the flow or to render
  # it to a different format
  module Formatter
    autoload :Datalog, 'atp/formatters/datalog'
  end
end
