defmodule Ivar.Adapter do
  @moduledoc """
  Specifies API required for an Ivar adapter to implement.
  """
  
  @doc """
  Callback used to execute the given `request`.
  """
  @callback execute(request :: map) :: tuple
end