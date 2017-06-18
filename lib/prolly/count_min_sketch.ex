defmodule Prolly.CountMinSketch do
  require Vector

  @moduledoc """
  Use CountMinSketch when you want to count and query the
  approximate number of occurences of values in a stream using sublinear memory

  For example, "how many times has the string `foo` been in the stream so far?" is
  a reasonable question for CountMinSketch.

  A CountMinSketch will not undercount occurences, but may overcount occurences,
  reporting a count that is higher than the real number of occurences for a given
  value.
  """

  @opaque t :: %__MODULE__{
    matrix: Vector.t,
    hash_fns: list((String.t -> integer)),
    depth: pos_integer
  }

  # storing depth on the struct is an optimization so it doesn't
  # have to be computed for every single update and query
  defstruct [matrix: nil, hash_fns: nil, depth: 1]

  @doc """
  Create a CountMinSketch

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end]).matrix
      ...> |> Enum.map(&Vector.to_list(&1))
      [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]
  """
  @spec new(pos_integer, pos_integer, list((String.t -> integer))) :: t
  def new(width, depth, hash_fns) when is_integer(width) and is_integer(depth)  do
    matrix =
      Enum.map(1..width, fn(_) ->
        Vector.new(Enum.map(1..depth, fn _ -> 0 end))
      end)
      |> Vector.new

    %__MODULE__{
      matrix: matrix,
      hash_fns: hash_fns,
      depth: depth
    }
  end

  @doc """
  Query a sketch for the count of a given value

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update("hi") |> Sketch.get_count("hi")
      1

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update("hi")
      ...> |> Sketch.update("hi")
      ...> |> Sketch.update("hi")
      iex> Sketch.get_count(sketch, "hi")
      3

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update([77, "list"])
      ...> |> Sketch.update([77, "list"])
      ...> |> Sketch.update([77, "list"])
      ...> |> Sketch.update([77, "list"])
      ...> |> Sketch.update([77, "list"])
      iex> Sketch.get_count(sketch, [77, "list"])
      5
  """
  @spec get_count(t, String.Chars) :: integer
  def get_count(%__MODULE__{matrix: matrix, hash_fns: hash_fns, depth: depth}, value) when is_binary(value) do
    hash_fns
    |> Enum.with_index
    |> Enum.map(fn({hash_fn, i}) ->
      [i, compute_index(hash_fn, value, depth)]
    end)
    |> Enum.map(fn(path) ->
      Kernel.get_in(matrix, path)
    end)
    |> Enum.min
  end

  def get_count(%__MODULE__{} = sketch, value) do
    get_count(sketch, to_string(value))
  end

  @doc """
  Update a sketch with a value

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update("hi")
      iex> sketch.matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [0, 1, 0, 0, 0]]

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update(["a", "list", "of", "things"])
      iex> sketch.matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 0, 0, 0, 1], [0, 0, 1, 0, 0], [0, 0, 1, 0, 0]]
  """
  @spec update(t, String.Chars) :: t
  def update(%__MODULE__{matrix: matrix, hash_fns: hash_fns, depth: depth} = sketch, value) when is_binary(value) do
    new_matrix =
      hash_fns
      |> Enum.with_index
      |> Enum.reduce(matrix, fn({hash_fn, i}, acc) ->
        Kernel.update_in(
          acc,
          [i, compute_index(hash_fn, value, depth)],
          &(&1 + 1)
        )
      end)

    %{sketch | matrix: new_matrix}
  end

  def update(%__MODULE__{} = sketch, value) do
    update(sketch, to_string(value))
  end

  @doc """
  Union two sketches by cell-wise adding their counts

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch1 = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update("hi")
      iex> sketch2 = Sketch.new(3, 5,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      ...> |> Sketch.update("hi")
      iex> Sketch.union(sketch1, sketch2).matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 2, 0, 0, 0], [0, 0, 2, 0, 0], [0, 2, 0, 0, 0]]
  """
  @spec union(t, t) :: t
  def union(
    %__MODULE__{matrix: matrix1, hash_fns: hash_fns, depth: depth} = sketch1,
    %__MODULE__{matrix: matrix2} = _sketch2
  ) do
    paths =
      for w <- 0..(Enum.count(hash_fns) - 1),
          d <- 0..(depth - 1), do: [w, d]

    new_matrix =
      Enum.reduce(paths, matrix1, fn(path, matrix) ->
        Kernel.update_in(matrix, path, fn(first) ->
          first + Kernel.get_in(matrix2, path)
        end)
      end)

    %{sketch1 | matrix: new_matrix}
  end

  defp compute_index(hash_fn, value, k) do
    hash_fn.(value) |> (fn(n) -> rem(n, k) end).()
  end
end