module AppStatus
  class CheckItem
    attr_reader :name, :status, :status_code, :details, :ms
    attr_accessor :proc, :description

    def initialize(name, include_description: false)
      @name = name
      @proc = nil
      @description = ''

      reset
    end

    def reset
      @result = {}
    end

    def valid_status?(status)
      CheckCollection.valid_status_map.keys.include?(status)
    end

    def evaluate!
      check_start = Time.now
      status, details = @proc ? @proc.call : [:unknown, "Check is not configured."]
      check_time = (Time.now - check_start) * 1000

      status = status.to_sym if status
      details = details.to_s if details

      if ! valid_status?(status)
        details = "Check returned invalid status '#{status}'. #{details}".strip
        status = :unknown
      end

      @status = status
      @status_code = CheckCollection.valid_status_map[@status]
      @details = details
      @ms = check_time.to_i

      return @status_code
    end

    def as_hash(include_description: false)
      out = {
        status: @status,
        status_code: @status_code,
        details: @details,
        ms: @ms
      }
      out[:description] = description if include_description
      out
    end
  end
end
