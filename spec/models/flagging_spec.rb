require 'spec_helper'

describe Flagging do
  describe 'attributes should be white listed' do
    it { should allow_mass_assignment_of(:flaggable) }
    it { should allow_mass_assignment_of(:flagger) }
    it { should allow_mass_assignment_of(:flag) }
  end

  describe '.ignore' do
    let(:flagging) { MakeFlaggable::Flagging.create(ignored: false) }

    it 'sets ignored attribute to true' do
      flagging.ignore
      flagging.reload
      expect(flagging.ignored).to eq(true)
    end
  end

  describe '.unignore' do
    let(:flagging) { MakeFlaggable::Flagging.create(ignored: true) }

    it 'sets ignored attribute to true' do
      flagging.unignore
      flagging.reload
      expect(flagging.ignored).to eq(false)
    end
  end

  describe '#ignore_all' do
    let(:flaggable) { FlaggableModel.create(name: 'Flaggable 1') }
    let!(:flagging_1) { MakeFlaggable::Flagging.create(ignored: false, flaggable: flaggable) }
    let!(:flagging_2) { MakeFlaggable::Flagging.create(ignored: false, flaggable: flaggable) }

    it 'ignores all flaggings' do
      flaggable.flaggings.ignore_all
      expect(flagging_1.reload.ignored).to eq(true)
      expect(flagging_2.reload.ignored).to eq(true)
    end
  end
end

