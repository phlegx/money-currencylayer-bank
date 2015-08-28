# encoding: UTF-8
require 'open-uri'
require 'money'
require 'json'

# Money gem class
class Money
  # https://github.com/RubyMoney/money#exchange-rate-stores
  module Bank
    # Invalid cache, file not found or cache empty
    class InvalidCache < StandardError; end

    # App id not set error
    class NoAccessKey < StandardError; end

    # CurrencylayerBank base class
    class CurrencylayerBank < Money::Bank::VariableExchange
      # CurrencylayerBank url
      CL_URL = 'http://apilayer.net/api/live'
      # CurrencylayerBank secure url
      SECURE_CL_URL = CL_URL.gsub('http:', 'https:')
      # Default base currency
      CL_SOURCE = 'USD'

      # Use https to fetch rates from CurrencylayerBank
      # CurrencylayerBank only allows http as connection
      # for the free plan users.
      attr_accessor :secure_connection

      # API must have a valid access_key
      attr_accessor :access_key

      # Cache accessor, can be a String or a Proc
      attr_accessor :cache

      # Rates expiration Time
      attr_reader :rates_expiration

      # Parsed CurrencylayerBank result as Hash
      attr_reader :cl_rates

      # Seconds after than the current rates are automatically expired
      attr_reader :ttl_in_seconds

      # Set the base currency for all rates. By default, USD is used.
      # CurrencylayerBank only allows USD as base currency
      # for the free plan users.
      #
      # @example
      #   source = 'USD'
      #
      # @param value [String] Currency code, ISO 3166-1 alpha-3
      #
      # @return [String] Setted base currency
      def source=(value)
        @source = Money::Currency.find(value.to_s).try(:iso_code) || CL_SOURCE
      end

      # Get the base currency for all rates. By default, USD is used.
      # @return [String] Base currency
      def source
        @source ||= CL_SOURCE
      end

      # Set the seconds after than the current rates are automatically expired
      # by default, they never expire.
      #
      # @example
      #   ttl_in_seconds = 86400 # will expire the rates in one day
      #
      # @param value [Integer] Time to live in seconds
      #
      # @return [Integer] Setted time to live in seconds
      def ttl_in_seconds=(value)
        @ttl_in_seconds = value
        refresh_rates_expiration if ttl_in_seconds
        @ttl_in_seconds
      end

      # Update all rates from CurrencylayerBank JSON
      # @return [Array] Array of exchange rates
      def update_rates
        exchange_rates.each do |exchange_rate|
          currency = exchange_rate.first[3..-1]
          rate = exchange_rate.last
          next unless Money::Currency.find(currency)
          set_rate(source, currency, rate)
          set_rate(currency, source, 1.0 / rate)
        end
      end

      # Save rates on cache
      # Can raise InvalidCache
      #
      # @return [Proc,File]
      def save_rates
        fail InvalidCache unless cache
        text = read_from_url
        store_in_cache(text) if valid_rates?(text)
      rescue Errno::ENOENT
        raise InvalidCache
      end

      # Override Money `get_rate` method for caching
      # @param [String] from_currency Currency ISO code. ex. 'USD'
      # @param [String] to_currency Currency ISO code. ex. 'CAD'
      #
      # @return [Numeric] rate.
      def get_rate(from_currency, to_currency, opts = {})
        expire_rates
        super
      end

      # Expire rates when expired
      def expire_rates
        return unless ttl_in_seconds
        return if rates_expiration > Time.now
        update_rates
        refresh_rates_expiration
      end

      # Source url of CurrencylayerBank
      # defined with access_key and secure_connection
      def source_url
        fail NoAccessKey if access_key.nil? || access_key.empty?
        cl_url = CL_URL
        cl_url = SECURE_CL_URL if secure_connection
        "#{cl_url}?source=#{source}&access_key=#{access_key}"
      end

      protected

      # Store the provided text data by calling the proc method provided
      # for the cache, or write to the cache file.
      #
      # @example
      #   store_in_cache("{\"quotes\": {\"USDAED\": 3.67304}}")
      #
      # @param text [String] String to cache
      # @return [String,Integer]
      def store_in_cache(text)
        if cache.is_a?(Proc)
          cache.call(text)
        elsif cache.is_a?(String)
          open(cache, 'w') do |f|
            f.write(text)
          end
        end
      end

      # Read from cache when exist
      def read_from_cache
        if cache.is_a?(Proc)
          cache.call(nil)
        elsif cache.is_a?(String) && File.exist?(cache)
          open(cache).read
        end
      end

      # Read from url
      # @return [String] JSON content
      def read_from_url
        open(source_url).read
      end

      # Check validity of rates response only for store in cache
      #
      # @example
      #   valid_rates?("{\"quotes\": {\"USDAED\": 3.67304}}")
      #
      # @param [String] text is JSON content
      # @return [Boolean] valid or not
      def valid_rates?(text)
        parsed = JSON.parse(text)
        parsed && parsed.key?('quotes')
      rescue JSON::ParserError
        false
      end

      # Get expire rates, first from cache and then from url
      # @return [Hash] key is country code (ISO 3166-1 alpha-3) value Float
      def exchange_rates
        begin
          doc = JSON.parse(read_from_cache.to_s)
        rescue JSON::ParserError
          begin
            doc = JSON.parse(read_from_url)
          rescue JSON::ParserError
            doc = { 'quotes' => {} }
          end
        end
        @cl_rates = doc['quotes']
      end

      # Refresh expiration from now
      # return [Time] new expiration time
      def refresh_rates_expiration
        @rates_expiration = Time.now + ttl_in_seconds
      end
    end
  end
end
