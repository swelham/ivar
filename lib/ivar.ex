defmodule Ivar do
  @moduledoc """
  Documentation for Ivar.
  """

  @doc """
  """
  def new(method, url), do: %{method: method, url: url}

  @doc """
  """
  def put_body(request, body, mime_type) when is_atom(mime_type),
    do: put_body(request, body, get_mime_type(mime_type))

  def put_body(request, body, mime_type) do
    request
      |> Map.put(:body, body)
      |> put_header("content-type", mime_type)
  end

  @doc """
  """
  def send(request) do
    HTTPoison.request(
      request.method,
      request.url,
      "",
      [],
      [])
  end

  defp put_header(request, key, value) do
    request
      |> Map.get(:headers) || %{}
      |> Map.put(key, value)
      |> put_headers(request)
  end

  defp put_headers(headers, request),
    do: Map.put(request, :headers, headers)

  defp get_mime_type(:json),        do: "application/json"
  defp get_mime_type(:xml),         do: "application/xml"
  defp get_mime_type(:url_encoded), do: "application/x-www-form-urlencoded"
end
