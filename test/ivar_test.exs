defmodule IvarTest do
  use ExUnit.Case
  doctest Ivar

  import Ivar.TestMacros

  setup do
    bypass = Bypass.open

    {:ok, bypass: bypass}
  end

  test "new/2 should return a map with the correct http method and url set" do
    url = "https://example.com"
    opts = [params: [{"q", "ivar"}]]
    
    assert Ivar.new(:get,    url) == %{method: :get,    url: url, opts: opts}
    assert Ivar.new(:post,   url) == %{method: :post,   url: url, opts: opts}
    assert Ivar.new(:put,    url) == %{method: :put,    url: url, opts: opts}
    assert Ivar.new(:patch,  url) == %{method: :patch,  url: url, opts: opts}
    assert Ivar.new(:delete, url) == %{method: :delete, url: url, opts: opts}
  end
  
  test "new/3 should merge given options on top of application level options" do
    result = Ivar.new(:get, "", [timeout: 10_000, params: [{"some", "param"}]])
    
    assert result.opts == [timeout: 10_000, params: [{"some", "param"}]]
  end
  
  test "put_auth/3 delegate to Ivar.Auth.put/3" do
    result = Ivar.put_auth(%{}, "token", :bearer)
    
    assert result == %{auth: {"authorization", "bearer token"}}
  end
  
  test "put_headers/3 delegate to Ivar.Headers.put/3" do
    result = Ivar.put_headers(%{}, {"header", "value"})
    
    assert result == %{headers: %{"header" => "value"}}
  end
  
  test "put_body/3 delegate to Ivar.Body.put/3" do
    result = Ivar.put_body(%{}, "some text", "text")
    
    assert result == %{body: {"text/plain", {"content-type", "text/plain"}, "some text"}}
  end
  
  test "put_files/3 delegate to Ivar.Files.put/3" do
    result = Ivar.put_files(%{}, {"file", "some text", "test.txt", "text"})
    
    assert result == %{files: [{"file", "some text", {"form-data", [{"name", "file"}, {"filename", "test.txt"}]}, [{"content-type", "text/plain"}]}]}
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
        |> Ivar.Body.put(%{test: 123}, :url_encoded)
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
        |> Ivar.Headers.put("x-test", "123")
        |> Ivar.Headers.put("x-abc", "xyz")
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
        |> Ivar.Auth.put("some.token", :bearer)
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
        |> Ivar.Auth.put({"username", "password"}, :basic)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with files attached", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)
      
      assert body != nil
      assert has_header(conn, {"content-length", "10322"})
      assert has_multipart_header(conn)
      
      Plug.Conn.send_resp(conn, 200, "")
    end
    
    file_data = File.read!("test/fixtures/elixir.png")
    
    {:ok, result} =
      Ivar.new(:post, test_url(bypass))
      |> Ivar.Files.put({"file", file_data, "elixir.png", "png"})
      |> Ivar.send
      
    assert result.status_code == 200
  end

  test "send/1 should send request with files and body", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      {:ok, body, _} = Plug.Conn.read_body(conn)

      assert body != nil
      assert has_header(conn, {"content-length", "10481"})
      assert has_multipart_header(conn)
      
      Plug.Conn.send_resp(conn, 200, "")
    end
    
    file_data = File.read!("test/fixtures/elixir.png")
    
    {:ok, result} =
      Ivar.new(:post, test_url(bypass))
      |> Ivar.Body.put(%{test: "data"}, :url_encoded)
      |> Ivar.Files.put({"file", file_data, "elixir.png", "png"})
      |> Ivar.send
      
    assert result.status_code == 200
  end

  test "send/1 should use http options specified in application config", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert conn.query_string == "q=ivar"

      Plug.Conn.send_resp(conn, 200, "")
    end

    {:ok, result} =
      Ivar.new(:get, test_url(bypass))
      |> Ivar.send

    assert result.status_code == 200
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
  
  test "unpack/1 should decode a url encoded response", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      conn
        |> Plug.Conn.put_resp_content_type("application/x-www-form-urlencoded")
        |> Plug.Conn.send_resp(200, "test=data")
    end
    
    {result, %HTTPoison.Response{}} =
      Ivar.new(:get, test_url(bypass))
      |> Ivar.send
      |> Ivar.unpack
      
    assert result == %{"test" => "data"}
  end

  test "unpack/1 should return raw response when unknown content type", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      conn
        |> Plug.Conn.put_resp_content_type("unknown/type")
        |> Plug.Conn.send_resp(200, "test=data")
    end
    
    {result, %HTTPoison.Response{}} =
      Ivar.new(:get, test_url(bypass))
      |> Ivar.send
      |> Ivar.unpack
      
    assert result == "test=data"
  end

  test "unpack/1 should return raw response when no content type is found", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      Plug.Conn.send_resp(conn, 200, "test=data")
    end
    
    {result, %HTTPoison.Response{}} =
      Ivar.new(:get, test_url(bypass))
      |> Ivar.send
      |> Ivar.unpack
      
    assert result == "test=data"
  end

  test "unpack/1 should return error when receiving an HTTPoison.Error" do
    test_error = {:error, %HTTPoison.Error{id: 1, reason: "test_error"}}
    
    result = Ivar.unpack(test_error)
    
    assert result == test_error
  end

  defp test_url(bypass), do: "http://localhost:#{bypass.port}/"

  defp method_type(:get),     do: "GET"
  defp method_type(:post),    do: "POST"
  defp method_type(:put),     do: "PUT"
  defp method_type(:patch),   do: "PATCH"
  defp method_type(:delete),  do: "DELETE"
end
