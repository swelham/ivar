defmodule IvarTest do
  use ExUnit.Case
  doctest Ivar

  import Ivar.TestMacros

  @example_url "https://example.com"
  @test_url "https://localhost:1234"
  @default_opts [params: [{"q", "ivar"}]]

  test "new/2 should return a map with the correct http method and url set" do
    url = @example_url
    opts = @default_opts
    
    assert Ivar.new(:get,     url) == %{method: :get,     url: url, opts: opts}
    assert Ivar.new(:post,    url) == %{method: :post,    url: url, opts: opts}
    assert Ivar.new(:put,     url) == %{method: :put,     url: url, opts: opts}
    assert Ivar.new(:patch,   url) == %{method: :patch,   url: url, opts: opts}
    assert Ivar.new(:delete,  url) == %{method: :delete,  url: url, opts: opts}
    assert Ivar.new(:options, url) == %{method: :options, url: url, opts: opts}
  end
  
  test "new/3 should merge given options on top of application level options" do
    result = Ivar.new(:get, "", [timeout: 10_000, params: [{"some", "param"}]])
    
    assert result.opts == [timeout: 10_000, params: [{"some", "param"}]]
  end
  
  test "get/2 should return a map with the correct http method and url set" do
    assert Ivar.get(@example_url) == %{method: :get, url: @example_url, opts: @default_opts}
  end
  
  test "post/2 should return a map with the correct http method and url set" do
    assert Ivar.post(@example_url) == %{method: :post, url: @example_url, opts: @default_opts}
  end
  
  test "put/2 should return a map with the correct http method and url set" do
    assert Ivar.put(@example_url) == %{method: :put, url: @example_url, opts: @default_opts}
  end
  
  test "patch/2 should return a map with the correct http method and url set" do
    assert Ivar.patch(@example_url) == %{method: :patch, url: @example_url, opts: @default_opts}
  end

  test "delete/2 should return a map with the correct http method and url set" do
    assert Ivar.delete(@example_url) == %{method: :delete, url: @example_url, opts: @default_opts}
  end

  test "options/2 should return a map with the correct http method and url set" do
    assert Ivar.options(@example_url) == %{method: :options, url: @example_url, opts: @default_opts}
  end

  test "put_auth/3 delegate to Ivar.Auth.put/3" do
    result = Ivar.put_auth(%{}, "token", :bearer)
    
    assert result == %{auth: {"authorization", "Bearer token"}}
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

  test "put_query_string/2 delegate to Ivar.QueryString.put/2" do
    result = Ivar.put_query_string(%{}, [q: "ivar"])
    
    assert result == %{query: %{"q" => "ivar"}}
  end

  test "send/1 should send minimal empty request" do
    methods = [:get, :post, :patch, :put, :delete, :options]

    for method <- methods do
      handler = fn req ->
        assert req.method == method_type(method)
        assert req.host == "localhost"
        assert req.port == 1234
        {:ok, nil}
      end

      {:ok, result} =
        Ivar.new(method, @test_url, handler: handler)
        |> Ivar.send()
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with body" do
    methods = [:post, :patch, :put]

    for method <- methods do
      handler = fn req ->
        assert has_header(req, {"content-type", "application/x-www-form-urlencoded"})
        assert req.body == "test=123"
        {:ok, nil}
      end

      {:ok, result} =
        Ivar.new(method, @test_url, handler: handler)
        |> Ivar.Body.put(%{test: 123}, :url_encoded)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with headers" do
    methods = [:get, :post, :patch, :put, :delete, :options]

    for method <- methods do
      handler = fn req ->
        assert has_header(req, {"x-test", "123"})
        assert has_header(req, {"x-abc", "xyz"})
        {:ok, nil}
      end

      {:ok, result} =
        Ivar.new(method, @test_url, handler: handler)
        |> Ivar.Headers.put("x-test", "123")
        |> Ivar.Headers.put("x-abc", "xyz")
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with bearer auth header" do
    methods = [:get, :post, :patch, :put, :delete, :options]

    for method <- methods do
      handler = fn req ->
        assert has_header(req, {"authorization", "Bearer some.token"})
        {:ok, nil}
      end

      {:ok, result} =
        Ivar.new(method, @test_url, handler: handler)
        |> Ivar.Auth.put("some.token", :bearer)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with basic auth header" do
    methods = [:get, :post, :patch, :put, :delete, :options]

    for method <- methods do
      handler = fn req ->
        assert has_header(req, {"authorization", "Basic dXNlcm5hbWU6cGFzc3dvcmQ="})
        {:ok, nil}
      end

      {:ok, result} =
        Ivar.new(method, @test_url, handler: handler)
        |> Ivar.Auth.put({"username", "password"}, :basic)
        |> Ivar.send
      
      assert result.status_code == 200
    end
  end

  test "send/1 should send request with files" do
    handler = fn req ->
      assert req.files_count == 1
      {:ok, nil}
    end
    
    file_data = File.read!("test/fixtures/elixir.png")
    
    {:ok, result} =
      Ivar.new(:post, @test_url, handler: handler)
      |> Ivar.Files.put({"file", file_data, "elixir.png", "png"})
      |> Ivar.send
      
    assert result.status_code == 200
  end

  test "send/1 should send request with files and body" do
    handler = fn req ->
      assert req.body != nil
      assert req.files_count == 1
      {:ok, nil}
    end
    
    file_data = File.read!("test/fixtures/elixir.png")
    
    {:ok, result} =
      Ivar.new(:post, @test_url, handler: handler)
      |> Ivar.Body.put(%{test: "data"}, :url_encoded)
      |> Ivar.Files.put({"file", file_data, "elixir.png", "png"})
      |> Ivar.send
      
    assert result.status_code == 200
  end

  test "send/1 should use http options specified in application config" do
    handler = fn req ->
      assert req.query == "q=ivar"
      {:ok, nil}
    end

    {:ok, result} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.send

    assert result.status_code == 200
  end

  test "send/1 should set query string" do
    handler = fn req ->
      assert req.query == "q=ivar&my=query"
      {:ok, nil}
    end

    {:ok, result} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.put_query_string([my: "query"])
      |> Ivar.send

    assert result.status_code == 200
  end

  test "send/1 should set query string when no default params are set" do
    handler = fn req ->
      assert req.query == "my=query"
      {:ok, nil}
    end

    {:ok, result} =
      Ivar.new(:get, @test_url, params: [], handler: handler)
      |> Ivar.put_query_string([my: "query"])
      |> Ivar.send

    assert result.status_code == 200
  end

  test "unpack/1 should decode a json response" do
    handler = fn _ ->
      {:ok, {200, :json, "{\"test\":\"data\"}"}}
    end
    
    {data, _} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.send
      |> Ivar.unpack
      
    assert data == %{"test" => "data"}
  end

  test "unpack/1 should decode a url encoded response" do
    handler = fn _ ->
      {:ok, {200, :url_encoded, "test=data"}}
    end
    
    {data, _} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.send
      |> Ivar.unpack

    assert data == %{"test" => "data"}
  end

  test "unpack/1 should return raw response when unknown content type" do
    handler = fn _ ->
      {:ok, {200, "unknown/type", "test=data"}}
    end
    
    {data, _} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.send
      |> Ivar.unpack
      
    assert data == "test=data"
  end

  test "unpack/1 should return raw response when no content type is found" do
    handler = fn _ ->
      {:ok, {200, "test=data"}}
    end
    
    {data, _} =
      Ivar.new(:get, @test_url, handler: handler)
      |> Ivar.send
      |> Ivar.unpack
      
    assert data == "test=data"
  end

  test "unpack/1 should return error when receiving an error response" do
    test_error = {:error, %{reason: "test_error"}}
    
    result = Ivar.unpack(test_error)
    
    assert result == test_error
  end

  defp method_type(:get),     do: "GET"
  defp method_type(:post),    do: "POST"
  defp method_type(:put),     do: "PUT"
  defp method_type(:patch),   do: "PATCH"
  defp method_type(:delete),  do: "DELETE"
  defp method_type(:options), do: "OPTIONS"
end
