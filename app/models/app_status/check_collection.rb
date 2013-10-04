# collect a variety of checks for reporting to nagios

module AppStatus

  class CheckCollection

    @@config_proc = nil

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
      @@config_proc = block
    end

    def self.clear_checks!
      @@config_proc = nil
    end

    def initialize
      @valid_status = {
              ok: 0,
         warning: 1,
        critical: 2,
         unknown: 3
      }.freeze

      @checks = HashWithIndifferentAccess.new
      @eval_finished = nil
      @eval_time = 0
    end

    # add the results of a check to the collection.
    # this should describe the health of some portion of your application
    #
    # example:
    #   value = some_service_check
    #   c.add(:name => 'some_service', :status => :ok, :details => value)
    def add(options={})
      raise ArgumentError, ":name option is required." if ! options[:name]
      raise ArgumentError, ":status option is required." if ! options[:status]

      name = options[:name].to_sym
      status = options[:status].to_sym
      details = options[:details].to_s

      # blow up if someone sends us options we don't understand.
      other_options = options.keys - [:name, :status, :details]
      if other_options.size > 0
        raise ArgumentError, "Unrecognized option(s) for '#{name}' check: #{other_options.join(',')}"
      end

      raise ArgumentError, "'#{status}' is not a valid status for check '#{name}'." if ! valid_status?(status)
      raise ArgumentError, "Check name '#{name}' has already been added." if @checks.keys.include?(name)

      @checks[name] = {status: status, status_code: @valid_status[status], details: details}
    end

    def valid_status?(status)
      @valid_status.keys.include?(status)
    end

    # run the checks added via configure
    # results of the checks are available via as_json
    def evaluate!
      start = Time.now
      @checks = {}
      @@config_proc.call(self) if @@config_proc
      @eval_finished = Time.now.utc
      @eval_time = (Time.now - start) * 1000
    end

    def as_json
      if @checks.size == 0
        max_status = :unknown
        max_int = @valid_status[max_status]
      else
        max_int = @checks.inject([]){ |memo,val| memo << val[1][:status_code]; memo}.max
        max_status = @valid_status.invert[max_int]
      end

      HashWithIndifferentAccess.new({
        status: max_status,
        status_code: max_int,
        run_time_ms: @eval_time.to_i,
        finished: @eval_finished.iso8601,
        checks: @checks
      })
    end
  end

end
