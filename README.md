# Rpromise

[![Build Status](https://travis-ci.org/samuelmolinari/rpromise.svg?branch=master)](https://travis-ci.org/samuelmolinari/rpromise)
[![Gem Version](https://badge.fury.io/rb/rpromise.svg)](http://badge.fury.io/rb/rpromise)
[![Code Climate](https://codeclimate.com/github/samuelmolinari/rpromise/badges/gpa.svg)](https://codeclimate.com/github/samuelmolinari/rpromise)
[![Test Coverage](https://codeclimate.com/github/samuelmolinari/rpromise/badges/coverage.svg)](https://codeclimate.com/github/samuelmolinari/rpromise)

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
    ::Rpromise.new do |resolve, reject|
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
  value + 10

end).then(lambda do |value|

  # value == 15
  Rpromise.new do |resolve, reject|
    resolve.call(value / 5)
  end

end).then(lambda do |value|

  # value == 3

end)
```

#### Error handling

You can handle errors raised during the async task by passing a callback block as second argument

```ruby
p = Rpromise.new do |resolve, reject|
  raise 'Oopss'
end

p.then(nil, lambda do |err|
  err.message # => "Oopss"
end)
```

or you can handle the exceptions yourself by making use of the reject callback

```ruby
p = Rpromise.new do |resolve, reject|
  begin
    method_that_could_raise_an_exception()
    resolve.call('Everything went ok')
  rescue Exception => e
    reject.call('Oh dear, what have I done?!')
  end
end

p.then(lambda do |message|
  # Called if the promise executed without exceptions
end, lambda do |err|
  # Called if the promise has raised an exception
end)
```

### Convert method to promise

You can convert any method into a promise

```ruby
promise = Rpromise.from_method(100, :to_s)

promise.then(lambda do |value|
  value[0...2] # => "10"
end)
```

or you can convert a method to a promise

```ruby
promise = 100.method(:to_s).to_rpromise

promise.then(lambda do |value|
  value[0...2] # => "10"
end)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
