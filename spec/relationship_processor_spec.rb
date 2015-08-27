require 'spec_helper'

describe 'The Relationship Processor' do

  it "updates both sides of the relationship" do
    ast =
      s(:flow,
        s(:test,
          s(:name, "test1"),
          s(:id, :t1)),
        s(:test,
          s(:name, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:bin, 10))),
        s(:test_result, :t1, true,
          s(:test,
            s(:name, "test3"))),
        s(:test_result, :t2, true,
          s(:test,
            s(:name, "test4"))),
        s(:test_result, :t2, false,
          s(:test,
            s(:name, "test5"))))
    p = ATP::Processors::Relationship.new
    #puts p.process(ast).inspect
    p.process(ast).should ==
      s(:flow,
        s(:test,
          s(:name, "test1"),
          s(:id, :t1),
          s(:on_pass,
            s(:set_run_flag, "t1_passed"))),
        s(:test,
          s(:name, "test2"),
          s(:id, :t2),
          s(:on_fail,
            s(:bin, 10),
            s(:set_run_flag, "t2_failed"),
            s(:continue)),
          s(:on_pass,
            s(:set_run_flag, "t2_passed"))),
        s(:run_flag, "t1_passed", true,
          s(:test,
            s(:name, "test3"))),
        s(:run_flag, "t2_passed", true,
          s(:test,
            s(:name, "test4"))),
        s(:run_flag, "t2_failed", true,
          s(:test,
            s(:name, "test5"))))

  end
end
