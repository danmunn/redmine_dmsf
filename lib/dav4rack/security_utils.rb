# frozen_string_literal: true

module Dav4rack
  # Implements secure string comparison methods.
  # Taken straight from ActiveSupport
  module SecurityUtils
    def secure_compare(avar, bvar)
      return false unless avar.bytesize == bvar.bytesize

      l = avar.unpack "C#{avar.bytesize}"

      res = 0
      bvar.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end

    module_function :secure_compare

    def variable_size_secure_compare(avar, bvar)
      secure_compare(::Digest::SHA256.hexdigest(avar), ::Digest::SHA256.hexdigest(bvar))
    end

    module_function :variable_size_secure_compare
  end
end
