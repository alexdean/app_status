require 'spec_helper'

describe AppStatus::CheckCollection do

  before(:each) do
    AppStatus::CheckCollection.clear_checks!
  end

  describe "add" do

    describe "validations" do
      it "should raise an error if :name is not supplied" do
        AppStatus::CheckCollection.configure {|c| c.add status: :ok }
        c = AppStatus::CheckCollection.new
        expect {
          c.evaluate!
        }.to raise_error(ArgumentError, ":name option is required.")
      end

      it "should raise an error if :status is not supplied" do
        AppStatus::CheckCollection.configure {|c| c.add name: 'foo' }
        c = AppStatus::CheckCollection.new
        expect {
          c.evaluate!
        }.to raise_error(ArgumentError, ":status option is required.")
      end

      it "should raise an error if an unrecognized option is supplied" do
        AppStatus::CheckCollection.configure {|c| c.add name: 'foo', status: :ok, glork: '', ping: '' }
        c = AppStatus::CheckCollection.new
        expect {
          c.evaluate!
        }.to raise_error(ArgumentError, "Unrecognized option(s) for 'foo' check: glork,ping")
      end

      it "should raise an error if :status is unrecognized" do
        AppStatus::CheckCollection.configure {|c| c.add name: 'foo', status: 'test' }
        c = AppStatus::CheckCollection.new
        expect {
          c.evaluate!
        }.to raise_error(ArgumentError, "'test' is not a valid status for check 'foo'.")
      end

      it "should raise an error if a :name is used multiple times" do
        AppStatus::CheckCollection.configure do |c|
          c.add name: 'foo', status: :ok
          c.add name: 'foo', status: :critical
        end
        c = AppStatus::CheckCollection.new
        expect {
          c.evaluate!
        }.to raise_error(ArgumentError, "Check name 'foo' has already been added.")
      end
    end

  end

  describe "evaluate!" do
    it "should run configured checks each time it is called" do
      counter = 0
      check = lambda { counter += 1; counter }
      AppStatus::CheckCollection.configure do |c|
        num_calls = check.call
        c.add name: 'something', status: :ok, details: num_calls
      end

      c = AppStatus::CheckCollection.new

      Timecop.freeze '2013-10-04T12:00:00Z' do
        c.evaluate!
        c.as_json[:finished].should eq '2013-10-04T12:00:00Z'
        c.as_json[:checks][:something][:details].should eq "1"
      end

      Timecop.freeze '2013-10-04T01:00:00Z' do
        c.evaluate!
        c.as_json[:finished].should eq '2013-10-04T01:00:00Z'
        c.as_json[:checks][:something][:details].should eq "2"
      end
    end
  end

  describe "as_json" do
    it "should use :unknown status if no checks are configured" do
      c = AppStatus::CheckCollection.new
      c.evaluate!
      data = c.as_json

      data[:status].should eq :unknown
      data[:checks].should eq({})
    end
  end

  describe "configure" do
    it "should add checks to be evaluated later" do
      AppStatus::CheckCollection.configure do |c|
        c.add name: 'something', status: :ok
      end

      c = AppStatus::CheckCollection.new
      c.evaluate!
      data = c.as_json
    end
  end
end
