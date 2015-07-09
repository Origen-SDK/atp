require 'spec_helper'
require 'ast'

describe 'The AST processors' do
  include AST::Sexp

  it "the base processor returns the same AST" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, on_fail: { bin: 5 }
    flow.test :test2, on_fail: { bin: 6, continue: true }
    ATP::Processor::Base.new.process(flow.ast).should == flow.ast
  end

  it "finds IDs of tests that have dependents" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, on_fail: { bin: 5 }, id: :t1
    flow.test :test2, on_fail: { bin: 5 }, id: :t2
    flow.test :test3, on_fail: { bin: 5 }, id: :t3, if_failed: :t2
    flow.test :test4, on_fail: { bin: 5 }, id: :t4, if_failed: :t2
    flow.test :test5, on_fail: { bin: 5 }, id: :t5
    flow.test :test6, on_fail: { bin: 5 }, id: :t6, if_failed: :t4
    p = ATP::Processor::Base.new
    p.process(flow.ast)
    p.tests_with_dependents.should == [:t2, :t4]
  end
end
