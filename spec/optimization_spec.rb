require 'spec_helper'

# These are integration tests of all flow AST processors based
# on some real life examples

describe 'AST optimization' do

  include ATP::FlowAPI

  before :each do
    self.atp = ATP::Program.new.flow(:sort1) 
  end

  it "test 1" do
    log "Another group-level dependencies test based on a real life use case"
    test :gt1, bin: 90
    group :gt_grp1, id: :gt_grp1 do
      test :gt_grp1_test1, bin: 90
      test :gt_grp1_test2, bin: 90
    end
    test :gt2, bin: 90, if_failed: :gt_grp1
    group :gt_grp2, id: :gt_grp2, if_failed: :gt_grp1 do
      test :gt_grp2_test1, bin: 90
      test :gt_grp2_test2, bin: 90
    end
    test :gt3, if_failed: :gt_grp2

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Another group-level dependencies test based on a real life use case"),
        s(:test,
          s(:object, "gt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 90)))),
        s(:group,
          s(:name, "gt_grp1"),
          s(:id, "gt_grp1"),
          s(:test,
            s(:object, "gt_grp1_test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90)))),
          s(:test,
            s(:object, "gt_grp1_test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90))))),
        s(:if_failed, "gt_grp1",
          s(:test,
            s(:object, "gt2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90))))),
        s(:if_failed, "gt_grp1",
          s(:group,
            s(:name, "gt_grp2"),
            s(:id, "gt_grp2"),
            s(:test,
              s(:object, "gt_grp2_test1"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 90)))),
            s(:test,
              s(:object, "gt_grp2_test2"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 90)))))),
        s(:if_failed, "gt_grp2",
          s(:test,
            s(:object, "gt3"))))

    atp.ast(optimization: :full, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Another group-level dependencies test based on a real life use case"),
        s(:test,
          s(:object, "gt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 90)))),
        s(:group,
          s(:name, "gt_grp1"),
          s(:id, "gt_grp1"),
          s(:test,
            s(:object, "gt_grp1_test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90)))),
          s(:test,
            s(:object, "gt_grp1_test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90)))),
          s(:on_fail,
            s(:set_flag, "gt_grp1_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, "gt_grp1_FAILED",
          s(:test,
            s(:object, "gt2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 90)))),
          s(:group,
            s(:name, "gt_grp2"),
            s(:id, "gt_grp2"),
            s(:test,
              s(:object, "gt_grp2_test1"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 90)))),
            s(:test,
              s(:object, "gt_grp2_test2"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 90)))),
            s(:on_fail,
              s(:set_flag, "gt_grp2_FAILED", "auto_generated"),
              s(:continue)))),
        s(:if_flag, "gt_grp2_FAILED",
          s(:test,
            s(:object, "gt3"))))
  end

  it "test 2" do
    log "Test that nested groups work"
    group "level1" do
      test :lev1_test1, bin: 5
      test :lev1_test2, bin: 5
      test :lev1_test3, bin: 10, id: :l1t3
      test :lev1_test4, bin: 12, if_failed: :l1t3
      test :lev1_test5, bin: 12, id: :l1t5
      group "level2" do
        test :lev2_test1, bin: 5
        test :lev2_test2, bin: 5
        test :lev2_test3, bin: 10, id: :l2t3
        test :lev2_test4, bin: 12, if_failed: :l2t3
        test :lev2_test5, bin: 12, if_failed: :l1t5
      end
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test that nested groups work"),
        s(:group,
          s(:name, "level1"),
          s(:test,
            s(:object, "lev1_test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5)))),
          s(:test,
            s(:object, "lev1_test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5)))),
          s(:test,
            s(:object, "lev1_test3"),
            s(:id, "l1t3"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 10)))),
          s(:if_failed, "l1t3",
            s(:test,
              s(:object, "lev1_test4"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 12))))),
          s(:test,
            s(:object, "lev1_test5"),
            s(:id, "l1t5"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 12)))),
          s(:group,
            s(:name, "level2"),
            s(:test,
              s(:object, "lev2_test1"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5)))),
            s(:test,
              s(:object, "lev2_test2"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5)))),
            s(:test,
              s(:object, "lev2_test3"),
              s(:id, "l2t3"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 10)))),
            s(:if_failed, "l2t3",
              s(:test,
                s(:object, "lev2_test4"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))))),
            s(:if_failed, "l1t5",
              s(:test,
                s(:object, "lev2_test5"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))))))))

    atp.ast(optimization: :full, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test that nested groups work"),
        s(:group,
          s(:name, "level1"),
          s(:test,
            s(:object, "lev1_test1"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5)))),
          s(:test,
            s(:object, "lev1_test2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 5)))),
          s(:test,
            s(:object, "lev1_test3"),
            s(:id, "l1t3"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 10)),
              s(:set_flag, "l1t3_FAILED", "auto_generated"),
              s(:continue))),
          s(:if_flag, "l1t3_FAILED",
            s(:test,
              s(:object, "lev1_test4"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 12))))),
          s(:test,
            s(:object, "lev1_test5"),
            s(:id, "l1t5"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 12)),
              s(:set_flag, "l1t5_FAILED", "auto_generated"),
              s(:continue))),
          s(:group,
            s(:name, "level2"),
            s(:test,
              s(:object, "lev2_test1"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5)))),
            s(:test,
              s(:object, "lev2_test2"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 5)))),
            s(:test,
              s(:object, "lev2_test3"),
              s(:id, "l2t3"),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 10)),
                s(:set_flag, "l2t3_FAILED", "auto_generated"),
                s(:continue))),
            s(:if_flag, "l2t3_FAILED",
              s(:test,
                s(:object, "lev2_test4"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))))),
            s(:if_flag, "l1t5_FAILED",
              s(:test,
                s(:object, "lev2_test5"),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))))))))
  end

  it "test 3" do
    test :t1, id: :check_drb_completed
    test :nvm_pass_rd_prb1_temp_old, name: :nvm_pass_rd_prb1_temp_old, number: 204016080, id: :check_prb1_new,
                                     bin: 204, softbin: 204, if_failed: :check_drb_completed
    if_failed :check_drb_completed do
      test :nvm_pass_rd_prb1_temp, name: :nvm_pass_rd_prb1_temp, number: 204016100,
                                       bin: 204, softbin: 204, if_failed: :check_prb1_new
    end
    if_failed :check_drb_completed do
      if_enabled :data_collection do
        test :nvm_dist_vcg, name: "PostDRB", number: 16120, continue: true, if_enabled: :data_collection
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_f, name: "PostDRBFW", number: 16290, continue: true
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_t, name: "PostDRBTIFR", number: 16460, continue: true
      end
    end
    if_enabled :data_collection_all do
      if_failed :check_drb_completed do
        test :nvm_dist_vcg_u, name: "PostDRBUIFR", number: 16630, continue: true
      end
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "t1"),
          s(:id, "check_drb_completed")),
        s(:if_failed, "check_drb_completed",
          s(:test,
            s(:object, "nvm_pass_rd_prb1_temp_old"),
            s(:name, "nvm_pass_rd_prb1_temp_old"),
            s(:number, 204016080),
            s(:id, "check_prb1_new"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 204),
                s(:softbin, 204))))),
        s(:if_failed, "check_drb_completed",
          s(:if_failed, "check_prb1_new",
            s(:test,
              s(:object, "nvm_pass_rd_prb1_temp"),
              s(:name, "nvm_pass_rd_prb1_temp"),
              s(:number, 204016100),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 204),
                  s(:softbin, 204)))))),
        s(:if_failed, "check_drb_completed",
          s(:if_enabled, "data_collection",
            s(:if_enabled, "data_collection",
              s(:test,
                s(:object, "nvm_dist_vcg"),
                s(:name, "PostDRB"),
                s(:number, 16120),
                s(:on_fail,
                  s(:continue)))))),
        s(:if_enabled, "data_collection_all",
          s(:if_failed, "check_drb_completed",
            s(:test,
              s(:object, "nvm_dist_vcg_f"),
              s(:name, "PostDRBFW"),
              s(:number, 16290),
              s(:on_fail,
                s(:continue))))),
        s(:if_enabled, "data_collection_all",
          s(:if_failed, "check_drb_completed",
            s(:test,
              s(:object, "nvm_dist_vcg_t"),
              s(:name, "PostDRBTIFR"),
              s(:number, 16460),
              s(:on_fail,
                s(:continue))))),
        s(:if_enabled, "data_collection_all",
          s(:if_failed, "check_drb_completed",
            s(:test,
              s(:object, "nvm_dist_vcg_u"),
              s(:name, "PostDRBUIFR"),
              s(:number, 16630),
              s(:on_fail,
                s(:continue))))))

    atp.ast(optimization: :full, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:test,
          s(:object, "t1"),
          s(:id, "check_drb_completed"),
          s(:on_fail,
            s(:set_flag, "check_drb_completed_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, "check_drb_completed_FAILED",
          s(:test,
            s(:object, "nvm_pass_rd_prb1_temp_old"),
            s(:name, "nvm_pass_rd_prb1_temp_old"),
            s(:number, 204016080),
            s(:id, "check_prb1_new"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 204),
                s(:softbin, 204)),
              s(:set_flag, "check_prb1_new_FAILED", "auto_generated"),
              s(:continue))),
          s(:if_flag, "check_prb1_new_FAILED",
            s(:test,
              s(:object, "nvm_pass_rd_prb1_temp"),
              s(:name, "nvm_pass_rd_prb1_temp"),
              s(:number, 204016100),
              s(:on_fail,
                s(:set_result, "fail",
                  s(:bin, 204),
                  s(:softbin, 204))))),
          s(:if_enabled, "data_collection",
            s(:test,
              s(:object, "nvm_dist_vcg"),
              s(:name, "PostDRB"),
              s(:number, 16120),
              s(:on_fail,
                s(:continue)))),
          s(:if_enabled, "data_collection_all",
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
    if_job :j1 do
      test :test1, if_enabled: :bitmap
    end
    if_job :j2 do
      test :test2, if_enabled: :bitmap
    end

    atp.raw.should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_job, "j1",
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test1")))),
        s(:if_job, "j2",
          s(:if_enabled, "bitmap",
            s(:test,
              s(:object, "test2")))))

    atp.ast(optimization: :full, add_ids: false).should ==
      s(:flow,
        s(:name, "sort1"),
        s(:if_enabled, "bitmap",
          s(:if_job, "j1",
            s(:test,
              s(:object, "test1"))),
          s(:if_job, "j2",
              s(:test,
                s(:object, "test2")))))
  end

  it 'test case from origen_testers' do
    log "Test nested conditions on a group"
    test :test1, name: :nt1, number: 0, id: :nt1, bin: 10
    test :test2, name: :nt2, number: 0, id: :nt2, bin: 11, if_failed: :nt1
    if_passed :nt2 do
      group "ntg1", id: :ntg1 do
        test :test3, name: :nt3, number: 0, bin: 12, if_failed: :nt1
      end
    end
    group "ntg2", id: :ntg2, if_failed: :nt2 do
      test :test4, name: :nt4, number: 0, bin: 13, if_failed: :nt1
    end

    atp.raw.should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test nested conditions on a group"),
        s(:test,
          s(:object, "test1"),
          s(:name, "nt1"),
          s(:number, 0),
          s(:id, "nt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)))),
        s(:if_failed, "nt1",
          s(:test,
            s(:object, "test2"),
            s(:name, "nt2"),
            s(:number, 0),
            s(:id, "nt2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 11))))),
        s(:if_passed, "nt2",
          s(:group,
            s(:name, "ntg1"),
            s(:id, "ntg1"),
            s(:if_failed, "nt1",
              s(:test,
                s(:object, "test3"),
                s(:name, "nt3"),
                s(:number, 0),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12))))))),
        s(:if_failed, "nt2",
          s(:group,
            s(:name, "ntg2"),
            s(:id, "ntg2"),
            s(:if_failed, "nt1",
              s(:test,
                s(:object, "test4"),
                s(:name, "nt4"),
                s(:number, 0),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 13))))))))

    atp.ast(optimization: :full, add_ids: false).should == 
      s(:flow,
        s(:name, "sort1"),
        s(:log, "Test nested conditions on a group"),
        s(:test,
          s(:object, "test1"),
          s(:name, "nt1"),
          s(:number, 0),
          s(:id, "nt1"),
          s(:on_fail,
            s(:set_result, "fail",
              s(:bin, 10)),
            s(:set_flag, "nt1_FAILED", "auto_generated"),
            s(:continue))),
        s(:if_flag, "nt1_FAILED",
          s(:test,
            s(:object, "test2"),
            s(:name, "nt2"),
            s(:number, 0),
            s(:id, "nt2"),
            s(:on_fail,
              s(:set_result, "fail",
                s(:bin, 11)),
              s(:continue),
              s(:set_flag, "nt2_FAILED", "auto_generated")),
            s(:on_pass,
              s(:set_flag, "nt2_PASSED", "auto_generated"))),
          s(:if_flag, "nt2_PASSED",
            s(:group,
              s(:name, "ntg1"),
              s(:id, "ntg1"),
              s(:test,
                s(:object, "test3"),
                s(:name, "nt3"),
                s(:number, 0),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 12)))))),
          s(:if_flag, "nt2_FAILED",
            s(:group,
              s(:name, "ntg2"),
              s(:id, "ntg2"),
              s(:test,
                s(:object, "test4"),
                s(:name, "nt4"),
                s(:number, 0),
                s(:on_fail,
                  s(:set_result, "fail",
                    s(:bin, 13))))))))
  end
end
