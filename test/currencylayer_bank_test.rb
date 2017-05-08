# encoding: UTF-8
# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

describe Money::Bank::CurrencylayerBank do
  subject { Money::Bank::CurrencylayerBank.new }
  let(:url) { Money::Bank::CurrencylayerBank::CL_URL }
  let(:secure_url) { Money::Bank::CurrencylayerBank::CL_SECURE_URL }
  let(:source) { Money::Bank::CurrencylayerBank::CL_SOURCE }
  let(:temp_cache_path) do
    File.expand_path(File.join(File.dirname(__FILE__), 'temp.json'))
  end
  let(:data_path) do
    File.expand_path(File.join(File.dirname(__FILE__), 'live.json'))
  end

  describe 'exchange' do
    before do
      subject.access_key = TEST_ACCESS_KEY
      subject.cache = temp_cache_path
      stub(subject).source_url { data_path }
      subject.update_rates
    end

    after do
      File.unlink(temp_cache_path)
    end

    describe 'without rates' do
      it 'able to exchange a money to its own currency even without rates' do
        money = Money.new(0, 'USD')
        subject.exchange_with(money, 'USD').must_equal money
      end

      it "raise if it can't find an exchange rate" do
        money = Money.new(0, 'USD')
        proc { subject.exchange_with(money, 'SSP') }
          .must_raise Money::Bank::UnknownRate
      end
    end

    describe 'with rates' do
      before do
        subject.update_rates
      end

      it 'should be able to exchange money from USD to a known exchange rate' do
        money = Money.new(100, 'USD')
        subject.exchange_with(money, 'BBD').must_equal Money.new(200, 'BBD')
      end

      it 'should be able to exchange money from a known exchange rate to USD' do
        money = Money.new(200, 'BBD')
        subject.exchange_with(money, 'USD').must_equal Money.new(100, 'USD')
      end

      it "should raise if it can't find an exchange rate" do
        money = Money.new(0, 'USD')
        proc { subject.exchange_with(money, 'SSP') }
          .must_raise Money::Bank::UnknownRate
      end
    end
  end

  describe 'cache rates' do
    before do
      subject.access_key = TEST_ACCESS_KEY
      subject.cache = temp_cache_path
      stub(subject).source_url { data_path }
      subject.update_rates
    end

    after do
      File.delete(temp_cache_path) if File.exist?(temp_cache_path)
    end

    it 'should allow update after save' do
      begin
        subject.update_rates
      rescue
        assert false, 'Should allow updating after saving'
      end
    end

    it 'should not break an existing file if save fails to read' do
      initial_size = File.read(temp_cache_path).size
      stub(subject).open_url { '' }
      subject.update_rates
      File.read(temp_cache_path).size.must_equal initial_size
    end

    it 'should not break an existing file if save returns json without rates' do
      initial_size = File.read(temp_cache_path).size
      stub(subject).open_url { '{ "error": "An error" }' }
      subject.update_rates
      File.read(temp_cache_path).size.must_equal initial_size
    end

    it 'should not break an existing file if save returns a invalid json' do
      initial_size = File.read(temp_cache_path).size
      stub(subject).open_url { '{ invalid_json: "An error" }' }
      subject.update_rates
      File.read(temp_cache_path).size.must_equal initial_size
    end
  end

  describe 'no cache' do
    before do
      subject.cache = nil
      subject.access_key = TEST_ACCESS_KEY
      stub(subject).source_url { data_path }
    end

    it 'should get from url' do
      subject.update_rates
      subject.rates.wont_be_empty
    end
  end

  describe 'no valid file for cache' do
    before do
      subject.cache = "space_dir#{rand(999_999_999)}/out_space_file.json"
      subject.access_key = TEST_ACCESS_KEY
      stub(subject).source_url { data_path }
    end

    it 'should raise an error if invalid path is given' do
      proc { subject.update_rates }.must_raise Money::Bank::InvalidCache
    end
  end

  describe 'using proc for cache' do
    before :each do
      @global_rates = nil
      subject.cache = proc { |v|
        if v
          @global_rates = v
        else
          @global_rates
        end
      }
      subject.access_key = TEST_ACCESS_KEY
    end

    it 'should get from url normally' do
      stub(subject).source_url { data_path }
      subject.update_rates
      subject.rates.wont_be_empty
    end

    it 'should save from url and get from cache' do
      stub(subject).source_url { data_path }
      subject.update_rates
      @global_rates.wont_be_empty
      dont_allow(subject).source_url
      subject.update_rates
      subject.rates.wont_be_empty
    end
  end

  describe '#secure_connection' do
    it "should use the non-secure http url if secure_connection isn't set" do
      subject.secure_connection = nil
      subject.access_key = TEST_ACCESS_KEY
      subject.source_url.must_equal "#{url}?source=#{source}&"\
                                    "access_key=#{TEST_ACCESS_KEY}"
    end

    it 'should use the non-secure http url if secure_connection is false' do
      subject.secure_connection = false
      subject.access_key = TEST_ACCESS_KEY
      subject.source_url.must_equal "#{url}?source=#{source}&"\
                                    "access_key=#{TEST_ACCESS_KEY}"
    end

    it 'should use the secure https url if secure_connection is set to true' do
      subject.secure_connection = true
      subject.access_key = TEST_ACCESS_KEY
      subject.source_url.must_equal "#{secure_url}?source=#{source}&"\
                                    "access_key=#{TEST_ACCESS_KEY}"
      subject.source_url.must_include 'https://'
    end
  end

  describe '#update_rates' do
    before do
      subject.access_key = TEST_ACCESS_KEY
      subject.cache = data_path
      stub(subject).source_url { data_path }
      subject.update_rates
    end

    it 'should update itself with exchange rates from CurrencylayerBank' do
      subject.rates.keys.each do |currency|
        next unless Money::Currency.find(currency)
        subject.get_rate('USD', currency).must_be :>, 0
      end
    end

    it 'should not return 0 with integer rate' do
      wtf = {
        priority: 1,
        iso_code: 'WTF',
        name: 'WTF',
        symbol: 'WTF',
        subunit: 'Cent',
        subunit_to_unit: 1000,
        separator: '.',
        delimiter: ','
      }
      Money::Currency.register(wtf)
      Timecop.freeze(subject.rates_timestamp) do
        subject.add_rate('USD', 'WTF', 2)
        subject.add_rate('WTF', 'USD', 2)
        subject.exchange_with(5000.to_money('WTF'), 'USD').cents
        subject.exchange_with(5000.to_money('WTF'), 'USD').cents.wont_equal 0
      end
    end
  end

  describe '#access_key' do
    before do
      subject.cache = temp_cache_path
      stub(OpenURI::OpenRead).open(url) { File.read data_path }
    end

    it 'should raise an error if no access key is set' do
      proc { subject.update_rates }.must_raise Money::Bank::NoAccessKey
    end
  end

  describe '#expire_rates!' do
    before do
      subject.access_key = TEST_ACCESS_KEY
      subject.ttl_in_seconds = 1000
      @old_usd_eur_rate = 0.655
      # see test/live.json +54
      @new_usd_eur_rate = 0.886584
      subject.cache = temp_cache_path
      stub(subject).source_url { data_path }
      subject.update_rates
      subject.add_rate('USD', 'EUR', @old_usd_eur_rate)
    end

    after do
      File.delete(temp_cache_path) if File.exist?(temp_cache_path)
    end

    describe 'when the ttl has expired' do
      it 'should update the rates' do
        Timecop.freeze(subject.rates_timestamp + 1000) do
          subject.get_rate('USD', 'EUR').must_equal @old_usd_eur_rate
        end
        Timecop.freeze(subject.rates_timestamp + 1001) do
          subject.get_rate('USD', 'EUR').wont_equal @old_usd_eur_rate
          subject.get_rate('USD', 'EUR').must_equal @new_usd_eur_rate
        end
      end

      it 'updates the next expiration time' do
        Timecop.freeze(subject.rates_timestamp + 1001) do
          exp_time = subject.rates_timestamp + 1000
          subject.expire_rates!
          subject.rates_expiration.must_equal exp_time
        end
      end
    end

    describe 'when the ttl has not expired' do
      it 'not should update the rates' do
        subject.update_rates
        exp_time = subject.rates_expiration
        subject.expire_rates!
        subject.rates_expiration.must_equal exp_time
      end
    end
  end

  describe '#rates_timestamp' do
    before do
      subject.access_key = TEST_ACCESS_KEY
      subject.cache = temp_cache_path
      stub(subject).source_url { data_path }
    end

    after do
      File.delete(temp_cache_path) if File.exist?(temp_cache_path)
    end

    it 'should return 1970-01-01 datetime if no rates' do
      stub(subject).open_url { '' }
      subject.update_rates
      subject.rates_timestamp.must_equal Time.at(0)
    end

    it 'should return a Time object' do
      subject.update_rates
      subject.rates_timestamp.class.must_equal Time
    end
  end
end
