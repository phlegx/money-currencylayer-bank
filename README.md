# Money Currencylayer Bank

A gem that calculates the exchange rate using published rates from
[currencylayer.com](https://currencylayer.com/)

## Usage

~~~ ruby
# Minimal requirements
require 'money/bank/currencylayer_bank'
mclb = Money::Bank::MoneyCurrencylayerBank.new
mclb.access_key = 'your access_key from https://currencylayer.com/product'

# Update rates
mclb.update_rates

# Store in cache
mclb.save_rates

# (optional)
# set the seconds after than the current rates are automatically expired
# by default, they never expire, in this example 1 day.
mclb.ttl_in_seconds = 86400

# (optional)
# use https to fetch rates from Open Exchange Rates
# disabled by default to support free-tier users
mclb.secure_connection = true

# Define cache
mclb.cache = 'path/to/file/cache'

# Set money default bank to currencylayer bank
Money.default_bank = mclb
~~~

### Using gem money-rails

You can also use it in Rails with the gem [money-rails](https://github.com/RubyMoney/money-rails).

~~~ ruby
require 'money/bank/currencylayer_bank'

MoneyRails.configure do |config|
  mclb = Money::Bank::MoneyCurrencylayerBank.new
  mclb.access_key = 'your access_key from https://currencylayer.com/product'
  mclb.update_rates

  config.default_bank = mclb
end
~~~

### Cache

You can also provide a Proc as a cache to provide your own caching mechanism
perhaps with Redis or just a thread safe `Hash` (global). For example:

~~~ ruby
mclb.cache = Proc.new do |v|
  key = 'money:currencylayer_bank'
  if v
    Thread.current[key] = v
  else
    Thread.current[key]
  end
end
~~~

## Process

The gem fetches all rates in a cache with USD as base currency. It's possible to compute the rate between any of the currencies by calculating a pair rate using base USD rate.

## Tests

You can place your own key on a file or environment
variable named TEST_ACCESS_KEY and then run:

~~~
bundle exec rake
~~~

## Refs

* <https://github.com/RubyMoney/money>
* <https://github.com/currencybot/open-exchange-rates>

## Contributors

* See [GitHub](https://github.com/phlegx/money-currencylayer-bank/graphs/contributors).
* Inspired by [GitHub](https://github.com/spk/money-open-exchange-rates/graphs/contributors).

## License

The MIT License

Copyright (c) 2015 Phlegx Systems OG

---
[![Gem Version](https://badge.fury.io/rb/money-currencylayer-bank.svg)](https://rubygems.org/gems/money-currencylayer-bank)
[![Build Status](https://secure.travis-ci.org/phlegx/money-currencylayer-bank.svg?branch=master)](https://travis-ci.org/phlegx/money-currencylayer-bank)
[![Code Climate](http://img.shields.io/codeclimate/github/phlegx/money-currencylayer-bank.svg)](https://codeclimate.com/github/phlegx/money-currencylayer-bank)
[![Inline docs](http://inch-ci.org/github/phlegx/money-currencylayer-bank.svg?branch=master)](http://inch-ci.org/github/phlegx/money-currencylayer-bank)
[![License](https://img.shields.io/github/license/phlegx/money-currencylayer-bank.svg)](http://opensource.org/licenses/MIT)
