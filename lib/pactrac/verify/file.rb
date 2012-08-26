require 'tmpdir'

module PacTrac
  module Verify
    module File
      module_function

      def create(name, data)
        filename = ::File.join(Dir.tmpdir, "pactrac_#{Time.now.to_i}_#{name}")
        ::File.open(filename, 'w') do |f|
          f.write(data)
        end
        filename
      end
    end
  end
end
