defmodule Ivar do
  @moduledoc """
  Documentation for Ivar.
  """

  @doc """
  """
  def new(method), do: %{method: method}
  def new(method, url), do: %{method: method, url: url}
end
