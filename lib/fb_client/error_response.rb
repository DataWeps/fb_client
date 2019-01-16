
module FbClient
  class ErrorResponse
    MASKED_STATUS = :masked
    ERRORS = {
      masked: {
        code: [5, 190, 613, 2, 4, 17, 613, 32],
        message: [/request limit reached/i] },
      break: [2500, 803, 21],
      new_id: [21],
      disable: [10],
      limit: {
        code: [-3, 1, 100],
        message: [
          /parameter should not exceed/i,
          /an unknown error occurred/i,
          /please reduce the amount of data/i] }
    }.freeze

    class << self
      def error_response?(response)
        response && response.include?(:error) && response.include?(:content)
      end

      def recognize_error(response)
        error =
          if response[:content].is_a?(String)
            Oj.load(response[:content])
          else
            response[:content]
          end
        begin
          return error unless error.include?('error')
          message, code = error['error'].values_at('message', 'code')
          code = code.to_i
          ERRORS.keys.each do |error_to_recognize|
            return send("#{error_to_recognize}_error", message, code) if
              send("#{error_to_recognize}_error?", message, code)
          end

          { error: message }
        rescue => bang
          { error: "Facebook::Fetch: " \
                    "#{bang.message} #{bang.backtrace} #{response}" }
        end
      end

    private

      def disable_error(_message, code)
        { error: 'disable_error', code: code }
      end


      def disable_error?(_message, code)
        return true if ERRORS[:masked][:code].include?(code)
        false
      end

      def masked_error(_message, _code)
        { error: MASKED_STATUS }
      end

      def masked_error?(_message, code)
        return true if ERRORS[:masked][:code].include?(code)
        false
      end

      def break_error?(_message, code)
        ERRORS[:break].include?(code)
      end

      def break_error(_message, code)
        { error: code }
      end

      def new_id_error?(_message, code)
        ERRORS[:new_id].include?(code)
      end

      def new_id_error(message, code)
        {
          error: code,
          new_id: message =~ /to page id (\d+)/i ? Regexp.last_match(1).to_i : nil }
      end

      def limit_error?(message, code)
        return true if ERRORS[:limit][:code].include?(code)
        ERRORS[:limit].each do |error|
          return true if message =~ error
        end
        false
      end

      def limit_error(messeage, error)
        { error: 'limit_error' }
      end
    end
  end
end
