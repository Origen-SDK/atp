require 'spec_helper'
require 'ast'

describe 'The builder API' do
  include AST::Sexp

  it 'is alive' do
    prog = ATP::Program.new
    flow = prog.flow(:sort1)
    flow.program.should == prog
    flow.ast.should be
  end

  it "tests can be added" do
    flow = ATP::Program.new.flow(:sort1) 
    flow.test :test1, on_fail: { bin: 5 }
    flow.test :test2, on_fail: { bin: 6, continue: true }
    flow.ast.should ==
      s(:flow,
        s(:test, s(:name, "test1"), s(:on_fail, s(:bin, 5)), s(:on_pass)),
        s(:test, s(:name, "test2"), s(:on_fail, s(:bin, 6), s(:continue)), s(:on_pass))
       )
  end
end
