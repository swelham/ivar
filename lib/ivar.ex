defmodule Ivar do
  @moduledoc """
  Ivar is the top level module used to compose HTTP requests.
  """

  alias Ivar.{
    Auth,
    Body,
    Headers,
    Files,
    QueryString
  }

  @mime_types %{
    json: "application/json",
    xml: "application/xml",
    url_encoded: "application/x-www-form-urlencoded"
  }

  @doc """
  Creates a new request map for the given HTTP `method` and `url` and merges the
  specified `opts` into the application level options defined in the `config.exs`
  
  Args
  
    * `method` - the HTTP method as an atom (`:get`, `:post`, `:delete`, etc...)
    * `url` - a binary containing the full url (e.g. `https://example.com`)
    * `opts` - keyword list containing any valid `HTTPoison` options
    
  Usages
  
      Ivar.new(:get, "https://example.com", [timeout: 10_000])
      %{method: :get, url: "https://example.com", opts: [timeout: 10_000]}
  """
  @spec new(atom, binary, Keyword.t) :: map
  def new(method, url, opts \\ []) do
    opts = :ivar
    |> Application.get_env(:http, [])
    |> Keyword.merge(opts)

    %{method: method, url: url, opts: opts}
  end

  @doc """
  Delegates to `Ivar.Auth.put/3`
  """
  @spec put_auth(map, {tuple | binary}, atom) :: map
  def put_auth(request, credentials, auth_type),
    do: Auth.put(request, credentials, auth_type)

  @doc """
  Delegates to `Ivar.Headers.put/2`
  """
  @spec put_headers(map, {tuple | Keyword.t | map}) :: map
  def put_headers(request, headers),
    do: Headers.put(request, headers)

  @doc """
  Delegates to `Ivar.Body.put/3`
  """
  @spec put_body(map, {map | list | binary}, atom | binary) :: map
  def put_body(request, content, content_type),
    do: Body.put(request, content, content_type)

  @doc """
  Delegates to `Ivar.Files.put/2`
  """
  @spec put_files(map, {tuple | list}) :: map | {:error, binary}
  def put_files(request, files),
    do: Files.put(request, files)

  @doc """
  Delegates to `Ivar.QueryString.put/2`
  """
  @spec put_query_string(map, list | Keyword.t | map) :: map | {:error, binary}
  def put_query_string(request, params),
    do: QueryString.put(request, params)

  @doc """
  Sends the given HTTP `request`
  
  Args
  
    * `request` - the map containing the request options to send, usually created via `Ivar.new/2`
  
  Usage
  
      Ivar.new(:get, "https://example.com")
      |> Ivar.send
      # {:ok, %HTTPoison.Response{}}
  """
  @spec send(map) :: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def send(request) do
    request = request
    |> prepare_auth
    |> prepare_body
    |> prepare_query_string

    HTTPoison.request(
      request.method,
      request.url,
      Map.get(request, :body, ""),
      Map.get(request, :headers, []),
      Map.get(request, :opts, []))
  end

  @doc """
  Receives the result of `Ivar.send/1` and attempts to decode the response body using the
  `content-type` header included in the HTTP response
  
  Args
    
    * `response` - an HTTPoison success or failure response
    
  Usage
    
      Ivar.new(:get, "https://example.com")
      |> Ivar.send
      |> Ivar.unpack
      # {"<!doctype html><html>...", %HTTPoison.Response{}}
  """
  @spec unpack(atom) ::
    {binary | map, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def unpack({:ok, %HTTPoison.Response{body: body} = response}) do
    ctype = get_content_type(response.headers)
    data = decode_body(body, ctype)

    {data, response}
  end
  def unpack(response), do: response

  defp get_mime_type({_, type}),
    do: get_mime_type(type)

  defp get_mime_type(type) when is_atom(type),
    do: Map.get(@mime_types, type)

  defp get_mime_type(type) when is_binary(type) do
    [ctype | _] = String.split(type, ";")

    @mime_types
    |> Enum.find(fn {_, v} -> v == ctype end)
    |> case do
      nil -> nil
      {k, _} -> k
    end
  end
  defp get_mime_type(_), do: nil

  defp prepare_auth(%{auth: {header, value}} = request),
    do: Headers.put(request, header, value)

  defp prepare_auth(request), do: request

  defp prepare_body(%{files: files} = request) do
    content = request
    |> Map.get(:body, "")
    |> get_body_content
    |> decode_body(:url_encoded)
    |> Enum.reduce([], fn (f, acc) -> [f | acc] end)
    |> Kernel.++(files)

    request
    |> Map.put(:body, {:multipart, content})
    |> Map.drop([:files])
  end
  defp prepare_body(%{body: body} = request) do
    {_, header, content} = body

    request
    |> Headers.put(header)
    |> Map.put(:body, content)
  end
  defp prepare_body(request), do: request

  defp prepare_query_string(%{query: query, opts: opts} = request) do
    params = Keyword.get(opts, :params, [])
    params = Enum.into(query, params)

    updated_opts = Keyword.put(opts, :params, params)

    Map.put(request, :opts, updated_opts)
  end
  defp prepare_query_string(request), do: request

  defp decode_body(body, nil), do: body
  defp decode_body(body, :json), do: Poison.decode!(body)
  defp decode_body(body, :url_encoded), do: URI.decode_query(body)

  defp get_content_type(headers) do
    headers
    |> Enum.find(&is_content_type_header?/1)
    |> get_mime_type
  end

  defp is_content_type_header?({k, _}),
    do: String.downcase(k) == "content-type"

  defp get_body_content(""), do: ""
  defp get_body_content({_, _, content}), do: content
end
