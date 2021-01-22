require_relative '../spec_helper'
require 'fake_consul/service'

RSpec.describe FakeConsul::Service do
  subject { FakeConsul::Service.new }

  describe '#get' do
    context 'when service is not found' do
      it 'returns blank OpenStruct if no service found' do
        expect(subject.get('foo')).to eq OpenStruct.new
      end
    end

    context 'when service is found' do
      let(:service) { {'ServiceName' => 'test', 'ServiceAddress' => 'addr'} }
      let(:expected_result) { OpenStruct.new(service) }

      before { subject.instance_variable_set(:@services, [service]) }

      it 'returns a service by name' do
        expect(subject.get('test')).to eq expected_result
        expect(subject.get(:test)).to eq expected_result
      end
    end
  end

  describe '#register' do
    let!(:service_params) do
      { id: 'Foobar#123', name: 'foobar', address: 'localhost', port: 3003, tags: %w[foo bar] }
    end

    let(:expected_result) do
      OpenStruct.new(ServiceID: 'Foobar#123', ServiceName: 'foobar',
                     ServiceAddress: 'localhost', ServicePort: 3003, ServiceTags: %w[foo bar])
    end

    let(:expected_result2) do
      OpenStruct.new(ServiceID: 'Foobar#123', ServiceName: 'foobar',
                     ServiceAddress: nil, ServicePort: 4000, ServiceTags: %w[foo bar])
    end

    it 'registers a service successfully' do
      subject.register(service_params)
      expect(subject.get('foobar')).to eq expected_result
    end

    it 'register a new service and override previous service with the same name' do
      subject.register(service_params.merge(port: 4000, address: nil))
      expect(subject.get('foobar')).to eq expected_result2
    end
  end

  describe '#deregister' do
    let!(:service_params) do
      { id: 'Foobar#123', name: 'foobar', address: 'localhost', port: 3003, tags: %w[foo bar] }
    end

    it 'removes service from registration' do
      subject.register(service_params)
      expect(subject.get('foobar')).to be

      subject.deregister('foobar')
      expect(subject.get('foobar')).to eq OpenStruct.new
    end
  end

  describe '#register_external' do
    let!(:service_params) do
      {
        node: 'foobar_node',
        address: 'localhost',
        service: { name: 'foobar_service', port: 3003 }
      }
    end

    let(:expected_result) do
      OpenStruct.new(Node: 'foobar_node', Address: 'localhost', ServiceName: 'foobar_service', ServicePort: 3003)
    end

    it 'registers a service successfully' do
      subject.register_external(service_params)
      expect(subject.get('foobar_service')).to eq expected_result
    end
  end

  describe '#deregister' do
    let!(:service_params) do
      {
        node: 'foobar_node',
        address: 'localhost',
        service: { name: 'foobar_service', port: 3003 }
      }
    end

    it 'removes service from registration' do
      subject.register(service_params)
      expect(subject.get('foobar_service')).to be

      subject.deregister('foobar_service')
      expect(subject.get('foobar_service')).to eq OpenStruct.new
    end
  end
end
