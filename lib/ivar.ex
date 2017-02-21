defmodule Ivar do
  @moduledoc """
  Documentation for Ivar.
  """

  @doc """
  """
  def new(method, url), do: %{method: method, url: url}

  @doc """
  """
  def put_body(request, body, mime_type) do
    IO.puts "blah"
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
end
