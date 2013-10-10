require 'yaml'

module Genio
  module Parser
    module Format
      class Raml < Base
	  
	    @schema

        def initialize
          YAML.add_tag "!include", Genio::Parser::Format::Include
        end
      
        def load(url_file)
          Include::base_url(url_file)
          read_file(url_file) do |data|
	        parse_file(data)
	      end
	    end

	    def parse_file(data)
	      @schema = YAML.load(data)
	      self.endpoint = update_version_parameter
	      @schema.each do |key, definition|
	        if key =~ /^\//
	          #parse_resource(key, definition)
			elsif key =~ /schema/
              #parse objects
              definition.each do |sch|
                if sch.is_a?(Hash)
                  sch.each do |object_name, object_content|
                    puts object_name
					puts object_content
                  end
                else sch.is_a?(String)
                  puts "TTT"  
                  puts sch
                end
              end
            #elsif key =~ /mediaType/
              #self.media_type = @schema['mediaType']
	        end
	      end
	      @schema
	    end

        def parse_resource(key, resource)
	      resource.each do |resource_key, resource_def|
	        resource_name = key.split('/').last

	        # check to see if last part is a template variable
	        if resource_name =~ /^{.*}/
	          resource_name = key.split('/')[-2]
	        end

            case resource_key

	        when 'displayName'
              
              # parse description of resource
            when 'post'

	          # parse post
	          define_post(resource_name, resource_def)
            when 'get'

	          # parse get
            else
	      
	          # default log
	          if resource_key =~ /^\//
	            # parse inner resource
		        parse_resource(key.to_s + resource_key.to_s, resource_def)
	          end
	        end
	      end
	    end

	    def define_post(resource_name, resource_def)
          resource_def.each do |post_key, post_def|
            case post_key

            when 'description'
	            
			  #parse description
            when 'body'
              post_def.each do |body_key, body_def|
                case body_key
                when 'text/xml'
                    
                  # puts 'to be implemented'
                when 'application/json'
                  body_def.each do |json_key, json_def|
                    case json_key
                    when 'schema'
                      puts "object name: " + form_class_name(resource_name)
                      puts json_def.to_s
                      puts "-----------------"
                    end
                  end
                end
              end
            end
          end
        end


        def form_class_name(name)
          File.basename(name.to_s.gsub(/\#$/, "").gsub(/-/, "_"), ".json").camelcase
        end
		
        def update_version_parameter
          @schema['baseUri'].gsub(/{version}/, @schema['version']) if @schema['baseUri'] =~ /{version}/
          @schema['baseUri']
		end

      end
    end
  end
end
