defmodule Ivar.Files do
  @moduledoc """
  `Ivar.Files` manages the files to be sent for a request
  """
  
  alias Ivar.Utilities
  
  @valid_types [nil, :multipart, :url_encoded]
  
  @doc """
  Puts the given `files` into the existing `request` map
  
  Args
  
  * `request` - the map used to store the map of headers, usually created via `Ivar.new/2`
  * `files` - the files to be put into the files list
  
  Files
  
  * tuple - `{"field_name", "some iodata", "file_name.txt", "text"}`
  * list - a list of tuples in the same format as above
  
  Usage
  
      file_data = File.read!("/some/image.png")
      Ivar.Files.put(%{}, {"file", file_data, "image.png", "png"})
      # %{files: [{"file", <<1, 2, 3, ...>>, {"form-data", [{"name", "file"}, {"filename", "image.png"}]}, [{"content-type", "image/png"}]}]}
  """
  @spec put(map, {tuple | list}) :: map | {:error, binary}
  def put(request, files) when is_tuple(files),
    do: put(request, [files])
  def put(request, files) do
    if is_valid?(request) do
      request
      |> Map.get(:files, [])
      |> put_files(files)
      |> put_in_request(request)
    else
      {:error, "Files can only be put into a :url_encoded or :multipart body"}
    end
  end
  
  defp put_files(files, []), do: files
  defp put_files(files, [{name, data, file_name, type} | rest]) do
    file = {
      name,
      IO.iodata_to_binary(data),
      {"form-data", [{"name", name}, {"filename", file_name}]},
      [{"content-type", Utilities.get_mime_type(type)}]
    }
    
    put_files([file | files], rest)
  end
  
  defp put_in_request(files, request),
    do: Map.put(request, :files, files)
  
  defp is_valid?(%{body: {type, _, _}}) when type in @valid_types, do: true
  defp is_valid?(request), do: request[:body] == nil
end