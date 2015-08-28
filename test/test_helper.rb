# encoding: UTF-8
require 'minitest/autorun'
require 'rr'
require 'money/bank/currencylayer_bank'
require 'monetize'
require 'timecop'
require 'pry'

TEST_ACCESS_KEY_PATH = File.join(File.dirname(__FILE__), 'TEST_ACCESS_KEY')
TEST_ACCESS_KEY = ENV['TEST_ACCESS_KEY'] || File.read(TEST_ACCESS_KEY_PATH)

if TEST_ACCESS_KEY.nil? || TEST_ACCESS_KEY.empty?
  fail "Please add a valid access key to file #{TEST_ACCESS_KEY_PATH} or to " \
    ' TEST_TEST_ACCESS_KEY environment'
end
