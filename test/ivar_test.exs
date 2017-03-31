defmodule IvarTest do
  use ExUnit.Case
  doctest Ivar

  import Ivar.TestMacros

  setup do
    bypass = Bypass.open

    {:ok, bypass: bypass}
  end

  test "new/2 should return a map with the correct http method and url set" do
    assert Ivar.new(:get,    "http://example.com") == %{method: :get, url: "http://example.com"}
    assert Ivar.new(:post,   "http://example.com") == %{method: :post, url: "http://example.com"}
    assert Ivar.new(:put,    "http://example.com") == %{method: :put, url: "http://example.com"}
    assert Ivar.new(:patch,  "http://example.com") == %{method: :patch, url: "http://example.com"}
    assert Ivar.new(:delete, "http://example.com") == %{method: :delete, url: "http://example.com"}
  end

  test "put_body/3 should add the body and content type to the request map" do
    request = Ivar.new(:post, "")
      |> Ivar.put_body("some plain text", "text/plain")
    
    assert request.body == "some plain text"
    assert Map.get(request.headers, "content-type") == "text/plain"
  end

  test "put_body/3 should put the known data type: json" do
    request = Ivar.new(:post, "")
      |> Ivar.put_body("{\"test\": 123}", :json)
    
    assert request.body == "{\"test\": 123}"
    assert Map.get(request.headers, "content-type") == "application/json"
  end

  test "put_body/3 should put the known data type: form url encoded" do
    request = Ivar.new(:post, "")
      |> Ivar.put_body("test=123", :url_encoded)
    
    assert request.body == "test=123"
    assert Map.get(request.headers, "content-type") == "application/x-www-form-urlencoded"
  end

  test "put_body/3 should put the known data type: xml" do
    request = Ivar.new(:post, "")
      |> Ivar.put_body("<test>123</test>", :xml)
    
    assert request.body == "<test>123</test>"
    assert Map.get(request.headers, "content-type") == "application/xml"
  end
  
  test "put_body/3 should encode and put known data types for a url encoded body" do
    data_tests = [
      %{some: 123, test: "abc"},
      [some: 123, test: "abc"],
      [{:some, 123}, {:test, "abc"}]
    ]
    
    for data <- data_tests do
      request = Ivar.new(:post, "")
        |> Ivar.put_body(data, :url_encoded)
      
      assert request.body == "some=123&test=abc"
      assert Map.get(request.headers, "content-type") == "application/x-www-form-urlencoded"
    end
  end
  
  test "put_body/3 should encode and put known data types for a json body" do
    data = %{some: 123, test: "abc"}
    
    request = Ivar.new(:post, "")
      |> Ivar.put_body(data, :json)
    
    assert request.body == "{\"test\":\"abc\",\"some\":123}"
    assert Map.get(request.headers, "content-type") == "application/json"
  end

  test "put_body/3 should return error for get and delete requests" do
    methods = [:get, :delete]

    for method <- methods do
      request = Ivar.new(method, "")
        |> Ivar.put_body("abc=123", :url_encoded)
      
      assert request == {:error, "Body not allowed for #{Atom.to_string(method)} request"}
    end
  end
  
  test "put_header/3 should put the header in the map headers list" do
    request = Ivar.new(:get, "")
      |> Ivar.put_header("x-test", "some_test")
    
    assert Map.get(request.headers, "x-test") == "some_test"
  end

  test "put_auth/3 should put the bearer auth header" do
    request = Ivar.new(:get, "")
      |> Ivar.put_auth("token", :bearer)

    assert request.auth == {:bearer, "token"}
  end

  test "put_auth/3 should put the basic auth credentials" do
    request = Ivar.new(:get, "")
      |> Ivar.put_auth({"username", "password"}, :basic)

    assert request.auth == {:basic, {"username", "password"}}
  end

  test "send/1 should send minimal empty request", %{bypass: bypass} do
    methods = [:get, :post, :patch, :put, :delete]

    for method <- methods do
      Bypass.expect bypass, fn conn ->
        assert conn.method == method_type(method)
        assert conn.host == "localhost"
        assert conn.port == bypass.port

        Plug.Conn.send_resp(conn, 200, "")
      end

      {:ok, result} =
        Ivar.new(method, test_url(bypass))
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with body", %{bypass: bypass} do
    methods = [:post, :patch, :put]

    for method <- methods do
      Bypass.expect bypass, fn conn ->
        {:ok, body, _} = Plug.Conn.read_body(conn)

        assert has_header(conn, {"content-type", "application/x-www-form-urlencoded"})
        assert body == "test=123"

        Plug.Conn.send_resp(conn, 200, "")
      end

      {:ok, result} =
        Ivar.new(method, test_url(bypass))
        |> Ivar.put_body("test=123", :url_encoded)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with headers", %{bypass: bypass} do
    methods = [:get, :post, :patch, :put, :delete]

    for method <- methods do
      Bypass.expect bypass, fn conn ->
        assert has_header(conn, {"x-test", "123"})
        assert has_header(conn, {"x-abc", "xyz"})

        Plug.Conn.send_resp(conn, 200, "")
      end

      {:ok, result} =
        Ivar.new(method, test_url(bypass))
        |> Ivar.put_header("x-test", "123")
        |> Ivar.put_header("x-abc", "xyz")
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with bearer auth header", %{bypass: bypass} do
    methods = [:get, :post, :patch, :put, :delete]

    for method <- methods do
      Bypass.expect bypass, fn conn ->
        assert has_header(conn, {"authorization", "bearer some.token"})

        Plug.Conn.send_resp(conn, 200, "")
      end

      {:ok, result} =
        Ivar.new(method, test_url(bypass))
        |> Ivar.put_auth("some.token", :bearer)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with basic auth header", %{bypass: bypass} do
    methods = [:get, :post, :patch, :put, :delete]

    for method <- methods do
      Bypass.expect bypass, fn conn ->
        assert has_header(conn, {"authorization", "basic dXNlcm5hbWU6cGFzc3dvcmQ="})
        
        Plug.Conn.send_resp(conn, 200, "")
      end

      {:ok, result} =
        Ivar.new(method, test_url(bypass))
        |> Ivar.put_auth({"username", "password"}, :basic)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "unpack/1 should decode a json response", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, "{\"test\":\"data\"}")
    end
    
    {result, %HTTPoison.Response{}} =
      Ivar.new(:get, test_url(bypass))
      |> Ivar.send
      |> Ivar.unpack
      
    assert result == %{"test" => "data"}
  end

  defp test_url(bypass), do: "http://localhost:#{bypass.port}"

  defp method_type(:get),     do: "GET"
  defp method_type(:post),    do: "POST"
  defp method_type(:put),     do: "PUT"
  defp method_type(:patch),   do: "PATCH"
  defp method_type(:delete),  do: "DELETE"
end
