require 'spec_helper'
require 'app_status/checks/ruby_version'

RSpec.describe AppStatus::Checks::RubyVersion, type: :model do
  let(:subject) { described_class }
  let(:actual_ruby_version)  { '2.4.1' }
  let(:other_ruby_version)   { '2.5.0' }
  before(:each) do
    stub_const('RUBY_VERSION', actual_ruby_version)
  end

  describe '.install!' do
    after(:each) do
      AppStatus::CheckCollection.clear_checks!
    end

    it 'should add a ruby_version check to AppStatus::CheckCollection' do
      # add to list of checks
      AppStatus::Checks::RubyVersion.install!(expected_version: actual_ruby_version)

      # evaluate the checks which have been added
      checks = AppStatus::CheckCollection.new
      checks.evaluate!

      # look at results
      results = checks.as_hash
      expect(results['checks'].keys).to include('ruby_version')
    end

    it 'should pass optional parameter along to .check' do
      AppStatus::Checks::RubyVersion.install!(expected_version: other_ruby_version)

      expect(AppStatus::Checks::RubyVersion).to(
        receive(:check)
          .with(expected_version: other_ruby_version)
      )

      checks = AppStatus::CheckCollection.new
      checks.evaluate!
    end
  end

  describe '.check' do
    it 'should be :ok when RUBY_VERSION matches expected_version' do
      result = subject.check(expected_version: actual_ruby_version)
      expect(result).to(
        eq([:ok, "expected: #{actual_ruby_version}, actual: #{actual_ruby_version}"])
      )
    end

    it 'should be :critical when RUBY_VERSION does not match expected_version' do
      result = subject.check(expected_version: other_ruby_version)
      expect(result).to(
        eq([:critical, "expected: #{other_ruby_version}, actual: #{actual_ruby_version}"])
      )
    end

    it 'should read from .ruby-version if expected_version is not specified' do
      expect(File).to(
        receive(:read)
          .with(Rails.root.join('.ruby-version'))
          .and_return(actual_ruby_version)
      )

      result = subject.check
      expect(result).to(
        eq([:ok, "expected: #{actual_ruby_version}, actual: #{actual_ruby_version}"])
      )
    end
  end
end
