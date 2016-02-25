require 'spec_helper'

describe 'The Runner' do

  it "is alive" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (name "test1")
          (id "t1"))
        (flow-flag "bitmap" true
          (test
            (name "test2"))
          (test-result "t1" false
            (test
              (name "test3")))))
    END

    ATP::Formatters::Basic.run(ast).should == <<-END
test1
    END
  end

  it "can enable flow flags" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (name "test1")
          (id "t1"))
        (flow-flag "bitmap" true
          (test
            (name "test2"))
          (test-result "t1" false
            (test
              (name "test3")))))
    END

    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap").should == <<-END
test1
test2
    END

  end

  it "can assume test failures" do
    ast = to_ast <<-END
      (flow
        (name "sort1")
        (test
          (name "test1")
          (id "t1")
          (on-fail
            (continue)))
        (test
          (name "test1")
          (id "t2")
          (on-fail
            (continue)))
        (flow-flag "bitmap" true
          (test
            (name "test2"))
          (test-result "t1" false
            (test
              (name "test3")))
          (test-result "t2" true
            (test
              (name "test4")))))
    END

    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap").should == <<-END
test1
test1
test2
test4
    END

    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: "t1").should == <<-END
test1
test1
test2
test3
test4
    END

    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
test1
test1
test2
test3
    END

  end

  it "can enable a job" do
    ast =
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:name, "test1"),
          s(:id, "t1")),
        s(:job, "j1", true,
          s(:test,
            s(:name, "test2"))),
        s(:job, "j2", true,
          s(:test,
            s(:name, "test3"))),
        s(:job, "j2", false,
          s(:test,
            s(:name, "test4"))),
        s(:job, ["j1", "j2"], true,
          s(:test,
            s(:name, "test5"))),
        s(:job, ["j1", "j2"], false,
          s(:test,
            s(:name, "test6"))))

    ATP::Formatters::Basic.run(ast, job: "j1").should == <<-END
test1
test2
test4
test5
    END

    ATP::Formatters::Basic.run(ast, job: "j2").should == <<-END
test1
test3
test5
    END

    ATP::Formatters::Basic.run(ast, job: "j3").should == <<-END
test1
test4
test6
    END
  end

#  it "can handle test failures" do
#    ast = to_ast <<-END
#      (flow
#        (name "sort1")
#        (test
#          (name "test1")
#          (id "t1"))
#        (test
#          (name "test1")
#          (id "t2"))
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
#test1
#test1
#test2
#test3
#test4
#    END
#
#    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: ["t1", "t2"]).should == <<-END
#test1
#test1
#test2
#test3
#    END
#
#  end

end
