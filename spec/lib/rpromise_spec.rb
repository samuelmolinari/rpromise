require 'spec_helper'

describe ::Rpromise do

  let(:n) { 0 }
  subject(:promise) do
    described_class.new do |resolve, reject|
    end
  end

  it { is_expected.to have_attributes( :state => described_class::State::PENDING ) }

  describe '#initialize' do
    it 'uses the resolve! method as callback' do
      t = nil
      p = described_class.new do |resolve, reject|
        t = Thread.new do
          resolve.call('hi')
        end
      end
      t.join
      expect(p).to be_resolved
    end

    it 'uses the reject! method as callback' do
      t = nil
      p = described_class.new do |resolve, reject|
        t = Thread.new do
          reject.call('hi')
        end
      end
      t.join
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

      context 'with async task' do
        before(:each) do
          @thread = nil
          @promise = described_class.new do |resolve, reject|
            @thread = Thread.new do
              sleep(0.5)
              resolve.call(value)
            end
          end
        end

        it 'returns the resolved value' do
          lambda_value = nil
          @promise.then(lambda do |v|
            lambda_value = v
          end)
          expect(lambda_value).to be_nil
          expect(@promise).to be_pending
          @thread.join
          expect(@promise).to be_resolved
          expect(lambda_value).to eq value
        end
        context 'when multiple then are chained together' do
          it 'passes its returned value to the next then' do
            lambda_value_1 = nil
            lambda_value_2 = nil
            lambda_value_3 = nil
            @promise.then(lambda do |v1|
              lambda_value_1 = v1
              return value2
            end).then(lambda do |v2|
              lambda_value_2 = v2
              return value3
            end).then(lambda do |v3|
              lambda_value_3 = v3
            end)
            @thread.join
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
                  sleep(0)
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
            @promise.then.then(lambda do |v|
              lambda_value = v
            end)
            @thread.join
            expect(lambda_value).to eq value
          end
        end
      end

      context 'with non-async task' do
        let(:promise) do
          described_class.new do |resolve, reject|
            resolve.call(value)
          end
        end

        it 'returns the resolved value' do
          lambda_value = nil
          promise.then(lambda do |v|
            lambda_value = v
          end)
          expect(lambda_value).to be value
        end

        context 'when multiple then are chained together' do
          it 'passes its returned value to the next then' do
            lambda_value_1 = nil
            lambda_value_2 = nil
            lambda_value_3 = nil
            promise.then(lambda do |v1|
              lambda_value_1 = v1
              return value2
            end).then(lambda do |v2|
              lambda_value_2 = v2
              return value3
            end).then(lambda do |v3|
              lambda_value_3 = v3
            end)
            expect(lambda_value_1).to eq value
            expect(lambda_value_2).to eq value2
            expect(lambda_value_3).to eq value3
          end
        end

        context 'when no callback is passed' do
          it 'does not raise any error' do
            expect { promise.then }.not_to raise_error
          end

          it 'passes original returned value to the next then' do
            lambda_value = nil
            promise.then.then(lambda do |v|
              lambda_value = v
            end)
            expect(lambda_value).to eq value
          end
        end
      end
    end

    context 'when promise is rejected' do
      context 'with non-async task' do
        let(:error) { Random.rand }
        let(:promise) do
          described_class.new do |resolve, reject|
            reject.call(error)
          end
        end
        it 'returns exception' do
          lambda_error = nil
          promise.then(nil, lambda do |e|
            lambda_error = e
          end)
          expect(lambda_error).to eq error
        end
        it 'handles raised exceptions within the promise' do
          lambda_error = nil
          promise = described_class.new do |resolve, reject|
            raise 'Oops'
          end
          promise.then(nil, lambda do |e|
            lambda_error = e
          end)
          expect(lambda_error).to be_kind_of RuntimeError
          expect(lambda_error.message).to eq 'Oops'
        end
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

end
