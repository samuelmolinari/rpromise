require 'rpromise'
require 'pry'

class ::Rpromise::Promise

  module State
    PENDING   = :pending
    RESOLVED  = :resolved
    REJECTED  = :rejected
  end

  Handler = Struct.new(:on_resolved, :on_rejected, :resolve, :reject)

  attr_reader :state

  def initialize()
    @state = State::PENDING
    @defered = nil
    yield(method(:resolve!), method(:reject!),self)
  rescue Exception => e
    reject!(e)
  end

  def then(on_resolved = nil, on_rejected = nil)
    raise ArgumentError unless is_valid_block?(on_resolved)
    raise ArgumentError unless is_valid_block?(on_rejected)
    return self if on_resolved.nil? && on_rejected.nil?
    return ::Rpromise::Promise.new do |resolve, reject, promise|
      handler = Handler.new(on_resolved, on_rejected, resolve, reject)
      self.handle(handler)
    end
  end

  def pending?
    return @state == State::PENDING
  end

  def resolved?
    return @state == State::RESOLVED
  end

  def rejected?
    return @state == State::REJECTED
  end

  def resolve!(value = nil)
    if value.is_a?(::Rpromise::Promise)
      value.then(method(:resolve!), method(:reject!))
      return
    end

    @state = State::RESOLVED
    @value = value

    unless @defered.nil?
      handle(@defered)
    end

  rescue
    reject!(nil)
  end

  def reject!(value = nil)
    @state = State::REJECTED
    @value = value

    unless @defered.nil?
      handle(@defered)
    end
  end

  protected

  def is_valid_block?(arg)
    return arg.nil? || arg.is_a?(Proc) || arg.is_a?(Method)
  end

  def handle(handler)
    if pending?
      @defered = handler
      return nil
    end

    callback = nil

    if resolved?
      callback = handler.on_resolved
    else
      callback = handler.on_rejected
    end

    unless callback.nil?
      output = nil
      output = callback.call(@value)
      handler.resolve.call(output) unless handler.resolve.nil?
    end
  rescue
    handler.reject.call(nil) unless handler.reject.nil?
  end

end
