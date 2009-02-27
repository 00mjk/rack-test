require File.dirname(__FILE__) + "/spec_helper"

describe Rack::Test::Session do
  before do
    app = Rack::Test::FakeApp.new
    @session = Rack::Test::Session.new(app)
  end

  def request
    @session.last_request
  end

  def response
    @session.last_response
  end

  describe "#request" do
    it "requests the URI using GET by default" do
      @session.request "/"
      request.should be_get
      response.should be_ok
    end

    it "returns a response" do
      @session.request("/").should be_ok
    end

    it "uses the provided env" do
      @session.request "/", "X-Foo" => "bar"
      request.env["X-Foo"].should == "bar"
    end

    it "defaults to GET" do
      @session.request "/"
      request.env["REQUEST_METHOD"].should == "GET"
    end

    it "defaults the REMOTE_ADDR to 127.0.0.1" do
      @session.request "/"
      request.env["REMOTE_ADDR"].should == "127.0.0.1"
    end

    it "sets rack.test to true in the env" do
      @session.request "/"
      request.env["rack.test"].should == true
    end

    it "defaults to port 80" do
      @session.request "/"
      request.env["SERVER_PORT"].should == "80"
    end

    it "defaults to example.org" do
      @session.request "/"
      request.env["SERVER_NAME"].should == "example.org"
    end

    it "keeps a cookie jar" do
      @session.request "/set-cookie"
      response.body.should == ["Value: 0"]
      @session.request "/set-cookie"
      response.body.should == ["Value: 1"]
    end

    it "accepts explicitly provided cookies" do
      @session.request "/set-cookie", :cookie => "value=1"
      response.body.should == ["Value: 1"]
    end

    it "sends multipart requests"

    it "yields the response to a given block" do
      @session.request "/" do |response|
        response.should be_ok
      end
    end

    it "doesn't follow redirects by default" do
      @session.request "/?redirect=true"
      response.should be_redirect
      response.body.should be_empty
    end

    context "when input is given" do
      it "should send the input" do
        @session.request "/", :method => "POST", :input => "foo"
        request.env["rack.input"].string.should == "foo"
      end

      it "should not send a multipart request" do
        @session.request "/", :method => "POST", :input => "foo"
        request.env["CONTENT_TYPE"].should_not == "application/x-www-form-urlencoded"
      end
    end

    context "for a POST" do
      it "uses application/x-www-form-urlencoded as the CONTENT_TYPE" do
        @session.request "/", :method => "POST"
        request.env["CONTENT_TYPE"].should == "application/x-www-form-urlencoded"
      end
    end

    context "when the URL is https://" do
      it "sets SERVER_PORT to 443" do
        @session.get "https://example.org/"
        request.env["SERVER_PORT"].should == "443"
      end

      it "sets HTTPS to on" do
        @session.get "https://example.org/"
        request.env["HTTPS"].should == "on"
      end
    end
  end

  describe "#initialize" do
    it "raises ArgumentError if the given app doesn't quack like an app" do
      lambda {
        Rack::Test::Session.new(Object.new)
      }.should raise_error(ArgumentError)
    end
  end

  describe "#last_request" do
    it "returns the most recent request" do
      @session.request "/"
      @session.last_request.env["PATH_INFO"].should == "/"
    end

    it "raises an error if no requests have been issued" do
      lambda {
        @session.last_request
      }.should raise_error
    end
  end

  describe "#last_response" do
    it "returns the most recent response" do
      @session.request "/"
      @session.last_response["Content-Type"].should == "text/html"
    end

    it "raises an error if no requests have been issued" do
      lambda {
        @session.last_response
      }.should raise_error
    end
  end

  describe "#get" do
    it_should_behave_like "any #verb methods"

    def verb
      "get"
    end

    it "accepts params in the path" do
      @session.send(verb, "/?foo=bar")
      request.send(verb.upcase).should == { "foo" => "bar" }
    end
  end

  describe "#head" do
    it_should_behave_like "any #verb methods"

    def verb
      "head"
    end
  end

  describe "#post" do
    it_should_behave_like "any #verb methods"

    def verb
      "post"
    end

    it "uses application/x-www-form-urlencoded as the CONTENT_TYPE" do
      @session.post "/"
      request.env["CONTENT_TYPE"].should == "application/x-www-form-urlencoded"
    end

    it "accepts a body" do
      @session.post "/", "Lobsterlicious!"
      request.body.read.should == "Lobsterlicious!"
    end
  end

  describe "#put" do
    it_should_behave_like "any #verb methods"

    def verb
      "put"
    end
  end

  describe "#delete" do
    it_should_behave_like "any #verb methods"

    def verb
      "delete"
    end
  end
end
