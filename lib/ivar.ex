defmodule Ivar do
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

  @doc """
  """
  def put_body(%{method: method}, _, _) when method in [:get, :delete],
    do: {:error, "Body not allowed for #{Atom.to_string(method)} request"}

  def put_body(request, body, mime_type) when not is_binary(body),
    do: put_body(request, encode_body(body, mime_type), mime_type)

  def put_body(request, body, mime_type) when is_atom(mime_type),
    do: put_body(request, body, get_mime_type(mime_type))

  def put_body(request, body, mime_type) do
    request
      |> Map.put(:body, body)
      |> put_header("content-type", mime_type)
  end

  @doc """
  """
  def put_header(request, key, value) do
    request
      |> Map.get(:headers, %{})
      |> Map.put(key, value)
      |> put_headers(request)
  end

  @doc """
  """
  def put_auth(request, token, :bearer),
    do: Map.put(request, :auth, {:bearer, token})

  def put_auth(request, credentials, :basic),
    do: Map.put(request, :auth, {:basic, credentials})

  @doc """
  """
  def send(request) do
    request = request
      |> prepare_auth

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

  defp put_headers(headers, request),
    do: Map.put(request, :headers, headers)

  defp get_mime_type(type) when is_atom(type),
    do: Map.get(@mime_types, type)
    
  defp get_mime_type(type) when is_binary(type) do
    [ctype | _] = String.split(type, ";")

    @mime_types
      |> Enum.find(fn {_, v} -> v == ctype end)
      |> elem(0)
  end
      
  defp get_mime_type(_), do: nil

  defp prepare_auth(%{auth: {:bearer, token}} = request),
    do: put_header(request, "authorization", "bearer #{token}")
    
  defp prepare_auth(%{auth: {:basic, {user, pass}}} = request) do
    auth = Base.encode64("#{user}:#{pass}")
    put_header(request, "authorization", "basic #{auth}")
  end

  defp prepare_auth(request), do: request
  
  defp encode_body(body, :json),        do: Poison.encode!(body)
  defp encode_body(body, :url_encoded), do: URI.encode_query(body)
  
  defp decode_body(body, nil), do: body
  defp decode_body(body, :json), do: Poison.decode!(body)
  #defp decode_body(body, :url_encoded), do: URI.decode_query(body)
  
  defp get_content_type(headers) do
    Enum.find(headers, &is_content_type_header/1)
      |> elem(1)
      |> get_mime_type
  end
  
  defp is_content_type_header({k, _}),
    do: String.downcase(k) == "content-type"
end