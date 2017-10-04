require 'spec_helper'

describe 'The Runner' do
  include ATP::FlowAPI

  before :each do
    self.flow = ATP::Program.new.flow(:sort1) 
  end

  it "is alive" do
    test :test1, id: :t1
    if_enabled :bitmap do
      test :test2
      test :test3, if_failed: :t1
    end
    
    flow.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "test1"),
          s(:id, "t1")),
        s(:if_enabled, "bitmap",
          s(:test,
            s(:object, "test2")),
          s(:if_failed, "t1",
            s(:test,
              s(:object, "test3")))))

    ATP::Formatters::Basic.run(flow.ast).should == <<-END
test1
    END
  end

#  it "can enable flow flags" do
#    ast = to_ast <<-END
#      (flow
#        (name "sort1")
#        (test
#          (name "test1")
#          (id "t1"))
#        (flow-flag "bitmap" true
#          (test
#            (name "test2"))
#          (test-result "t1" false
#            (test
#              (name "test3")))))
#    END
#
#    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap").should == <<-END
#test1
#test2
#    END
#
#  end
#
#  it "can assume test failures" do
#    ast = to_ast <<-END
#      (flow
#        (name "sort1")
#        (test
#          (name "test1")
#          (id "t1")
#          (on-fail
#            (continue)))
#        (test
#          (name "test1")
#          (id "t2")
#          (on-fail
#            (continue)))
#        (flow-flag "bitmap" true
#          (test
#            (name "test2"))
#          (test-result "t1" false
#            (test
#              (name "test3")))
#          (test-result "t2" true
#            (test
#              (name "test4")))))
#    END
#
#    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap").should == <<-END
#test1
#test1
#test2
#test4
#    END
#
#    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: "t1").should == <<-END
#test1 F
#test1
#test2
#test3
#test4
#    END
#
#    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
#test1 F
#test1 F
#test2
#test3
#    END
#
#  end
#
#  it "can enable a job" do
#    ast =
#      s(:flow,
#        s(:name, "sort1"),
#        s(:test,
#          s(:name, "test1"),
#          s(:id, "t1")),
#        s(:job, "j1", true,
#          s(:test,
#            s(:name, "test2"))),
#        s(:job, "j2", true,
#          s(:test,
#            s(:name, "test3"))),
#        s(:job, "j2", false,
#          s(:test,
#            s(:name, "test4"))),
#        s(:job, ["j1", "j2"], true,
#          s(:test,
#            s(:name, "test5"))),
#        s(:job, ["j1", "j2"], false,
#          s(:test,
#            s(:name, "test6"))))
#
#    ATP::Formatters::Basic.run(ast, job: "j1").should == <<-END
#test1
#test2
#test4
#test5
#    END
#
#    ATP::Formatters::Basic.run(ast, job: "j2").should == <<-END
#test1
#test3
#test5
#    END
#
#    ATP::Formatters::Basic.run(ast, job: "j3").should == <<-END
#test1
#test4
#test6
#    END
#  end
#
#  it 'can handle a speed binning flow' do
#    ast =
#      s(:flow,                                                                        
#        s(:name, "prb1"),                                                             
#        s(:log, "Speed binning example bug from video 5"),
#        s(:group,
#          s(:name, "200Mhz Tests"),
#          s(:id, "g200"),
#          s(:test,
#            s(:object, {"Test"=>"test200_1"})),
#          s(:test,
#            s(:object, {"Test"=>"test200_2"})),
#          s(:test,
#            s(:object, {"Test"=>"test200_3"})),
#          s(:on_fail,
#            s(:set_run_flag, "g200_FAILED"),
#            s(:continue))),
#        s(:run_flag, "g200_FAILED", true,
#          s(:group,
#            s(:name, "100Mhz Tests"),
#            s(:id, "g100"),
#            s(:test,
#              s(:object, {"Test"=>"test100_1"}),
#              s(:on_fail,
#                s(:set_result, "fail",
#                  s(:bin, 5)))),
#            s(:test,
#              s(:object, {"Test"=>"test100_2"}),
#              s(:on_fail,
#                s(:set_result, "fail",
#                  s(:bin, 5)))),
#            s(:test,
#              s(:object, {"Test"=>"test100_3"}),
#              s(:on_fail,
#                s(:set_result, "fail",
#                  s(:bin, 5)))),
#            s(:on_fail,
#              s(:set_run_flag, "g100_RAN")),
#            s(:on_pass,
#              s(:set_run_flag, "g100_RAN")))),
#        s(:run_flag, "g100_RAN", true,
#          s(:set_result, "pass",
#            s(:bin, 2))),
#        s(:set_result, "pass",
#          s(:bin, 1),
#          s(:softbin, 1),
#          s(:bin_description, "Good die!")))
#      
#    ATP::Formatters::Basic.run(ast).should == <<-END
#test200_1
#test200_2
#test200_3
#PASS 1 1
#    END
#
#    ATP::Formatters::Basic.run(ast, failed_test_ids: ['t1']).should == <<-END
#test200_1 F
#test200_2
#test200_3
#test100_1
#test100_2
#test100_3
#PASS 2
#    END
#
#    ATP::Formatters::Basic.run(ast, failed_test_ids: ['t1','t5']).should == <<-END
#test200_1 F
#test200_2
#test200_3
#test100_1
#test100_2 F
#FAIL 5
#    END
#  end 
#
##  it "can handle test failures" do
##    ast = to_ast <<-END
##      (flow
##        (name "sort1")
##        (test
##          (name "test1")
##          (id "t1"))
##        (test
##          (name "test1")
##          (id "t2"))
##        (flow-flag "bitmap" true
##          (test
##            (name "test2"))
##          (test-result "t1" false
##            (test
##              (name "test3")))
##          (test-result "t2" true
##            (test
##              (name "test4")))))
##    END
##
##    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap").should == <<-END
##test1
##test1
##test2
##test4
##    END
##
##    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: "t1").should == <<-END
##test1
##test1
##test2
##test3
##test4
##    END
##
##    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
##test1
##test1
##test2
##test3
##    END
##
##  end

end
