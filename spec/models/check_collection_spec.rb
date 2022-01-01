require 'spec_helper'

describe AppStatus::CheckCollection do

  before(:each) do
    AppStatus::CheckCollection.clear_checks!
  end

  describe "configure" do
    it "should yield itself" do
      AppStatus::CheckCollection.configure do |c|
        c.should eq AppStatus::CheckCollection
      end
    end
  end

  describe "clear_checks!" do
    it "should remove all checks" do
      c = AppStatus::CheckCollection.new
      AppStatus::CheckCollection.add_check('test') { nil }
      c.evaluate!
      raise "fails"
      c.as_json['checks'].size.should eq 1

      AppStatus::CheckCollection.clear_checks!
      c.evaluate!
      c.as_json['checks'].size.should eq 0
    end
  end

  describe "add_check" do

    describe "validations" do
      it "should raise an error if name is not supplied" do
        expect {
          AppStatus::CheckCollection.add_check
        }.to raise_error(ArgumentError)
      end

      it "should raise an error if block is not supplied" do
        expect {
          AppStatus::CheckCollection.add_check 'some_service'
        }.to raise_error(ArgumentError, "No check defined for 'some_service'.")
      end

      it "should raise an error if a :name is used multiple times" do
        AppStatus::CheckCollection.add_check('foo') {[:ok, 'ok']}
        expect {
          AppStatus::CheckCollection.add_check('foo') {[:ok, 'ok']}
        }.to raise_error(ArgumentError, "Check name 'foo' has already been added.")
      end
    end

  end


  describe "evaluate!" do

    it "should run configured checks each time it is called" do
      counter = 0
      AppStatus::CheckCollection.add_check('test') { counter += 1; [:ok, counter] }

      c = AppStatus::CheckCollection.new

      Timecop.freeze '2013-10-04T12:00:00Z' do
        c.evaluate!
        c.as_json[:finished].should eq '2013-10-04T12:00:00Z'
        c.as_json[:checks][:test][:details].should eq "1"
      end

      Timecop.freeze '2013-10-04T01:00:00Z' do
        c.evaluate!
        c.as_json[:finished].should eq '2013-10-04T01:00:00Z'
        c.as_json[:checks][:test][:details].should eq "2"
      end
    end

    it "should set :unknown status for a check which does not return a status" do
      AppStatus::CheckCollection.add_check('test') { nil }

      c = AppStatus::CheckCollection.new
      c.evaluate!
      c.as_json[:checks][:test][:status].should eq :unknown
      c.as_json[:checks][:test][:details].should eq "Check returned invalid status ''."
    end

    it "should set :unknown status for a check which returns an invalid status" do
      AppStatus::CheckCollection.add_check('test') { 'huh?' }

      c = AppStatus::CheckCollection.new
      c.evaluate!
      c.as_json[:checks][:test][:status].should eq :unknown
      c.as_json[:checks][:test][:details].should eq "Check returned invalid status 'huh?'."
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

    it "should set overall status to match the worst status among configured checks" do
      c = AppStatus::CheckCollection.new

      AppStatus::CheckCollection.add_check('a') { :ok }

      c.evaluate!
      c.as_json['status'].should eq :ok
      c.as_json['checks'].size.should eq 1

      AppStatus::CheckCollection.add_check('b') { :warning }

      c.evaluate!
      c.as_json['status'].should eq :warning
      c.as_json['checks'].size.should eq 2

      AppStatus::CheckCollection.add_check('c') { :critical }

      c.evaluate!
      c.as_json['status'].should eq :critical
      c.as_json['checks'].size.should eq 3

      AppStatus::CheckCollection.add_check('d') { :unknown }

      c.evaluate!
      c.as_json['status'].should eq :unknown
      c.as_json['checks'].size.should eq 4
    end

    it "should include details on all checks" do
      AppStatus::CheckCollection.configure do |c|
        c.add_check('test1') { [:ok, 'looks good'] }
        c.add_check('test2') { [:huh, 'invalid'] }
        c.add_check('test3') { [:warning, 'not good'] }
        c.add_check('test4') { [:critical, 'on fire'] }
        c.add_check('test5') { [:unknown, 'no idea'] }
      end

      c = AppStatus::CheckCollection.new
      Timecop.freeze('2013-10-05T12:00:00Z') { c.evaluate! }

      expect(c.as_json).to match({
        "status" => :unknown,
        "status_code" => 3,
        "ms" => an_instance_of(Integer),
        "finished" => "2013-10-05T12:00:00Z",
        "checks" => {
          "test1" => {
            "status" => :ok,
            "status_code" => 0,
            "details" => "looks good",
            "ms" => an_instance_of(Integer)
          },
          "test2" => {
            "status" => :unknown,
            "status_code" => 3,
            "details" => "Check returned invalid status 'huh'. invalid",
            "ms" => an_instance_of(Integer)
          },
          "test3" => {
            "status" => :warning,
            "status_code" => 1,
            "details" => "not good",
            "ms" => an_instance_of(Integer)
          },
          "test4" => {
            "status" => :critical,
            "status_code" => 2,
            "details" => "on fire",
            "ms" => an_instance_of(Integer)
          },
          "test5" => {
            "status" => :unknown,
            "status_code" => 3,
            "details" => "no idea",
            "ms" => an_instance_of(Integer)
          }
        }
      })
    end

    it "should include optionally include descriptions" do
      AppStatus::CheckCollection.configure do |c|
        c.add_check('test1') { [:ok, 'looks good'] }
        c.add_description 'test1', 'test1 description'

        c.add_check('test2') { [:ok, 'looks good'] }
        c.add_description 'test2', 'test2 description'
      end

      c = AppStatus::CheckCollection.new
      c.evaluate!

      result = c.as_json(include_descriptions: true)

      expect(
        result['checks']['test1']['description']
      ).to eq 'test1 description'

      expect(
        result['checks']['test2']['description']
      ).to eq 'test2 description'
    end

  end
end
