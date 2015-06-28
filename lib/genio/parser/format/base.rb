#
#   Copyright 2013 PayPal Inc.
# 
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
# 
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
require 'active_support/all'
require 'uri'
require 'open-uri'

module Genio
  module Parser
    module Format
      class Base
        include Logging

        attr_accessor :files, :services, :data_types, :enum_types, :options, :endpoint, :media_type

        def initialize(options = {})
          @options = options

          @files      = Types::Base.new( "#" => "self" )
          @services   = Types::Base.new
          @data_types = Types::Base.new
          @enum_types = Types::Base.new
        end

        def to_iodocs
          IODocs.to_iodocs(self)
        end

        def open(file, options = {})
          options[:ssl_verify_mode] ||= 0
          super(file, options)
        end

        def load_files
          @load_files ||= []
        end

        def expand_path(file)
          if load_files.any? and file !~ /^(\/|https?:\/\/)/
            parent_file = load_files.last
            if parent_file =~ /^https?:/
              file = URI.join(parent_file, file).to_s
            else
              file = File.expand_path(file, File.dirname(parent_file))
            end
          end
          file
        end

        def read_file(file, &block)
          file = expand_path(file)
          load_files.push(file)
          logger.info("GET #{file}")
          block.call(open(file).read)
        ensure
          load_files.pop
        end

      end
    end
  end
end
