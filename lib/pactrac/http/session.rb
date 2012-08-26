require 'net/http'

module PacTrac
  module Http
    module Session
      module_function

      Store = Struct.new(:session, :cookies)

      def start(address, port)
        Store.new(Net::HTTP.start(address, port), {})
      end

      def finish(session)
        session.session.finish
      end
    end
  end
end
