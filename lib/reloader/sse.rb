require 'json'

module Reloader
  class SSE
    def initialize io
      @io = io
    end

    def write object, options = {}
      options.each do |k,v|
        #Rails.logger.debug("#{k}: #{v}")
        @io.write "#{k}: #{v}\n"
      end
      #Rails.logger.debug("data: #{JSON.dump(object)}\n")
      @io.write "data: #{JSON.dump(object)}\n\n"
    end

    def close
      @io.close
    end
  end
end
