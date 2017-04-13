defmodule Ivar.Utilities do
  @moduledoc """
  `Ivar.Utilities` is a collection of utility functions used for building requests
  """

  @doc """
  Returns the mime type for a given `type`
  
  Args
  
  * `type` - a binary including the mime extension or a custom mime type
  
  Type
  
  * mime extension - `"jpg"` would return `"image/jpeg"`
  * custom mime type - `"custom/type"` any input containing a `/` is considered a custom type
  
  Usage
  
      iex> Ivar.Utilities.get_mime_type("png")
      "image/png"
      
      iex> Ivar.Utilities.get_mime_type("custom/type")
      "custom/type"
  """
  @spec get_mime_type(binary) :: binary
  def get_mime_type(type) do
    if Regex.match?(~r/\//, type),
        do: type,
        else: :mimerl.extension(type)
  end
end
