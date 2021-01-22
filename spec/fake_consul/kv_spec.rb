require_relative '../spec_helper'
require 'fake_consul/kv'

RSpec.describe FakeConsul::Kv do
  subject { FakeConsul::Kv.new }

  before { subject.clear }

  describe '#put' do
    it 'stores key into Hash' do
      subject.put('foo', 'bar')
      expect(subject['foo']).to eq 'bar'
    end

    it 'returns true' do
      expect(subject.put('foo', 'bar')).to eq true
    end

    it 'compacts the hash to remove keys with nil values' do
      subject.put('foo', nil)
      expect(subject.key?('foo')).to eq false
    end
  end

  describe '#delete' do
    before { subject.put('foo', 'bar') }

    it 'delete key from Hash' do
      subject.delete('foo')
      expect(subject.key?('foo')).to eq false
    end

    it 'returns true' do
      expect(subject.put('foo', 'bar')).to eq true
    end

    it 'compacts the hash to remove keys with nil values' do
      subject.put('foo', nil)
      expect(subject.key?('foo')).to eq false
    end
  end

  describe '#get' do
    describe 'simple (no recursing)' do
      before { subject.put('foo', 'bar') }

      it 'retrieves key from Hash in an array' do
        expect(subject.get('foo')).to eq 'bar'
      end
    end

    describe 'with recursing' do
      before do
        subject.put('foo/bar/baz', 'baz')
        subject.put('foo/bar/bif', 'bif')
        subject.put('foo/bar/boz', 'boz')
        subject.put('foo/boom/boz', 'boz')
      end

      let(:expected_value) do
        %w[baz bif boz]
      end

      it 'retrieves all keys beginning with supplied key from Hash in an array' do
        expect(subject.get('foo/bar/', recurse: true)).to eq expected_value
      end
    end
  end
end
