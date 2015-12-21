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
        (flow-flag "bitmap" true
          (test
            (name "test2"))
          (test-result "t1" false
            (test
              (name "test3")))))
    END

    ATP::Formatters::Basic.run(ast, flow_flag: "bitmap", failed_test_ids: "t1").should == <<-END
test1
test2
test3
    END

  end

end
