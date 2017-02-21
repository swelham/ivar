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
    map = Ivar.new(:get, "")
      |> Ivar.put_body("some plain text", "text/plain")
    
    assert map.body == "some plain text"
    assert Map.get(map.headers, "content-type") == "text/plain"
  end

  test "put_body/3 should put the known data type: json" do
    map = Ivar.new(:get, "")
      |> Ivar.put_body("{\"test\": 123}", :json)
    
    assert map.body == "{\"test\": 123}"
    assert Map.get(map.headers, "content-type") == "application/json"
  end

  test "put_body/3 should put the known data type: form url encoded" do
    map = Ivar.new(:get, "")
      |> Ivar.put_body("test=123", :url_encoded)
    
    assert map.body == "test=123"
    assert Map.get(map.headers, "content-type") == "application/x-www-form-urlencoded"
  end

  test "put_body/3 should put the known data type: xml" do
    map = Ivar.new(:get, "")
      |> Ivar.put_body("<test>123</test>", :xml)
    
    assert map.body == "<test>123</test>"
    assert Map.get(map.headers, "content-type") == "application/xml"
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

        assert conn.method == method_type(method)
        assert conn.host == "localhost"
        assert conn.port == bypass.port
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

  defp test_url(bypass), do: "http://localhost:#{bypass.port}"

  defp method_type(:get),     do: "GET"
  defp method_type(:post),    do: "POST"
  defp method_type(:put),     do: "PUT"
  defp method_type(:patch),   do: "PATCH"
  defp method_type(:delete),  do: "DELETE"
end
