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
    flow.test :test1, bin: 5
    flow.test :test2, bin: 6, continue: true
    flow.ast.should ==
      s(:flow,
        s(:test, s(:name, "test1"), s(:bin, 5)),
        s(:test, s(:name, "test2"), s(:bin, 6), s(:continue)))
  end
end
