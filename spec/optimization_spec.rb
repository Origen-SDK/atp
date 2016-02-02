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

  it "test 3" do
    ast = 
      s(:flow,
        s(:test,
          s(:object, "t1"),
          s(:id, "check_drb_completed")),
        s(:test_result, "check_drb_completed", false,
          s(:test,
            s(:object, "nvm_pass_rd_prb1_temp_old"),
            s(:name, "nvm_pass_rd_prb1_temp_old"),
            s(:number, 204016080),
            s(:id, "check_prb1_new"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 204),
                s(:softbin, 204))))),
        s(:test_result, "check_drb_completed", false,
          s(:test_result, "check_prb1_new", false,
            s(:test,
              s(:object, "nvm_pass_rd_prb1_temp"),
              s(:name, "nvm_pass_rd_prb1_temp"),
              s(:number, 204016100),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 204),
                  s(:softbin, 204)))))),
        s(:test_result, "check_drb_completed", false,
          s(:flow_flag, "data_collection", true,
            s(:flow_flag, "data_collection", true,
              s(:test,
                s(:object, "nvm_dist_vcg"),
                s(:name, "PostDRB"),
                s(:number, 16120),
                s(:on_fail,
                  s(:continue)))))),
        s(:flow_flag, "data_collection_all", true,
          s(:test_result, "check_drb_completed", false,
            s(:test,
              s(:object, "nvm_dist_vcg_f"),
              s(:name, "PostDRBFW"),
              s(:number, 16290),
              s(:on_fail,
                s(:continue))))),
        s(:flow_flag, "data_collection_all", true,
          s(:test_result, "check_drb_completed", false,
            s(:test,
              s(:object, "nvm_dist_vcg_t"),
              s(:name, "PostDRBTIFR"),
              s(:number, 16460),
              s(:on_fail,
                s(:continue))))),
        s(:flow_flag, "data_collection_all", true,
          s(:test_result, "check_drb_completed", false,
            s(:test,
              s(:object, "nvm_dist_vcg_u"),
              s(:name, "PostDRBUIFR"),
              s(:number, 16630),
              s(:on_fail,
                s(:continue))))))

    flow(ast).ast.should == 
      s(:flow,
        s(:test,
          s(:object, "t1"),
          s(:id, "check_drb_completed"),
          s(:on_fail,
            s(:set_run_flag, "check_drb_completed_FAILED"),
            s(:continue))),
        s(:run_flag, "check_drb_completed_FAILED", true,
          s(:test,
            s(:object, "nvm_pass_rd_prb1_temp_old"),
            s(:name, "nvm_pass_rd_prb1_temp_old"),
            s(:number, 204016080),
            s(:id, "check_prb1_new"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 204),
                s(:softbin, 204)),
              s(:set_run_flag,"check_prb1_new_FAILED"),
              s(:continue))),
          s(:run_flag, "check_prb1_new_FAILED", true,
            s(:test,
              s(:object, "nvm_pass_rd_prb1_temp"),
              s(:name, "nvm_pass_rd_prb1_temp"),
              s(:number, 204016100),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 204),
                  s(:softbin, 204))))),
          s(:flow_flag, "data_collection", true,
            s(:test,
              s(:object, "nvm_dist_vcg"),
              s(:name, "PostDRB"),
              s(:number, 16120),
              s(:on_fail,
                s(:continue)))),
          s(:flow_flag, "data_collection_all", true,
            s(:test,
              s(:object, "nvm_dist_vcg_f"),
              s(:name, "PostDRBFW"),
              s(:number, 16290),
              s(:on_fail,
                s(:continue))),
            s(:test,
              s(:object, "nvm_dist_vcg_t"),
              s(:name, "PostDRBTIFR"),
              s(:number, 16460),
              s(:on_fail,
                s(:continue))),
            s(:test,
              s(:object, "nvm_dist_vcg_u"),
              s(:name, "PostDRBUIFR"),
              s(:number, 16630),
              s(:on_fail,
                s(:continue))))))
  end

  it "embedded common rules test" do
    ast = to_ast <<-END
      (flow
        (job "j1"
          (flow_flag "bitmap" true
            (test
              (object "test1"))))
        (job "j2"
          (flow_flag "bitmap" true
            (test
              (object "test1")))))
    END

    optimized = to_ast <<-END
      (flow
        (flow_flag "bitmap" true
          (job "j1"
            (test
              (object "test1")))
          (job "j2"
            (test
              (object "test1")))))
    END

    flow(ast).ast.should == optimized
  end
end
