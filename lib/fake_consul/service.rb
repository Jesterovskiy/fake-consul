require "active_support/core_ext/hash/keys.rb"
require "active_support/core_ext/string/inflections"
require "ostruct"
require "tmpdir"

module FakeConsul
  class Service
    attr_reader :services

    def initialize
      @services = []
      restore!
    end

    def get(key, scope = :first, options = {}, meta = nil)
      service = services.select { |hash| hash['ServiceName'] == key.to_s }.first
      OpenStruct.new(service)
    end

    # Fake register
    #
    # Performs no http requests but retrieves data from local hash
    #
    # @param definition [Hash]
    # @param options [Hash] unused/unimplemented
    # @return [Boolean] true
    def register(definition, options = {})
      new_service = build_service(definition.stringify_keys)
      deregister(new_service['ServiceName'])
      services.push new_service
      persist!
    end

    # Fake deregister
    #
    # Performs no http requests but deletes data from local hash
    #
    # @param service_name [String]
    # @param options [Hash] unused/unimplemented
    # @return [Boolean] true
    def deregister(service_name, options = {})
      services.delete_if { |hash| hash['ServiceName'] == service_name }
      persist!
    end

    def register_external(definition, options = {})
      new_service = build_external_service(definition.stringify_keys)
      deregister(new_service['ServiceName'])
      services.push new_service
      persist!
    end

    # Fake deregister_external, alias to deregister
    #
    # Performs no http requests but deletes data from local hash
    #
    # @param service_name [String]
    # @param options [Hash] unused/unimplemented
    # @return [Boolean] true
    def deregister_external(service_name, options = {})
      deregister(service_name, options)
    end

    private

    def build_service(hash)
      hash.each_with_object({}) do |(key, value), h|
        if key == 'id'
          h['ServiceID'] = value
          next
        end

        h["Service#{key.camelize}"] = value
      end
    end

    def build_external_service(hash)
      hash.each_with_object({}) do |(key, value), h|
        if value.is_a?(Hash)
          h.merge!(build_service(value.stringify_keys)) if key == 'service'
          next
        end

        h[key.camelize] = value
      end
    end

    # Persist current data to marshalled file
    def persist!
      File.open(db_file, 'w+') { |f| Marshal.dump(services, f) }
      true
    end

    # Restore hash from marshalled data
    def restore!
      return unless File.exist?(db_file)

      File.open(db_file) { |f| @services = Marshal.load(f) rescue [] }
    rescue EOFError
      # do nothing
    rescue StandardError => e
      raise e
    end

    # Path to marshalled file
    #
    # @return [String]
    def db_file
      "#{Dir.tmpdir}#{File::SEPARATOR}.fake_consul_services.m"
    end
  end
end
