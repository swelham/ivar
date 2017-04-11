defmodule Ivar do
  @moduledoc """
  Ivar is the top level module used to compose HTTP requests.
  """

  alias Ivar.{
    Auth,
    Body,
    Headers,
    Files
  }

  @mime_types %{
    json: "application/json",
    xml: "application/xml",
    url_encoded: "application/x-www-form-urlencoded"
  }

  @doc """
  Creates a new request map for the given HTTP `method` and `url`
  
  Args
  
    * `method` - the HTTP method as an atom (`:get`, `:post`, `:delete`, etc...)
    * `url` - a binary containing the full url (e.g. `https://example.com`)
    
  Usages
  
      iex> Ivar.new(:get, "https://example.com")
      %{method: :get, url: "https://example.com"}
  """
  @spec new(atom, binary) :: map
  def new(method, url), do: %{method: method, url: url}

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

    opts = []
    |> prepare_opts

    HTTPoison.request(
      request.method,
      request.url,
      Map.get(request, :body, ""),
      Map.get(request, :headers, []),
      opts)
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
    |> is_body_valid?(:url_encoded)
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

  defp prepare_opts(opts) do
    case Application.get_env(:ivar, :http) do
      nil -> opts
      http -> http || [] ++ opts
    end
  end

  defp decode_body(body, nil), do: body
  defp decode_body(body, :json), do: Poison.decode!(body)
  defp decode_body(body, :url_encoded), do: URI.decode_query(body)

  defp get_content_type(headers) do
    with {_, v} <- Enum.find(headers, &is_content_type_header?/1),
         type   <- get_mime_type(v)
    do
      type
    else
      nil
    end
  end

  defp is_content_type_header?({k, _}),
    do: String.downcase(k) == "content-type"

  defp is_body_valid?("", _), do: ""
  defp is_body_valid?({type, _, content}, target_type) when type == target_type,
    do: content
  defp is_body_valid?({type, _, _}, target_type),
    do: {:error, "Body type was expected to be '#{target_type}' but is #{type}'"}
end
