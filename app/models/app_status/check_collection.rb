# collect a variety of checks for reporting to nagios

module AppStatus

  class CheckCollection

    include Enumerable

    @@check_descriptions = HashWithIndifferentAccess.new
    @@checks = HashWithIndifferentAccess.new

    # Add checks here.
    #
    # These checks are re-run whenever evaluate! is called on an instance.
    # They aren't run at configure time.
    #
    # The block recieves an instance of AppStatus::CheckCollection as an
    # argument.
    #
    # example (put this in config/initalizers/app_status.rb):
    #
    #   AppStatus::CheckCollection.configure do |c|
    #
    #     value = some_service_check
    #     status = value > 100 ? :ok : :critical
    #     c.add(:name => 'some_service', :status => status, :details => value)
    #
    #   end
    def self.configure(&block)
      yield self
    end

    def self.clear_checks!
      @@check_descriptions = HashWithIndifferentAccess.new
      @@checks = HashWithIndifferentAccess.new
    end

    def self.valid_status_map
      {
              ok: 0,
         warning: 1,
        critical: 2,
         unknown: 3
      }
    end

    # add the results of a check to the collection.
    # this should describe the health of some portion of your application
    # The check block you supply should return a status value, or a
    # [:status, 'details'] array.
    #
    # example:
    #   AppStatus::CheckCollection.add_check('some_service') do
    #     [:ok, 'these are optional details']
    #   end
    def self.add_check(name, &block)
      raise ArgumentError, ":name option is required." if ! name

      name = name.to_sym
      raise ArgumentError, "Check name '#{name}' has already been added." if @@checks.keys.include?(name.to_s)
      raise ArgumentError, "No check defined for '#{name}'." if ! block_given?

      item = CheckItem.new(name)
      item.proc = block
      @@checks[name] = item
    end

    # add a long-form description of a check
    # service must have already been added via add_check.
    #
    # example:
    #   AppStatus::CheckCollection.configure do |c|
    #     c.add_check('some_service') do
    #       [:ok, 'these are optional details']
    #     end
    #     c.add_decription 'some_service', <<-EOF
    # some_service is pretty easy to understand.
    # it always works, no matter what.
    # but if it were **harder to comprehend** you
    # could add markdown here to explain what it is
    # and what to do if it starts failing.
    #     EOF
    #
    def self.add_description(name, markdown)
      raise ArgumentError, "Check '#{name}' is not defined." if ! @@checks[name]
      @@checks[name].description = markdown
    end



    attr_reader :finished, :ms, :status, :status_code


    def initialize
      reset
    end

    def reset
      @finished = nil
      @ms = 0
      @status = :ok
      @status_code = self.class.valid_status_map[@status]
      @@checks.each {|key,check| check.reset }
    end

    def each
      @@checks.each {|name,check| yield check }
    end

    # run the checks added via configure
    # results of the checks are available via as_json
    def evaluate!
      eval_start = Time.now

      reset

      @@checks.each do |name,check|
        @status_code = [check.evaluate!, @status_code].max
      end

      @finished = Time.now.utc
      @ms = (Time.now - eval_start) * 1000

      if @@checks.size == 0
        @status = :unknown
        @status_code = self.class.valid_status_map[@status]
      else
        @status = self.class.valid_status_map.invert[@status_code]
      end
    end

    def as_hash
      HashWithIndifferentAccess.new({
        status: @status,
        status_code: @status_code,
        ms: @ms.to_i,
        finished: @finished.iso8601,
        checks: @@checks.inject({}) {|memo,(name,check)| memo[name] = check.as_hash; memo}
      })
    end

    def as_json
      as_hash
    end
  end

end
