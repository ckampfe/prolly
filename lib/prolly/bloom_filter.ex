defmodule Prolly.BloomFilter do
  require Vector

  @moduledoc """
  Use a Bloom filter when you want to keep track of whether
  you have seen a given value or not.

  For example, the quesetion "have I seen the string `foo` so far in the stream?"
  is a reasonble question for a Bloom filter.

  Specifically, a Bloom filter can tell you two things:
  1. When a value *may* be in a set.
  2. When a value is definitely not in a set

  Carefully note that a Bloom filter can only tell you that a value
  might be in a set or that a value is definitely not in a set.
  It cannot tell you that a value is definitely in a set.
  """

  @opaque t :: %__MODULE__{
    filter: Vector.t,
    hash_fns: list((String.t -> integer)),
    m: pos_integer
  }

  defstruct [filter: nil, hash_fns: nil, m: 1]

  @doc """
  Create a Bloom filter.

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end]).filter
      ...> |> Enum.to_list
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  """
  @spec new(pos_integer, list((String.t -> integer))) :: t
  def new(filter_size, hash_fns) when is_integer(filter_size) do
    filter = Vector.new(Enum.map(1..filter_size, fn _ -> 0 end))

    %__MODULE__{
      filter: filter,
      hash_fns: hash_fns,
      m: filter_size
    }
  end

  @doc """
  Find the optimal number of hash functions for a given filter size and expected input size

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.optimal_number_of_hashes(10000, 1000)
      7
  """
  @spec optimal_number_of_hashes(pos_integer, pos_integer) :: pos_integer
  def optimal_number_of_hashes(filter_size, input_size)
  when is_integer(filter_size) and is_integer(input_size) and filter_size > 0 and input_size > 0 do
    (filter_size / input_size) * :math.log(2) |> round
  end

  @doc """
  Find the false positive rate for a given filter size, expected input size, and number of hash functions

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.false_positive_rate(10000, 3000, 3) |> (fn(n) -> :erlang.round(n * 100) / 100 end).()
      0.21
  """
  @spec false_positive_rate(pos_integer, pos_integer, pos_integer) :: float
  def false_positive_rate(filter_size, input_size, number_of_hashes) do
    :math.pow(1 - :math.exp(-number_of_hashes * input_size / filter_size), number_of_hashes)
  end

  @doc """
  Test if something might be in a bloom filter

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      iex> bf = BloomFilter.update(bf, "hi")
      iex> BloomFilter.possible_member?(bf, "hi")
      true

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      iex> bf = BloomFilter.update(bf, "hi")
      iex> BloomFilter.possible_member?(bf, "this is not hi!")
      false

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      iex> bf = BloomFilter.update(bf, 7777777)
      iex> BloomFilter.possible_member?(bf, 7777777)
      true
  """
  @spec possible_member?(t, String.Chars) :: boolean
  def possible_member?(%__MODULE__{filter: filter, hash_fns: hash_fns, m: m}, value) when is_binary(value) do
    Stream.take_while(hash_fns, fn(hash_fn) ->
      filter[compute_index(hash_fn, value, m)] == 1
    end)
    |> Enum.count
    |> (fn(ones) -> ones == Enum.count(hash_fns) end).()
  end

  def possible_member?(%__MODULE__{} = bloom_filter, value) do
    possible_member?(bloom_filter, to_string(value))
  end

  @doc """
  Add a value to a bloom filter

  This operation runs in time proportional to the number
  of hash functions.

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      iex> BloomFilter.update(bf, "hi").filter |> Enum.to_list
      [0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20,
      ...> [fn(value) -> :crypto.hash(:sha, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:md5, value) |> :crypto.bytes_to_integer() end,
      ...>  fn(value) -> :crypto.hash(:sha256, value) |> :crypto.bytes_to_integer() end])
      iex> BloomFilter.update(bf, 12345).filter |> Enum.to_list
      [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]
  """
  @spec update(t, String.Chars) :: t
  def update(%__MODULE__{filter: filter, hash_fns: hash_fns, m: m} = bloom_filter, value) when is_binary(value) do
    new_filter =
      Enum.reduce(hash_fns, filter, fn(hash_fn, acc) ->
        index = compute_index(hash_fn, value, m)
        Vector.put(acc, index, 1)
      end)

    %{bloom_filter | filter: new_filter}
  end

  def update(%__MODULE__{} = bloom_filter, value) do
    update(bloom_filter, to_string(value))
  end

  defp compute_index(hash_fn, value, k) do
    hash_fn.(value) |> (fn(n) -> rem(n, k) end).()
  end
end