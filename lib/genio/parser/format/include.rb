require 'open-uri'


module Genio
  module Parser
    module Format
  
      class Include

        @@base_url

        @path

        def init_with coder
          initialize(coder.scalar)
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
	    uri = File.join(File.dirname(@@base_url.to_s), @path.to_s)
	  end
	  return open(uri).read
	end

      end

    end
  end
end

