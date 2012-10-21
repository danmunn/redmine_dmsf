module DAV4Rack

  module HTTPStatus
    
    class Status < Exception
      
      class << self
        attr_accessor :code, :reason_phrase
        alias_method :to_i, :code
        
        def status_line
          "#{code} #{reason_phrase}"
        end
        
      end
      
      def code
        self.class.code
      end

      def reason_phrase
        self.class.reason_phrase
      end
      
      def status_line
        self.class.status_line
      end
      
      def to_i
        self.class.to_i
      end
      
    end
    
    StatusMessage = {
      100 => 'Continue',
      101 => 'Switching Protocols',
      102 => 'Processing',
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',
      207 => 'Multi-Status',
      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      307 => 'Temporary Redirect',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Request Entity Too Large',
      414 => 'Request-URI Too Large',
      415 => 'Unsupported Media Type',
      416 => 'Request Range Not Satisfiable',
      417 => 'Expectation Failed',
      422 => 'Unprocessable Entity',
      423 => 'Locked',
      424 => 'Failed Dependency',      
      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported',
      507 => 'Insufficient Storage'
    }

    StatusMessage.each do |code, reason_phrase|
      klass = Class.new(Status)
      klass.code = code
      klass.reason_phrase = reason_phrase
      klass_name = reason_phrase.gsub(/[ \-]/,'')
      const_set(klass_name, klass)
    end

  end

end


module Rack
  class Response
    module Helpers
      DAV4Rack::HTTPStatus::StatusMessage.each do |code, reason_phrase|
        name = reason_phrase.gsub(/[ \-]/,'_').downcase
        define_method(name + '?') do
          @status == code
        end
      end
    end
  end
end
