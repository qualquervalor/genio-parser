require 'open-uri'
require 'uri'

module Genio
  module Parser
    module Format
  
      class Include

        @@base_url

        @path

        @file_name

        def init_with coder
          initialize(coder.scalar)
          @file_name = coder.scalar
        end

        def initialize(path)
          @path = path
        end

        def self.base_url(base_url)
          @@base_url = base_url
        end

	    def to_s
	      if @path.to_s =~ /^https?:/
	       uri = @path.to_s
	      else
	       uri = URI.join(@@base_url.to_s, @path.to_s)
	      end
	      return open(uri).read
	    end

        def get_file_name
          @file_name
        end

      end

    end
  end
end

