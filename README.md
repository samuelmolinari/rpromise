# Rpromise

[![Build Status](https://travis-ci.org/samuelmolinari/rpromise.svg?branch=master)](https://travis-ci.org/samuelmolinari/rpromise)
[![Gem Version](https://badge.fury.io/rb/rpromise.svg)](http://badge.fury.io/rb/rpromise)

## Installation

Add this line to your application's Gemfile:

    gem 'rpromise'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rpromise

## Usage

### Create a promise

```ruby

class Task

  def async

    return ::Rpromise.new do |resolve, reject|
      Thread.new do
        sleep(1)
        value = Random.rand * 10

        if value > 5
          resolve.call(value)
        else
          reject.call('Oh boy, what have you done')
        end

      end
    end

  end

end

```

### Callbacks

#### Using method

You can use existing methods as callbacks:

```ruby
def on_resolve(value)
  # Do something with the returned value from the promise
end

Task.new.async.then(method(:on_resolve))
```

#### Using proc

You can use ``Proc`` as a callback

```ruby
Task.new.async.then(Proc.new do |value|
  # Do something
end)
```

#### Using lambda

You can use ``lambda`` as a callback

```ruby
Task.new.async.then(lambda do |value|
  # Do something
end)
```

### Chained promises

```ruby
Rpromise.new do |resolve, reject|

  resolve.call(5)

end.then(lambda do |value|

  # value == 5
  return value + 10

end).then(lambda do |value|

  # value == 15
  return Rpromise.new do |resolve, reject|

    Thread.new { resolve.call(value / 5) }

  end

end).then(lambda do |value|

  # value == 3

end)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
