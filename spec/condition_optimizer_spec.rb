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
    p = ATP::Optimizers::Condition.new
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

  it "wraps nested conditions" do
    # You can't really generate a flow AST like this from the exposed API, but
    # just to check it will deal with them in case it is possible in future
    ast =
      s(:flow,
        s(:test,
          s(:name, "test1")),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2"))),
        s(:flow_flag, "bitmap", true,
          s(:flow_flag, "x", true,
            s(:test,
              s(:name, "test3"))),
          s(:flow_flag, "x", true,
            s(:flow_flag, "y", true,
              s(:test,
                s(:name, "test4"))))))
    p = ATP::Optimizers::Condition.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:test,
          s(:name, "test1")),
        s(:flow_flag, "bitmap", true,
          s(:test,
            s(:name, "test2")),
          s(:flow_flag, "x", true,
            s(:test,
              s(:name, "test3")),
            s(:flow_flag, "y", true,
              s(:test,
                s(:name, "test4"))))))
  end
end
