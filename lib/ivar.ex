defmodule Ivar do
  @moduledoc """
  Documentation for Ivar.
  """

  @doc """
  """
  def new(method, url), do: %{method: method, url: url}

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
end
