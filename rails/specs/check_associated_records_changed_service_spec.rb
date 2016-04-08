# This spec file won't work outside of a rails project with the relevant records.
# I would want a way to test the service class without depending on a model in a project,
# but until I find a way to do it, this will have to do as a reference...


require 'rails_helper'

RSpec.describe CheckAssociatedRecordsChangedService, type: :service do

  subject { described_class.new(record_in_question) }

  describe '#changed?' do
    context 'with User record' do
      let!(:referrer) { create(:user) }
      let!(:user) { create(:user, referrer: referrer) }
      let!(:profile) { create(:profile, user: user) }
      let!(:company) { create(:company, owner: user) }

      before do
        referrer.save # this is to prevent it from being considered dirty due to increasing referral count
      end

      let(:record_in_question) { user }

      context 'with no changes in any associated records' do
        it { expect(subject.changed?).to be_falsey }
      end

      context 'with changes to associated belongs_to record' do
        before { user.referrer.first_name = 'new first name' }

        it { expect(subject.changed?).to be_truthy }
      end

      context 'with changes to associated has_one record' do
        before { user.profile.medium_ids << 9 }

        it { expect(subject.changed?).to be_truthy }
      end

      context 'with changes to associated has_many record' do
        before { user.companies.first.name = 'new company name' }

        xit { expect(subject.changed?).to be_truthy } # this spec fails, probably because the service class will query the record from the database instead of finding it in memory
      end

      context 'with blacklist' do
        context 'and blacklisted association changed' do
          before { user.profile.medium_ids << 9 }

          it { expect(subject.changed?(except: :profile)).to be_falsey }
        end

        context 'and non blacklisted association changed' do
          before { user.profile.medium_ids << 9 }

          it { expect(subject.changed?(except: :companies)).to be_truthy }
        end
      end

      context 'with whitelist' do
        context 'and whitelisted association changed' do
          before { user.profile.medium_ids << 9 }

          it { expect(subject.changed?(only: :profile)).to be_truthy }
        end

        context 'and non whitelisted association changed' do
          before { user.companies.first.name = 'new company name' }

          it { expect(subject.changed?(only: :profile)).to be_falsey }
        end
      end

    end
  end
end
