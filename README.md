# Rpromise

## Installation

Add this line to your application's Gemfile:

    gem 'rpromise'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rpromise

## Usage

```ruby

class Task

  def async
    return ::Rpromise::Promise.new do |resolve, reject|
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

on_resolve = lambda do |value|

  puts value

  return ::Rpromise::Promise.new do |resolve, reject|
    Thread.new do
      sleep(1)
      # Do an async task
      resolve.call(value + 10)
    end
  end
end

on_reject = lambda do |error|
  puts error
end

Task.new.async
  .then(on_resolve, on_reject)
  .then(Proc.new do |value_plus_10|
    puts value_plus_10 # Returned value from the previous ``then`` promise resolved value
  end)

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
