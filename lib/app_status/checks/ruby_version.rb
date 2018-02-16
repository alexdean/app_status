module AppStatus
  module Checks
    # verify that running ruby version is as expected
    #
    # @example reading expected version from .ruby-version file
    #   # config/initializers/app_status.rb
    #   require 'app_status/checks/ruby_version'
    #   AppStatus::Checks::RubyVersion.install!
    #
    # @example specifying expected ruby version
    #   # config/initializers/app_status.rb
    #   require 'app_status/checks/ruby_version'
    #   AppStatus::Checks::RubyVersion.install!(expected_version: '2.5.0')
    module RubyVersion
      # add a ruby version check to AppStatus::CheckCollection
      #
      # @param [String] expected_version which ruby version is expected?
      def self.install!(expected_version: nil)
        AppStatus::CheckCollection.add_check('ruby_version') do
          AppStatus::Checks::RubyVersion.check(expected_version: expected_version)
        end
      end

      # compare expected ruby version to actual ruby version
      #
      # @param [String] expected_version which ruby version is expected?
      #   if nil, value will be read from .ruby-version file
      def self.check(expected_version: nil)
        expected_version ||= File.read(Rails.root.join('.ruby-version')).strip
        status = RUBY_VERSION == expected_version ? :ok : :critical
        [status, "expected: #{expected_version}, actual: #{RUBY_VERSION}"]
      end
    end
  end
end
