require 'spec_helper'

describe 'The AST validators' do

  def name
    "Validators spec"
  end

  it "positive and negative job conditions can't be mixed" do
    validator = ATP::Validators::Jobs.new(self)

    ast = s(:flow,
            s(:job, "p1", true,
              s(:test,
                s(:name, "test1"),
                s(:id, "t1"))),
            s(:job, "p2", false,
              s(:test,
                s(:name, "test2"),
                s(:id, "t2"))))

    validator.test_process(ast).should == false  

    ast = s(:flow,
            s(:job, "p1", true,
              s(:test,
                s(:name, "test1"),
                s(:id, "t1")),
              s(:job, "p2", false,
                s(:test,
                  s(:name, "test2"),
                  s(:id, "t2")))))

    validator.test_process(ast).should == true
  end

  it "job names can't start with a negative symbol" do
    validator = ATP::Validators::Jobs.new(self)
    ast = s(:flow,
            s(:job, "!p1", true,
              s(:test,
                s(:name, "test1"),
                s(:id, "t1"))),
            s(:job, "~p2", false,
              s(:test,
                s(:name, "test2"),
                s(:id, "t2"))))

    validator.test_process(ast).should == true
  end

end
