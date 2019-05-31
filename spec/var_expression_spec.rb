require 'spec_helper'

describe 'Variable Expressions' do
  include ATP::FlowAPI

  before :each do
    self.atp = ATP::Program.new.flow(:sort1) 
  end

  it "can create if_true node" do
    if_true eq('ONE', 1) do
      test :test1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_true, [s(:eq, "ONE", 1)],
          s(:test,
            s(:object, "test1"))))

  end

  it "can create if_false node" do
    if_false eq('ONE', 2) do
      test :test1
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_false, [s(:eq, "ONE", 2)],
          s(:test,
            s(:object, "test1"))))

  end

  it "can translate expr into relational operator node" do
    if_true expr(:eq, 'THREE', 3) do
      test :test3
    end
    if_true expr(:lt, 'FOUR', 5) do
      test :test4lt5
    end


    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_true, [s(:eq, "THREE", 3)],
          s(:test,
            s(:object, "test3"))),
        s(:if_true, [s(:lt, "FOUR", 5)],
          s(:test,
            s(:object, "test4lt5"))))


  end

  it "can create if_true node with multiple relationals" do
    if_true expr(:and, eq('ONE', 1), eq('TWO', 2)) do
      test :test1and2
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_true, [s(:and,
        s(:eq, "ONE", 1),
        s(:eq, "TWO", 2))],
          s(:test,
            s(:object, "test1and2"))))

  end
end

