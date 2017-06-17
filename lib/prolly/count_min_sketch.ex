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

  @type t :: __MODULE__

  # storing depth on the struct is an optimization so it doesn't
  # have to be computed for every single update and query
  defstruct [matrix: nil, hashes: nil, depth: 0]

  @doc """
  Create a CountMinSketch

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> Sketch.new(3, 5, [:sha, :md5, :sha256]).matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]]

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> Sketch.new(3, 5, [:sha, :md5, :sha256]).hashes
      [:sha, :md5, :sha256]
  """
  def new(width, depth, hashes) when is_integer(width) and is_integer(depth)  do
    matrix =
      Enum.map(1..width, fn(_) ->
        Vector.new(Stream.iterate(0, &(&1)) |> Enum.take(depth))
      end)
      |> Vector.new

    %__MODULE__{
      matrix: matrix,
      hashes: hashes,
      depth: depth
    }
  end

  @doc """
  Query a sketch for the count of a given value

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> Sketch.new(3, 5, [:sha, :md5, :sha256]) |> Sketch.update("hi") |> Sketch.get_count("hi")
      1

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5, [:sha, :md5, :sha256])
      ...> |> Sketch.update("hi")
      ...> |> Sketch.update("hi")
      ...> |> Sketch.update("hi")
      iex> Sketch.get_count(sketch, "hi")
      3
  """
  def get_count(%__MODULE__{matrix: matrix, hashes: hashes, depth: depth}, value) do
    hashes
    |> Enum.with_index
    |> Enum.map(fn({hash, i}) ->
      [i, compute_index(hash, value, depth)]
    end)
    |> Enum.map(fn(path) ->
      Kernel.get_in(matrix, path)
    end)
    |> Enum.min
  end

  @doc """
  Update a sketch with a value

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch = Sketch.new(3, 5, [:sha, :md5, :sha256]) |> Sketch.update("hi")
      iex> sketch.matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [0, 1, 0, 0, 0]]
  """
  def update(%__MODULE__{matrix: matrix, hashes: hashes, depth: depth} = sketch, value) do
    new_matrix =
      hashes
      |> Enum.with_index
      |> Enum.reduce(matrix, fn({hash, i}, acc) ->
        Kernel.update_in(
          acc,
          [i, compute_index(hash, value, depth)],
          &(&1 + 1)
        )
      end)

    %{sketch | matrix: new_matrix}
  end

  @doc """
  Union two sketches by cell-wise adding their counts

  ## Examples

      iex> require Prolly.CountMinSketch, as: Sketch
      iex> sketch1 = Sketch.new(3, 5, [:sha, :md5, :sha256]) |> Sketch.update("hi")
      iex> sketch2 = Sketch.new(3, 5, [:sha, :md5, :sha256]) |> Sketch.update("hi")
      iex> Sketch.union(sketch1, sketch2).matrix |> Enum.map(&Vector.to_list(&1))
      [[0, 2, 0, 0, 0], [0, 0, 2, 0, 0], [0, 2, 0, 0, 0]]
  """
  def union(
    %__MODULE__{matrix: matrix1, hashes: hashes, depth: depth} = sketch,
    %__MODULE__{matrix: matrix2}
  ) do
    paths =
      for w <- 0..(Enum.count(hashes) - 1),
          d <- 0..(depth - 1), do: [w, d]

    new_matrix =
      Enum.reduce(paths, matrix1, fn(path, matrix) ->
        Kernel.update_in(matrix, path, fn(first) ->
          first + Kernel.get_in(matrix2, path)
        end)
      end)

    %{sketch | matrix: new_matrix}
  end

  defp compute_index(hash, value, k) do
    :crypto.hash(hash, value)
    |> :binary.bin_to_list
    |> Enum.sum
    |> (fn(n) -> rem(n, k) end).()
  end
end