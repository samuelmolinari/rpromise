class Method
  def to_rpromise(*args, &block)
    Rpromise.new do |resolve, reject|
      resolve.call(self.call(*args, &block))
    end
  end
end
