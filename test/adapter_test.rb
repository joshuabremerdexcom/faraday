require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class AdapterTest < Faraday::TestCase
  before do
    @connection = Faraday::Connection.new(LIVE_SERVER)
  end

  [Faraday::Adapter::NetHttp, Faraday::Adapter::Typhoeus].each do |adapter|
    describe "#get with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      it "retrieves the response body" do
        assert_equal 'hello world', @connection.get('hello_world').body
      end

      it "retrieves the response JSON with StringResponse" do
        @connection.response_class = Faraday::Response::StringResponse
        assert_equal 'hello world', @connection.get('hello_world')
      end

      it "retrieves the response JSON with YajlResponse" do
        @connection.response_class = Faraday::Response::YajlResponse
        assert_equal [1,2,3], @connection.get('json')
      end

      it "retrieves the response headers" do
        assert_equal 'text/html', @connection.get('hello_world').headers['content-type']
      end
    end
  end

  describe "async Typhoeus requests" do
    before do
      @connection.extend Faraday::Adapter::Typhoeus
    end

    it "clears parallel manager after running a single request" do
      assert !@connection.in_parallel?
      resp = @connection.get('hello_world')
      assert !@connection.in_parallel?
      assert_equal 'hello world', @connection.get('hello_world').body
    end

    it "uses parallel manager to run multiple requests" do
      resp1, resp2 = nil, nil

      @connection.in_parallel do
        resp1 = @connection.get('hello_world')
        resp2 = @connection.get('hello_world')
        assert @connection.in_parallel?
        assert_nil resp1.body
        assert_nil resp2.body
      end
      assert !@connection.in_parallel?
      assert_equal 'hello world', resp1.body
      assert_equal 'hello world', resp2.body
    end
  end
end