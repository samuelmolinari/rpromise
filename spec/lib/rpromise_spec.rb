require 'spec_helper'

describe ::Rpromise do

  let(:n) { 0 }
  subject(:promise) do
    described_class.new do |resolve, reject|
      sleep(0.1)
    end
  end

  it { is_expected.to have_attributes( :state => described_class::State::PENDING ) }

  describe '#initialize' do
    it 'uses the resolve! method as callback' do
      lock = true
      p = described_class.new do |resolve, reject|
        sleep(0.1)
        resolve.call('hi')
        lock = false
      end
      loop { break unless lock }
      expect(p).to be_resolved
    end

    it 'uses the reject! method as callback' do
      lock = true
      p = described_class.new do |resolve, reject|
        sleep(0.1)
        reject.call('hi')
        lock = false
      end
      loop { break unless lock }
      expect(p).to be_rejected
    end
  end

  describe '#then' do
    it 'returns a new promise' do
      expect(promise.then).to be_kind_of described_class
    end

    it 'takes an optional block as first argument' do
      expect { promise.then(nil,lambda {}) }.not_to raise_error
      expect { promise.then(nil, promise.method(:reject!)) }.not_to raise_error
      expect { promise.then(nil, "test") }.to raise_error ArgumentError
    end

    it 'takes an optional block as second argument' do
      expect { promise.then(lambda {}, nil) }.not_to raise_error
      expect { promise.then(promise.method(:resolve!), nil) }.not_to raise_error
      expect { promise.then("test", nil) }.to raise_error ArgumentError
    end

    context 'when promise is resolved' do

      let(:value) { Random.rand }
      let(:value2) { Random.rand + value }
      let(:value3) { Random.rand + value + value2 }

      before(:each) do
        @promise = described_class.new do |resolve, reject|
          sleep(0.1)
          resolve.call(value)
        end
      end

      it 'returns the resolved value' do
        lambda_value = nil
        lock = true
        @promise.then(lambda do |v|
          lambda_value = v
          lock = false
        end)
        loop { break unless lock }
        expect(@promise).to be_resolved
        expect(lambda_value).to eq value
      end

      context 'when multiple then are chained together' do
        it 'passes its returned value to the next then' do
          lambda_value_1 = nil
          lambda_value_2 = nil
          lambda_value_3 = nil
          lock = true
          @promise.then(lambda do |v1|
            lambda_value_1 = v1
            return value2
          end).then(lambda do |v2|
            lambda_value_2 = v2
            return value3
          end).then(lambda do |v3|
            lambda_value_3 = v3
            lock = false
          end)
          loop { break unless lock }
          expect(lambda_value_1).to eq value
          expect(lambda_value_2).to eq value2
          expect(lambda_value_3).to eq value3
        end
      end

      context 'when then resolve callback returns a promise' do
        it 'uses the next then as handler' do
          thread2 = nil
          lambda_value = nil
          lock = true
          @promise.then(lambda do |v|
            return described_class.new do |resolve, reject|
              thread2 = Thread.new do
                sleep(0.1)
                resolve.call('Hello world!')
              end
            end
          end).then(lambda do |hello_world|
            lambda_value = hello_world
            lock = false
          end)
          loop { break unless lock }
          expect(lambda_value).to eq 'Hello world!'
        end
      end

      context 'when no callback is passed' do
        it 'passes original returned value to the next then' do
          lambda_value = nil
          lock = true
          @promise.then.then(lambda do |v|
            lambda_value = v
            lock = false
          end)
          loop { break unless lock }
          expect(lambda_value).to eq value
        end
      end
    end

    context 'when promise is rejected' do
      let(:error) { Random.rand }
      it 'returns exception' do
        lambda_error = nil
        lock = true
        p = described_class.new do |resolve, reject|
          sleep(0.1)
          reject.call(error)
        end
        p.then(nil, lambda do |e|
          lambda_error = e
          lock = false
        end)
        loop { break unless lock }
        expect(lambda_error).to eq error
      end

      it 'handles raised exceptions within the promise' do
        lambda_error = nil
        lock = true
        p = described_class.new do |resolve, reject|
          sleep(0.1)
          raise 'Oops'
        end
        p.then(nil, lambda do |e|
          lambda_error = e
          lock = false
        end)
        loop { break unless lock }
        expect(lambda_error).to be_kind_of RuntimeError
        expect(lambda_error.message).to eq 'Oops'
      end

      it 'handles raised exceptions within resolve!' do
        lambda_error = nil
        lock = true
        p = described_class.new do |resolve, reject|
          sleep(0.1)
          resolve.call(true)
        end
        # Skip the lambda argument to generate an error
        p.then(lambda do
          lock = false
        end, lambda do |err|
          lambda_error = err
          lock = false
        end)
        loop { break unless lock }
        expect(lambda_error).to be_kind_of ArgumentError
      end
    end
  end

  context 'when it is pending' do
    before(:each) { promise.instance_variable_set(:@state, described_class::State::PENDING) }
    describe '#pending?' do
      it 'returns true' do
        expect(promise).to be_pending
      end
    end
    describe '#rejected?' do
      it 'returns false' do
        expect(promise).not_to be_rejected
      end
    end
    describe '#resolved?' do
      it 'returns false' do
        expect(promise).not_to be_resolved
      end
    end
  end
  context 'when it is rejected' do
    before(:each) { promise.instance_variable_set(:@state, described_class::State::REJECTED) }
    describe '#pending?' do
      it 'returns false' do
        expect(promise).not_to be_pending
      end
    end
    describe '#rejected?' do
      it 'returns true' do
        expect(promise).to be_rejected
      end
    end
    describe '#resolved?' do
      it 'returns false' do
        expect(promise).not_to be_resolved
      end
    end
  end
  context 'when it is resolved' do
    before(:each) { promise.instance_variable_set(:@state, described_class::State::RESOLVED) }
    describe '#pending?' do
      it 'returns false' do
        expect(promise).not_to be_pending
      end
    end
    describe '#rejected?' do
      it 'returns false' do
        expect(promise).not_to be_rejected
      end
    end
    describe '#resolved?' do
      it 'returns true' do
        expect(promise).to be_resolved
      end
    end
  end

  describe '.from_method' do
    MyObject = Struct.new(:store) do
      def method_with_args(*args)
        return args
      end
      def method_with_block
        yield
      end
    end

    before(:each) do
      @obj = MyObject.new('Hello World')
    end

    it 'converts method to a running promise' do
      lambda_value = nil
      lock = true
      promise = Rpromise.from_method(@obj, :store)
      promise.then(lambda do |store_value|
        lambda_value = store_value
        lock = false
      end)
      loop { break unless lock }
      expect(lambda_value).to eq 'Hello World'
    end

    it 'passes the method arguments' do
      promise = Rpromise.from_method(@obj, :method_with_args, 1, 2, 3, 'test')
      lambda_value = nil
      lock = true
      promise.then(lambda do |value|
        lambda_value = value
        lock = false
      end)
      loop { break unless lock }
      expect(lambda_value).to eq [1,2,3,'test']
    end

    it 'passes the method block' do
      promise = Rpromise.from_method(@obj, :method_with_block) { 'Block' }
      lambda_value = nil
      lock = true
      promise.then(lambda do |value|
        lambda_value = value
        lock = false
      end)
      loop { break unless lock }
      expect(lambda_value).to eq 'Block'
    end
  end

end
