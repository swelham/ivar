defmodule Ivar.Adapter do
  @moduledoc """
  Specifies API required for an Ivar adapter to implement.
  """
  
  @doc """
  Callback used to executes the given `request`.
  """
  @callback init(request :: map) :: tuple
end