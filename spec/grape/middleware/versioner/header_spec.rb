require 'spec_helper'

describe Grape::Middleware::Versioner::Header do
  let(:app) { lambda{|env| [200, env, env]} }
  let(:accept) { 'application/vnd.vendor-v1+json' }
  subject { Grape::Middleware::Versioner::Header.new(app, @options || {}) }

  context 'api.type and api.subtype' do
    it 'should set any type and any subtype' do
      env = subject.call('HTTP_ACCEPT' => '*/*').last
      env['api.type'].should eql '*'
      env['api.subtype'].should eql '*'
    end

    it 'should set preferred type and subtype' do
      env = subject.call('HTTP_ACCEPT' => 'text/html').last
      env['api.type'].should eql 'text'
      env['api.subtype'].should eql 'html'
    end
  end

  context 'api.format' do
    it 'should be set' do
      env = subject.call('HTTP_ACCEPT' => accept).last
      env['api.format'].should eql 'json'
    end

    it 'should be nil if not provided' do
      env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1').last
      env['api.format'].should eql nil
    end
  end

  context 'matched version' do
    before do
      @options = {
        :versions => ['v1'],
        :version_options => {:using => :header}
      }
    end

    it 'should set api.vendor' do
      env = subject.call('HTTP_ACCEPT' => accept).last
      env['api.vendor'].should eql 'vendor'
    end

    it 'should set api.version' do
      env = subject.call('HTTP_ACCEPT' => accept).last
      env['api.version'].should eql 'v1'
    end
  end

  context 'no header' do
    it 'should return a 200 when no header is set and no strict setting is done' do
      @options = {
        :versions => ['v1'],
        :version_options => {:using => :header}
      }
      subject.call('HTTP_ACCEPT' => '').first.should == 200
    end

    it 'should return a 200 when no header is set but strict header based versioning is disabled' do
      @options = {
        :versions => ['v1'],
        :version_options => {:using => :header, :strict => false}
      }
      subject.call('HTTP_ACCEPT' => '').first.should == 200
    end

    it 'should return a 404 when no header is set but strict header based versioning is used' do
      @options = {
        :versions => ['v1'],
        :version_options => {:using => :header, :strict => true}
      }
      expect {
        env = subject.call('HTTP_ACCEPT' => '').last
      }.to throw_symbol(:error, :status => 404, :headers => {'X-Cascade' => 'pass'}, :message => "404 API Version Not Found")
    end
  end

  context 'no matched version' do
    before do
      @options = {
        :versions => ['unknown_version'],
        :version_options => {:using => :header}
      }
    end

    it 'should throw 404 error with X-Cascade header set to pass' do
      expect {
        env = subject.call('HTTP_ACCEPT' => accept).last
      }.to throw_symbol(:error, :status => 404, :headers => {'X-Cascade' => 'pass'}, :message => "404 API Version Not Found")
    end
  end
end
