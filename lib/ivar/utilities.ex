defmodule Ivar.Utilities do
  @moduledoc """
  `Ivar.Utilities` is a collection of utility functions used for building requests
  """

  @doc """
  Returns the mime type for a given `type`
  
  Args
  
  * `type` - a binary including the mime extension or a custom mime type
  * `:ext | :file` - the atom `:ext` to look up an extension or `:file` to look up a file name
  
  Type
  
  * mime extension - `"jpg"` would return `"image/jpeg"`
  * custom mime type - `"custom/type"` any input containing a `/` is considered a custom type
  
  Usage
  
      iex> Ivar.Utilities.get_mime_type("png", :ext)
      "image/png"
      
      iex> Ivar.Utilities.get_mime_type("custom/type", :ext)
      "custom/type"
      
      iex> Ivar.Utilities.get_mime_type("elixir.png", :file)
      "image/png"
  """
  @spec get_mime_type(binary, atom) :: binary
  def get_mime_type(type, :ext) do
    if Regex.match?(~r/\//, type),
        do: type,
        else: :mimerl.extension(type)
  end
  def get_mime_type(file_name, :file),
    do: :mimerl.filename(file_name)
end
