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

  @type t :: __MODULE__

  defstruct [filter: nil, hashes: nil]

  @doc """
  Create a Bloom filter.

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.new(20, [:md5, :sha, :sha256]).filter |> Enum.to_list
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.new(20, [:md5, :sha, :sha256]).hashes
      [:md5, :sha, :sha256]

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.new(20, Enum.into([:md5, :sha, :sha256], MapSet.new)).hashes
      #MapSet<[:md5, :sha, :sha256]>
  """
  def new(filter_size, hashes) when is_integer(filter_size) do
    filter = Vector.new(Stream.iterate(0, &(&1)) |> Enum.take(filter_size))

    %__MODULE__{
      filter: filter,
      hashes: hashes
    }
  end

  @doc """
  Find the optimal number of hash functions for a given filter size and expected input size

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.optimal_number_of_hashes(10000, 1000) |> round
      7
  """
  def optimal_number_of_hashes(filter_size, input_size) do
    (filter_size / input_size) * :math.log(2)
  end

  @doc """
  Find the false positive rate for a given filter size, expected input size, and number of hash functions

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> BloomFilter.false_positive_rate(10000, 3000, 3) |> (fn(n) -> :erlang.round(n * 100) / 100 end).()
      0.21
  """
  def false_positive_rate(filter_size, input_size, number_of_hashes) do
    :math.pow(1 - :math.exp(-number_of_hashes * input_size / filter_size), number_of_hashes)
  end

  @doc """
  Test if something might be in a bloom filter

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20, [:md5, :sha, :sha256])
      iex> bf = BloomFilter.update(bf, "hi")
      iex> BloomFilter.possible_member?(bf, "hi")
      true

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20, [:md5, :sha, :sha256])
      iex> bf = BloomFilter.update(bf, "hi")
      iex> BloomFilter.possible_member?(bf, "this is not hi!")
      false
  """
  def possible_member?(%__MODULE__{filter: filter, hashes: hashes}, value) do
    m = Vector.size(filter)
    Stream.take_while(hashes, fn(hash) ->
      filter[compute_index(hash, value, m)] == 1
    end)
    |> Enum.count
    |> (fn(ones) -> ones == Enum.count(hashes) end).()
  end

  @doc """
  Add a value to a bloom filter

  This operation runs in time proportional to the number
  of hash functions.

  ## Examples

      iex> alias Prolly.BloomFilter
      iex> bf = BloomFilter.new(20, [:md5, :sha, :sha256])
      iex> BloomFilter.update(bf, "hi").filter |> Enum.to_list
      [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  """
  def update(%__MODULE__{filter: filter, hashes: hashes} = bloom_filter, value) do
    string_value = to_string(value)
    m = Vector.size(filter)

    new_filter =
      Enum.reduce(hashes, filter, fn(hash, acc) ->
        index = compute_index(hash, string_value, m)
        Vector.put(acc, index, 1)
      end)

    %{bloom_filter | filter: new_filter}
  end

  defp compute_index(hash, value, m) do
    :crypto.hash(hash, value)
    |> :binary.bin_to_list
    |> Enum.sum
    |> (fn(n) -> rem(n, m) end).()
  end
end