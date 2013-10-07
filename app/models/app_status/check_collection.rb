# collect a variety of checks for reporting to nagios

module AppStatus

  class CheckCollection

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
      @@checks = HashWithIndifferentAccess.new
    end

    def initialize
      @valid_status = {
              ok: 0,
         warning: 1,
        critical: 2,
         unknown: 3
      }.freeze

      @check_results = HashWithIndifferentAccess.new
      @eval_finished = nil
      @eval_time = 0
    end

    # add the results of a check to the collection.
    # this should describe the health of some portion of your application
    #
    # example:
    #   value = some_service_check
    #   c.add(:name => 'some_service', :status => :ok, :details => value)
    def self.add_check(name, &block)
      raise ArgumentError, ":name option is required." if ! name
      # raise ArgumentError, ":status option is required." if ! options[:status]

      name = name.to_sym
      raise ArgumentError, "Check name '#{name}' has already been added." if @@checks.keys.include?(name.to_s)
      raise ArgumentError, "No check defined for '#{name}'." if ! block_given?

      @@checks[name] = block
    end

    def valid_status?(status)
      @valid_status.keys.include?(status)
    end

    # run the checks added via configure
    # results of the checks are available via as_json
    def evaluate!
      eval_start = Time.now
      @check_results = {}
      @@checks.each do |name,proc|
        check_start = Time.now
        status, details = proc.call
        check_time = (Time.now - check_start) * 1000

        status = status.to_sym if status
        details = details.to_s if details

        if ! valid_status?(status)
          details = "Check returned invalid status '#{status}'. #{details}".strip
          status = :unknown
        end
        @check_results[name] = {
          status: status,
          status_code: @valid_status[status],
          details: details,
          ms: check_time.to_i
        }
      end

      @eval_finished = Time.now.utc
      @eval_time = (Time.now - eval_start) * 1000
    end

    def as_json
      if @check_results.size == 0
        max_status = :unknown
        max_int = @valid_status[max_status]
      else
        max_int = @check_results.inject([]){ |memo,val| memo << val[1][:status_code]; memo}.max
        max_status = @valid_status.invert[max_int]
      end

      HashWithIndifferentAccess.new({
        status: max_status,
        status_code: max_int,
        ms: @eval_time.to_i,
        finished: @eval_finished.iso8601,
        checks: @check_results
      })
    end
  end

end
