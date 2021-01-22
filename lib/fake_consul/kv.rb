require "active_support/hash_with_indifferent_access"
require "tmpdir"

module FakeConsul
  class Kv < HashWithIndifferentAccess

    def initialize
      restore!
    end

    # Fake get
    #
    # Performs no http requests but stores data in local hash
    #
    # @param key [String]
    # @param options [Hash]
    # @options recurse [Boolean] wether to list all keys starting with this prefix
    # @param not_found [Symbol] unused/unimplemented
    # @param found [Symbol] not unused/unimplemented
    # @return String e.g. 'bar'
    def get(key, options = nil, not_found = :reject, found = :return)
      options ||= {}

      if options[:recurse]
        find_keys_recursive(key)
      else
        consul_value(key)
      end
    end

    # Fake put
    #
    # Performs no http requests but retrieves data from local hash
    #
    # @param key [String]
    # @param options [Hash] unused/unimplemented
    # @return [Boolean] true :trollface:
    def put(key, value, options = nil)
      self[key] = value
      compact
      persist!
      true
    end

    # Fake delete
    #
    # Performs no http requests but deletes data from local hash
    #
    # @param key [String]
    # @param options [Hash] unused/unimplemented
    # @return [Boolean] true :trollface:
    def delete(key, options = nil)
      super(key)
      compact
      persist!
      true
    end

    # Clear current data
    # and delete backing marshalling file
    def clear
      super
      return unless File.exist?(db_file)
      File.delete(db_file)
    end

    private

    # Persist current data to marshalled file
    def persist!
      File.open(db_file, 'w+') do |f|
        Marshal.dump(self, f)
      end
    end

    # Restore hash from marshalled data
    def restore!
      return unless File.exist?(db_file)

      File.open(db_file) do |f|
        restored_data = Marshal.load(f)
        self.clear
        self.merge!(restored_data)
      end
    rescue EOFError
      # do nothing
    rescue StandardError => e
      raise e
    end

    # Path to marshalled file
    #
    # @return [String]
    def db_file
      "#{Dir.tmpdir}#{File::SEPARATOR}.fake_consul.m"
    end

    # Returns the keys in the following format:
    #  'bar
    # @return String
    def consul_value(key)
      self[key].to_s
    end

    # Returns all keys that begin with the supplied `key`.
    #
    # @return [Array<String>] e.g. ['foo', 'bar', 'baz']
    def find_keys_recursive(key)
      self.keys.select { |_key| _key.to_s.start_with?(key.to_s) }.map { |_key| consul_value(_key) }
    end

    # Remove all keys that are nil
    def compact
      delete_if { |k, v| v.nil? }
    end
  end
end
