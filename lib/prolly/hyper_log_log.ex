defmodule Prolly.HyperLogLog do
  require Vector
  import Bitwise, only: [<<<: 2]

  @moduledoc """
  Use HyperLogLog when you want to count the numer of distinct elements in a stream in sublinear memory

  `m` = the number of registers, >= 16

  `a` = the "alpha" corrective factor, varied by `m`

  `b` = the number of least-significant bits that go toward the index. Must be `log2(m)`, ie 64 registers
  means the 6 rightmost bits are the ones devoted to determining a registers

  `alpha_m_squared` = `a * m * m`, memoized
  """

  @opaque t :: %__MODULE__{
    registers: Vector.t,
    hash_fn: (term -> integer),
    m: pos_integer,
    a: float,
    b: pos_integer,
    alpha_m_squared: float
  }

  defstruct [registers: nil, hash_fn: nil, m: 0, a: 0.0, b: 0, alpha_m_squared: 0.0]

  @doc """
  Create a new HyperLogLog

  ## Examples

      iex> require Prolly.HyperLogLog, as: HLL
      iex> HLL.new(64, fn(value) -> :erlang.phash2(value) end).m
      64

      iex> require Prolly.HyperLogLog, as: HLL
      iex> HLL.new(64, fn(value) -> :erlang.phash2(value) end).a
      0.709

      iex> require Prolly.HyperLogLog, as: HLL
      iex> HLL.new(64, fn(value) -> :erlang.phash2(value) end).b
      6

      iex> require Prolly.HyperLogLog, as: HLL
      iex> HLL.new(64, fn(value) -> :erlang.phash2(value) end).alpha_m_squared
      2904.064

      iex> require Prolly.HyperLogLog, as: HLL
      iex> HLL.new(64, fn(value) -> :erlang.phash2(value) end).registers |> Vector.to_list
      Enum.map(1..64, fn _ -> 0 end)
  """
  @spec new(pos_integer, (term -> integer)) :: t
  def new(m, hash_fn) when is_integer(m) and is_function(hash_fn) and m > 0 do
    registers = Vector.new(Enum.map(1..m, fn _ -> 0 end))
    a = compute_alpha(m)
    b = :math.log2(m) |> round()

    %__MODULE__{
      registers: registers,
      hash_fn: hash_fn,
      m: m,
      a: a,
      b: b,
      alpha_m_squared: a * m * m
    }
  end

  @doc """
  Update a HyperLogLog wth a `String`

  ## Examples

      iex> require Prolly.HyperLogLog, as: HLL
      iex> hll = HLL.new(64, fn(value) -> :erlang.phash2(value) end)
      iex> HLL.update(hll, "hi").registers |> Vector.to_list
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  """
  @spec update(t, String.t) :: t
  def update(%__MODULE__{registers: registers, hash_fn: hash_fn, b: b} = loglog, value) when is_binary(value) do
    value_hash_bits = compute_value_hash_bits(hash_fn, value)
    index = compute_index(value_hash_bits, b)
    run_length = run_length(value_hash_bits, b)

    new_registers =
      Vector.update!(registers, index, fn(old_value) ->
        max(old_value, run_length + 1)
      end)

    %{loglog | registers: new_registers}
  end

  @doc """
  Update a HyperLogLog with any term

  ## Examples

      iex> require Prolly.HyperLogLog, as: HLL
      iex> hll = HLL.new(64, fn(value) -> :erlang.phash2(value) end)
      iex> HLL.update(hll, 4242).registers |> Vector.to_list
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
       0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
  """
  @spec update(t, term) :: t
  def update(%__MODULE__{} = loglog, value) do
    update(loglog, to_string(value))
  end

  @doc """
  Get the count-distinct from a HyperLogLog

  ## Examples

      iex> require Prolly.HyperLogLog, as: HLL
      iex> hll = HLL.new(64, fn(value) -> :erlang.phash2(value) end)
      iex> Enum.reduce(1..5800, hll, fn(val, acc) -> HLL.update(acc, val) end) |> HLL.count
      5813
  """
  @spec count(t) :: integer
  def count(%__MODULE__{} = loglog) do
    cardinality_estimate = cardinality_estimate(loglog)
    correct_estimate(cardinality_estimate, loglog) |> round
  end

  defp cardinality_estimate(%__MODULE__{registers: registers, alpha_m_squared: alpha_m_squared}) do
    harmonic_sum_of_registers = harmonic_sum_of_registers(registers)
    if harmonic_sum_of_registers == 0 do
      0
    else
      alpha_m_squared * 1 / harmonic_sum_of_registers
    end
  end

  defp correct_estimate(cardinality_estimate, %__MODULE__{m: m} = loglog) do
    cond do
      cardinality_estimate < (5 * m / 2) ->
        small_range_correction(cardinality_estimate, loglog)

      cardinality_estimate <= (1 / 30 * :math.pow(2, 32)) ->
        cardinality_estimate

      true ->
        large_range_correction(cardinality_estimate)
    end
  end

  defp small_range_correction(cardinality_estimate, %__MODULE__{registers: registers, m: m}) do
    count_of_zero_registers =
      registers
      |> Enum.filter(fn(register) -> register == 0 end)
      |> Enum.count

    case count_of_zero_registers do
      0 ->  cardinality_estimate
      _ -> m * :math.log(m / count_of_zero_registers)
    end
  end

  defp large_range_correction(cardinality_estimate) do
    :math.pow(-2, 32) * :math.log(1 - cardinality_estimate / :math.pow(2, 32))
  end

  defp harmonic_sum_of_registers(registers) do
    nonzero_values = Enum.filter(registers, fn(register) -> register > 0 end)

    Enum.reduce(nonzero_values, 0, fn(register, acc) ->
      acc + (1 / (1 <<< register))
    end)
  end

  defp compute_alpha(16), do: 0.673
  defp compute_alpha(32), do: 0.697
  defp compute_alpha(64), do: 0.709
  defp compute_alpha(number_of_registers), do: 0.7213 / (1 + 1.079 / number_of_registers)

  defp run_length(compute_value_hash_bits, number_of_index_bits) do
    (Vector.size(compute_value_hash_bits) - number_of_index_bits - 1)..0
    |> Stream.take_while(fn(n) ->
      compute_value_hash_bits[n] == 0
    end)
    |> Enum.count()
  end

  defp compute_value_hash_bits(hash_fn, value) do
    hash_fn.(value)
    |> Integer.digits(2)
    |> Vector.new()
  end

  defp compute_index(value_hash_bits, number_of_index_bits) do
    Enum.reduce(1..number_of_index_bits, [], fn(n, acc) ->
      index_bit = value_hash_bits[-n]
      [index_bit|acc]
    end)
    |> Integer.undigits(2)
  end
end