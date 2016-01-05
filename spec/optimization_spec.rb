require 'spec_helper'

# These are integration tests of all flow AST processors based
# on some real life examples

describe 'AST optimization' do

  def flow(ast)
    f = ATP::Flow.new(self)
    f.send("raw=", ast)
    f
  end

  it "test 1" do
    ast = to_ast <<-END
      (flow
        (log "Another group-level dependencies test based on a real life use case")
        (test
          (object "gt1")
          (on-fail
            (bin 90)))
        (group
          (name "gt_grp1")
          (id "gt_grp1")
          (members
            (test
              (object "gt_grp1_test1")
              (id "gt_grp1")
              (on-fail
                (bin 90)))
            (test
              (object "gt_grp1_test2")
              (id "gt_grp1")
              (on-fail
                (bin 90)))))
        (test-result "gt_grp1" false
          (test
            (object "gt2")
            (on-fail
              (bin 90))))
        (test-result "gt_grp1" false
          (group
            (name "gt_grp2")
            (id "gt_grp2")
            (members
              (test-result "gt_grp1" false
                (test
                  (object "gt_grp2_test1")
                  (id "gt_grp2")
                  (on-fail
                    (bin 90))))
              (test-result "gt_grp1" false
                (test
                  (object "gt_grp2_test2")
                  (id "gt_grp2")
                  (on-fail
                    (bin 90)))))))
        (test-result "gt_grp2" false
          (test
            (object "gt3")
            (on-fail
              (bin 90)))))
    END

    optimized = to_ast <<-END
      (flow
        (log "Another group-level dependencies test based on a real life use case")
        (test
          (object "gt1")
          (on-fail
            (bin 90)))
        (group
          (name "gt_grp1")
          (id "gt_grp1")
          (members
            (test
              (object "gt_grp1_test1")
              (on-fail
                (bin 90)))
            (test
              (object "gt_grp1_test2")
              (on-fail
                (bin 90))))
          (on-fail
            (set-run-flag "gt_grp1_FAILED")
            (continue)))
        (run-flag "gt_grp1_FAILED" true
          (test
            (object "gt2")
            (on-fail
              (bin 90)))
          (group
            (name "gt_grp2")
            (id "gt_grp2")
            (members
              (test
                (object "gt_grp2_test1")
                (on-fail
                  (bin 90)))
              (test
                (object "gt_grp2_test2")
                (on-fail
                  (bin 90))))
            (on-fail
              (set-run-flag "gt_grp2_FAILED")
              (continue))))
        (run-flag "gt_grp2_FAILED" true
          (test
            (object "gt3")
            (on-fail
              (bin 90)))))
    END

    flow(ast).ast.should == optimized
  end

  it "test 2" do
    ast = to_ast <<-END
      (flow
        (log "Test that nested groups work")
        (group
          (name "level1")
          (members
            (test
              (object "lev1_test1")
              (on-fail
                (bin 5)))
            (test
              (object "lev1_test2")
              (on-fail
                (bin 5)))
            (test
              (object "lev1_test3")
              (id "l1t3")
              (on-fail
                (bin 10)))
            (test-result "l1t3" false
              (test
                (object "lev1_test4")
                (on-fail
                  (bin 12))))
            (test
              (object "lev1_test5")
              (id "l1t5")
              (on-fail
                (bin 12)))
            (group
              (name "level2")
              (members
                (test
                  (object "lev2_test1")
                  (on-fail
                    (bin 5)))
                (test
                  (object "lev2_test2")
                  (on-fail
                    (bin 5)))
                (test
                  (object "lev2_test3")
                  (id "l2t3")
                  (on-fail
                    (bin 10)))
                (test-result "l2t3" false
                  (test
                    (object "lev2_test4")
                    (on-fail
                      (bin 12))))
                (test-result "l1t5" false
                  (test
                    (object "lev2_test5")
                    (on-fail
                      (bin 12)))))))))
    END

    optimized = to_ast <<-END
      (flow
        (log "Test that nested groups work")
        (group
          (name "level1")
          (members
            (test
              (object "lev1_test1")
              (on-fail
                (bin 5)))
            (test
              (object "lev1_test2")
              (on-fail
                (bin 5)))
            (test
              (object "lev1_test3")
              (id "l1t3")
              (on-fail
                (bin 10)
                (set-run-flag "l1t3_FAILED")
                (continue)))
            (run-flag "l1t3_FAILED" true
              (test
                (object "lev1_test4")
                (on-fail
                  (bin 12))))
            (test
              (object "lev1_test5")
              (id "l1t5")
              (on-fail
                (bin 12)
                (set-run-flag "l1t5_FAILED")
                (continue)))
            (group
              (name "level2")
              (members
                (test
                  (object "lev2_test1")
                  (on-fail
                    (bin 5)))
                (test
                  (object "lev2_test2")
                  (on-fail
                    (bin 5)))
                (test
                  (object "lev2_test3")
                  (id "l2t3")
                  (on-fail
                    (bin 10)
                    (set-run-flag "l2t3_FAILED")
                    (continue)))
                (run-flag "l2t3_FAILED" true
                  (test
                    (object "lev2_test4")
                    (on-fail
                      (bin 12))))
                (run-flag "l1t5_FAILED" true
                  (test
                    (object "lev2_test5")
                    (on-fail
                      (bin 12)))))))))
    END

    flow(ast).ast.should == optimized
  end

end
