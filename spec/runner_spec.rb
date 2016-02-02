require 'spec_helper'

describe 'The Runner' do

  it "is alive" do
    ast = to_ast <<-END
      (flow
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
        (test
          (name "test1")
          (id "t1"))
        (test
          (name "test1")
          (id "t2"))
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
    ast = to_ast <<-END
      (flow
        (test
          (name "test1")
          (id "t1"))
        (job "j1"
          (test
            (name "test2")))
        (job "j2"
          (test
            (name "test3")))
        (job (not "j2")
          (test
            (name "test4")))
        (job (or "j1" "j2")
          (test
            (name "test5")))
        (job (not (or "j1" "j2"))
          (test
            (name "test6"))))
    END

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
