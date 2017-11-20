require 'spec_helper'

describe 'The adjacent if combiner' do

  include ATP::FlowAPI

  before :each do
    self.atp = ATP::Program.new.flow(:sort1) 
  end

  def ast(options = {})
    options = {
      optimization: :smt,
      add_ids: false
    }.merge(options)
    atp.ast(options)
  end

  it "works" do
    test :test1, if_flag: "SOME_FLAG"
    test :test2, unless_flag: "SOME_FLAG"

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test1")),
          s(:else,
              s(:test,
                s(:object, "test2")))))
  end

  it "should not combine if there is potential modification of the flag in either branch" do
    if_flag "SOME_FLAG" do
      test :test1
      set_flag "SOME_FLAG"
    end
    test :test2, unless_flag: "SOME_FLAG"

    ast.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test1")),
          s(:set_flag, "SOME_FLAG")),
        s(:unless_flag, "SOME_FLAG",
          s(:test,
            s(:object, "test2"))))

  end
end
