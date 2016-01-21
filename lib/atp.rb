require 'origen'
require_relative '../config/application.rb'

module ATP
  autoload :Program, 'atp/program'
  autoload :Flow, 'atp/flow'
  autoload :Processor, 'atp/processor'
  autoload :Validator, 'atp/validator'
  autoload :Runner, 'atp/runner'
  autoload :Formatter, 'atp/formatter'
  autoload :Parser, 'atp/parser'
  autoload :AND, 'atp/and'
  autoload :OR, 'atp/or'
  autoload :NOT, 'atp/not'

  module AST
    autoload :Node, 'atp/ast/node'
    autoload :Builder, 'atp/ast/builder'
    autoload :Factories, 'atp/ast/factories'
    autoload :Extractor, 'atp/ast/extractor'
  end

  # Processors actually modify the AST to clean and optimize the user input
  # and to implement the flow control API
  module Processors
    autoload :Condition,    'atp/processors/condition'
    autoload :Relationship, 'atp/processors/relationship'
    autoload :PreCleaner, 'atp/processors/pre_cleaner'
    autoload :PostCleaner, 'atp/processors/post_cleaner'
  end

  # Summarizers extract summary data from the given AST
  module Summarizers
  end

  # Validators are run on the processed AST to check it for common errors or
  # logical issues that will prevent it being rendered to a test program format
  module Validators
    autoload :DuplicateIDs, 'atp/validators/duplicate_ids'
    autoload :MissingIDs, 'atp/validators/missing_ids'
    autoload :Condition, 'atp/validators/condition'
  end

  # Formatters are run on the processed AST to display the flow or to render
  # it to a different format
  module Formatters
    autoload :Basic,   'atp/formatters/basic'
    autoload :Datalog, 'atp/formatters/datalog'
    autoload :Graph,   'atp/formatters/graph'
  end

  def self.or(*args)
    OR.new(*args)
  end

  def self.and(*args)
    AND.new(*args)
  end

  def self.not(*args)
    NOT.new(*args)
  end
end
