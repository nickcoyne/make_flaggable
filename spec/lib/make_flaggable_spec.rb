require File.expand_path('../../spec_helper', __FILE__)

describe "Make Flaggable" do
  before(:each) do
    @flaggable  = FlaggableModel.create(:name => "Flaggable 1")
    @flaggable2 = FlaggableModel.create(:name => "Flaggable 2")

    @flagger    = FlaggerModel.create(:name => "Flagger 1")
    @flagger2   = FlaggerModel.create(:name => "Flagger 2")
  end

  it "should create a flaggable instance" do
    @flaggable.class.should == FlaggableModel
    @flaggable.class.flaggable?.should == true
  end

  it "should create a flagger instance" do
    @flagger.class.should == FlaggerModel
    @flagger.class.flagger?.should == true
  end

  it "should have flags" do
    @flagger.flags.length.should == 0
    @flagger.flag!(@flaggable, :inappropriate)
    @flagger.flags.reload.length.should == 1
  end

  it "should have flags by flag name" do
    @flagger.flag!(@flaggable, :inappropriate)
    @flagger.flag!(@flaggable, :favorite)
    @flagger.flags.reload.length.should == 2
    @flagger.flags.with_flag(:favorite).length.should == 1
  end

  it "should have flags by flaggable" do
    @flagger.flag!(@flaggable, :inappropriate)
    @flagger.flag!(@flaggable, :favorite)
    @flagger.flag!(@flaggable2, :favorite)
    @flagger.flags.reload.length.should == 3
    @flagger.flags.with_flaggable(@flaggable).length.should == 2
    @flagger.flags.with_flaggable(@flaggable2).length.should == 1
  end

  describe "flagger" do
    describe "#flag" do
      it "should create a flag" do
        @flaggable.flaggings.length.should == 0
        @flagger.flag!(@flaggable, :inappropriate)
        @flaggable.flaggings.reload.length.should == 1
      end

      it "should not allow duplicate flaggings with the same flag and flaggable and throw exception" do
        @flaggable.flaggings.length.should == 0
        @flagger.flag!(@flaggable, :inappropriate)
        lambda {
          @flagger.flag!(@flaggable, :inappropriate)
        }.should raise_error(MakeFlaggable::Exceptions::AlreadyFlaggedError)
      end

      it "should not allow duplicate flaggings with the same flag and flaggable and return false" do
        @flaggable.flaggings.length.should == 0
        @flagger.flag!(@flaggable, :inappropriate)
        @flagger.flag(@flaggable, :inappropriate).should == nil
      end

      it "should remove related flaggings when destroyed" do
        @flagger.flag!(@flaggable, :inappropriate)
        @flagger2.flag!(@flaggable, :inappropriate)
        @flaggable.flaggings.count.should == 2

        @flagger.destroy
        @flaggable.flaggings.reload.count.should == 1
        @flaggable.flaggings.first.flagger.should == @flagger2

        @flagger2.destroy
        @flaggable.flaggings.reload.should be_empty
      end
    end

    describe "#unflag" do
      it "should unflag a flagging" do
        @flagger.flag!(@flaggable, :inappropriate)
        @flagger.flags.length.should == 1
        @flagger.unflag!(@flaggable, :inappropriate).should == true
        @flagger.flaggings.reload.length.should == 0
      end

      it "should unflag individual flaggings based on the flag" do
        @flagger.flag!(@flaggable, :inappropriate)
        @flagger.flag!(@flaggable, :favorite)
        @flagger.flags.length.should == 2
        @flagger.unflag!(@flaggable, :inappropriate).should == true
        @flagger.flags.reload.length.should == 1
      end

      it "normal method should return true when successfully unflagged" do
        @flagger.flag(@flaggable, :favorite)
        @flagger.unflag(@flaggable, :favorite).should == true
      end

      it "should raise error if flagger not flagged the flaggable with bang method" do
        lambda { @flagger.unflag!(@flaggable, :favorite) }.should raise_error(MakeFlaggable::Exceptions::NotFlaggedError)
      end

      it "should not raise error if flagger not flagged the flaggable with normal method" do
        lambda {
          @flagger.unflag(@flaggable, :favorite).should == false
        }.should_not raise_error(MakeFlaggable::Exceptions::NotFlaggedError)
      end
    end

    describe "#toggle_flag" do
      it "should add a flag when none exists" do
        @flaggable.flaggings.length.should == 0
        @flagger.toggle_flag(@flaggable, :inappropriate)
        @flaggable.flaggings.reload.length.should == 1
      end

      it "should remove an existing flag" do
        @flagger.flag!(@flaggable, :inappropriate)
        @flaggable.flaggings.length.should == 1
        @flagger.toggle_flag(@flaggable, :inappropriate)
        @flaggable.flaggings.reload.length.should == 0
      end

      it "should return the new flagging state" do
        @flagger.flagged?(@flaggable, :inappropriate).should == false

        @flagger.toggle_flag(@flaggable, :inappropriate).should  == true
        @flagger.flagged?(@flaggable, :inappropriate).should     == true

        @flagger.toggle_flag(@flaggable, :inappropriate).should  == false
        @flagger.flagged?(@flaggable, :inappropriate).should     == false
      end
    end

    describe "#has_flagged?" do
      it "should check if flagger has flagged the flaggable" do
        @flagger.has_flagged?(@flaggable, :favorite).should == false
        @flagger.flag!(@flaggable, :favorite)
        @flagger.has_flagged?(@flaggable, :favorite).should == true
        @flagger.unflag!(@flaggable, :favorite)
        @flagger.has_flagged?(@flaggable, :favorite).should == false
      end

      it "should check if flagger has flagged the flaggable with any flag" do
        @flagger.has_flagged?(@flaggable).should == false
        @flagger.flag!(@flaggable, :favorite)
        @flagger.has_flagged?(@flaggable).should == true
        @flagger.unflag!(@flaggable, :favorite)
        @flagger.has_flagged?(@flaggable).should == false
      end
    end

    describe "#find_last_flag_for" do
      it "should fetch the most recent flag the flagger has made on the flaggable" do
        @flagger.flagged?(@flaggable, :favorite).should == false
        @flagger.flagged?(@flaggable, :inappropriate).should == false
        @flagger.flag!(@flaggable, :favorite)
        @flagger.flag!(@flaggable, :inappropriate)
        @flagger.find_last_flag_for(@flaggable).flag.should == "inappropriate"
      end

      it "should return nil when the flagger has made no flags on the flaggable" do
        @flagger.flagged?(@flaggable).should == false

        @flagger.find_last_flag_for(@flagger).should == nil
      end
    end

    describe "#find_all_flags_for" do
      it "should fetch all flags the flagger has made on the flaggable" do
        @flagger.flagged?(@flaggable, :favorite).should == false
        @flagger.flagged?(@flaggable, :inappropriate).should == false
        @flagger.flag!(@flaggable, :favorite)
        @flagger.flag!(@flaggable, :inappropriate)
        flag_types = @flagger.find_all_flags_for(@flaggable).map(&:flag)
        flag_types.should include("inappropriate")
        flag_types.should include("favorite")
      end

      it "should return an empty ActiveRecord relation when the flagger has made no flags on the flaggable" do
        @flagger.flagged?(@flaggable).should == false
        @flagger.find_all_flags_for(@flaggable).should == []
      end
    end
  end

  describe "flaggable" do
    it "should have flaggings" do
      @flaggable.flaggings.length.should == 0
      @flagger.flag!(@flaggable, :favorite)
      @flaggable.flaggings.reload.length.should == 1
    end

    it "should check if flaggable is flagged" do
      @flaggable.flagged?.should == false
      @flagger.flag!(@flaggable, :favorite)
      @flaggable.flagged?.should == true
      @flagger.unflag!(@flaggable, :favorite)
      @flaggable.flagged?.should == false
    end

    it "should remove related flaggings when destroyed" do
      @flagger.flag!(@flaggable, :inappropriate)
      @flagger.flag!(@flaggable2, :inappropriate)

      @flagger.flags.count.should == 2

      @flaggable.destroy
      @flagger.flags.reload.count.should == 1
      @flagger.flags.first.flaggable.should == @flaggable2

      @flaggable2.destroy
      @flagger.flags.reload.should be_empty
    end
  end
end
