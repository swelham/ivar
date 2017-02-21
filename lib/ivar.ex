defmodule Ivar do
  @moduledoc """
  Documentation for Ivar.
  """

  @doc """
  """
  def new(method, url), do: %{method: method, url: url}

  @doc """
  """
  def put_body(%{method: method}, _, _) when method in [:get, :delete],
    do: {:error, "Body not allowed for #{Atom.to_string(method)} request"}

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
  def put_auth(request, :bearer, token),
    do: Map.put(request, :auth, {:bearer, token})

  def put_auth(request, :basic, credentials),
    do: Map.put(request, :auth, {:basic, credentials})

  @doc """
  """
  def send(request) do
    request = request
      |> prepare_auth

    opts = []
      |> put_basic_auth(request)

    HTTPoison.request(
      request.method,
      request.url,
      Map.get(request, :body, ""),
      Map.get(request, :headers, []),
      opts)
  end

  defp put_headers(headers, request),
    do: Map.put(request, :headers, headers)

  defp get_mime_type(:json),        do: "application/json"
  defp get_mime_type(:xml),         do: "application/xml"
  defp get_mime_type(:url_encoded), do: "application/x-www-form-urlencoded"

  defp prepare_auth(%{auth: {:bearer, token}} = request),
    do: put_header(request, "authorization", "bearer #{token}")

  defp prepare_auth(request), do: request

  defp put_basic_auth(opts, %{auth: {:basic, credentials}}),
    do: [hackney: [basic_auth: credentials]] ++ opts
    
  defp put_basic_auth(opts, _), do: opts
end