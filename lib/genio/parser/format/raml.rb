require 'yaml'
require 'json'
require 'uri'

module Genio
  module Parser
    module Format
      class Raml < Base
	  
	    @schema
		
		@file_url

        def initialize
		  super
          YAML.add_tag "!include", Genio::Parser::Format::Include
        end
      
        def load(file_url)
		  @file_url = file_url
          Include::base_url(@file_url)
          read_file(@file_url) do |data|
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
                  sch.each do |object_name, object_def|
                    class_name = form_class_name(object_name)
                    class_def = get_json_hash(object_def)
                    populate_datatype(class_name, class_def)
                  end
                else sch.is_a?(String)
                  # parse external schemas
                end
              end
            elsif key =~ /mediaType/
              self.media_type = @schema['mediaType']
	        end
	      end
	      @schema
	    end
		
        def populate_datatype(class_name, class_def)
          #
		  puts "Defining: " + class_name
          data_types[class_name] = {}
          data_types[class_name] = parse_object(class_def)
		  class_name
        end
		
        def parse_object(data)
          properties = Types::Base.new
          if data.properties
		    data.properties.each do |name, property_def|
              # property_name => property_type
			  properties[name] = parse_object_properties(name, property_def)
            end
          elsif data.type.is_a?(Array)
            data.type.each do |object|
              properties.merge!(parse_object(object).properties)
            end
          end
          if data.extends.is_a? String
            uri = get_uri_from_ref(data.extends)
            class_name = form_class_name(uri)
			if data_types[class_name] == nil
			    puts data_types.keys
                puts "Class name: " + class_name.inspect + " Extends Read from: " + uri
			    read_file(uri) do |data|
	              class_def = get_json_hash(data)
				  data.extends = populate_datatype(class_name, class_def)
                end
            end
          else
            data.extends = nil
          end
		  data.properties = properties
          Types::DataType.new(data)
        end
		
        def parse_object_properties(name, property_def)
		  property_def.array = true if property_def.type == 'array'
          property_def.type  =
            if property_def["$ref"]               # Check the type is refer to another schema or not
			  uri = get_uri_from_ref(property_def["$ref"])
              class_name = form_class_name(uri)
			  if data_types[class_name] == nil
                puts "Class name: " + class_name + " Reference Read from: " + uri
			    read_file(uri) do |data|
	              class_def = get_json_hash(data)
				  populate_datatype(class_name, class_def)
				end
              end
            elsif property_def.additionalProperties and property_def.additionalProperties["$ref"]
              #self.load(data.additionalProperties["$ref"])
              uri = get_uri_from_ref(property_def.additionalProperties["$ref"])
              class_name = form_class_name(uri)
			  if data_types[class_name] == nil
                puts "Class name: " + class_name + " Additional Read from: " + uri
			    read_file(uri) do |data|
	              class_def = get_json_hash(data)
				  populate_datatype(class_name, class_def)
                end
              end
            elsif property_def.properties # Check the type has object definition or not
              class_name = form_class_name(name)
              populate_datatype(class_name, property_def)
            elsif property_def.type.is_a? Array
			  property_def.union_types = property_def.type.map do |type|
                parse_object(type)
              end
              "object"
            elsif property_def.items              # Parse array value type
              array_property = parse_object_properties(name, property_def.items)
              array_property.type
            else
              property_def.type                   # Simple type
            end
          Types::Property.new(property_def)
        rescue => error
          logger.error error.message
          Types::Property.new
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

		def get_uri_from_ref(ref)
		  if ref =~ /^https?:/
	       uri = ref
	      else
	       uri = URI.join(@file_url.to_s, ref)
	      end
	      return uri.to_s
	    end

        def form_class_name(name)
          File.basename(name.to_s.gsub(/\#$/, "").gsub(/-/, "_"), ".json").camelcase
        end
		
        def update_version_parameter
          @schema['baseUri'].gsub(/{version}/, @schema['version']) if @schema['baseUri'] =~ /{version}/
          @schema['baseUri']
		end
		
        def get_json_hash(json)
          json_hash = JSON.parse(json.to_s, :object_class => Types::Base, :max_nesting => 100)
        end

      end
    end
  end
end
