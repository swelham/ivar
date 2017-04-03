defmodule Ivar do
  alias Ivar.Headers
  
  @moduledoc """
  Documentation for Ivar.
  """
  
  @mime_types %{
    json: "application/json",
    xml: "application/xml",
    url_encoded: "application/x-www-form-urlencoded"
  }

  @doc """
  """
  def new(method, url), do: %{method: method, url: url}

  # @doc """
  # """
  # def put_body(%{method: method}, _, _) when method in [:get, :delete],
  #   do: {:error, "Body not allowed for #{Atom.to_string(method)} request"}

  # def put_body(request, body, mime_type) when not is_binary(body),
  #   do: put_body(request, encode_body(body, mime_type), mime_type)

  # def put_body(request, body, mime_type) when is_atom(mime_type),
  #   do: put_body(request, body, get_mime_type(mime_type))

  # def put_body(request, body, mime_type) do
  #   request
  #     |> Map.put(:body, body)
  #     |> Headers.put("content-type", mime_type)
  # end

  # @doc """
  # """
  # def put_auth(request, token, :bearer),
  #   do: Map.put(request, :auth, {:bearer, token})

  # def put_auth(request, credentials, :basic),
  #   do: Map.put(request, :auth, {:basic, credentials})

  @doc """
  """
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
  """
  def unpack({:ok, %HTTPoison.Response{body: body} = response}) do
    ctype = get_content_type(response.headers)
    data = decode_body(body, ctype)
    
    {data, response}
  end

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
    Enum.find(headers, &is_content_type_header/1)
      |> elem(1)
      |> get_mime_type
  end
  
  defp is_content_type_header({k, _}),
    do: String.downcase(k) == "content-type"
end