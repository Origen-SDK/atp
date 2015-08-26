require 'spec_helper'
require 'ast'

describe 'The Condition Optimizer' do
  include AST::Sexp

  it "wraps adjacent nodes that share the same conditions" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, id: :t1
    flow.test :test2, conditions: { if_enabled: "bitmap" }
    flow.test :test3, conditions: { if_enabled: "bitmap", if_failed: :t1 }
    flow.raw.should ==
      s(:flow,
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2"))),
        s(:test_result, :t1, false,
          s(:flow_flag, "bitmap", true,
            s(:test,
              s(:name, "test3")))))
    p = ATP::Processor::ConditionOptimizer.new
    #puts p.process(flow.raw).inspect
    p.process(flow.raw).should ==
      s(:flow,
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2")),
          s(:test_result, :t1, false,
            s(:test,
              s(:name, "test3")))))
  end
end
