require 'spec_helper'

describe Flagging do
  let(:flaggable) { FlaggableModel.create(name: 'Flaggable 1') }
  let(:flagger) { FlaggerModel.create(name: 'Flagger 1') }

  describe 'attributes should be white listed' do
    it { should allow_mass_assignment_of(:flaggable) }
    it { should allow_mass_assignment_of(:flagger) }
    it { should allow_mass_assignment_of(:flag) }
  end

  describe '.ignore' do
    before(:each) do
      flagger.flag!(flaggable, :inappropriate)
    end

    it 'sets ignored attribute to true' do
      flaggable.flaggings.last.ignore
      expect(flaggable.reload.flaggings.last.ignored).to eq(true)
    end

    it 'decrements flaggings count on flaggable' do
      expect{
        flaggable.flaggings.last.ignore
      }.to change{
        flaggable.reload.flaggings_count
      }.by(-1)
    end
  end

  describe '.unignore' do
    before(:each) do
      flagger.flag!(flaggable, :inappropriate)
      flaggable.flaggings.last.update_attributes(ignored: true)
    end

    it 'sets ignored attribute to false' do
      flaggable.flaggings.last.unignore
      expect(flaggable.reload.flaggings.last.ignored).to eq(false)
    end

    it 'increments flaggings count on flaggable' do
      expect{
        flaggable.flaggings.last.unignore
      }.to change{
        flaggable.reload.flaggings_count
      }.by(1)
    end
  end

  describe '#ignore_all' do
    let!(:flagging_1) { MakeFlaggable::Flagging.create(ignored: false, flaggable: flaggable) }
    let!(:flagging_2) { MakeFlaggable::Flagging.create(ignored: false, flaggable: flaggable) }

    it 'ignores all flaggings' do
      flaggable.flaggings.ignore_all
      expect(flagging_1.reload.ignored).to eq(true)
      expect(flagging_2.reload.ignored).to eq(true)
    end
  end
end

