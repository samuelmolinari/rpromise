require 'spec_helper'

describe Method do
  MyObject = Struct.new(:store) do
    def method_with_args(*args)
      return args
    end
    def method_with_block
      yield
    end
  end

  let(:obj) { MyObject.new('Hello World') }

  describe '#to_rpromise' do
    it 'converts method object to a promise' do
      lambda_value = nil
      lock = true
      p = obj.method(:store).to_rpromise
      p.then(lambda do |value|
        lambda_value = value
        lock = false
      end)
      loop { break unless lock }
      expect(lambda_value).to eq 'Hello World'
    end
  end
end
