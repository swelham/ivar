defmodule Ivar do
  @moduledoc """
  Ivar is the top level module used to compose HTTP requests.
  """
  
  alias Ivar.Headers
  
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

    HTTPoison.request(
      request.method,
      request.url,
      Map.get(request, :body, ""),
      Map.get(request, :headers, []),
      [])
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
  @spec unpack(atom) :: {binary | map, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
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
      |> elem(0)
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
  
  defp decode_body(body, nil), do: body
  defp decode_body(body, :json), do: Poison.decode!(body)
  defp decode_body(body, :url_encoded), do: URI.decode_query(body)
  
  defp get_content_type(headers) do
    Enum.find(headers, &is_content_type_header?/1)
      |> elem(1)
      |> get_mime_type
  end
  
  defp is_content_type_header?({k, _}),
    do: String.downcase(k) == "content-type"
    
  defp is_body_valid?("", _), do: ""
  defp is_body_valid?({type, _, content}, target_type) when type == target_type,
    do: content
  defp is_body_valid?({type, _, _}, target_type),
    do: {:error, "Body type was expected to be '#{target_type}' but is #{type}'"}
end