alias Prolly.BloomFilter
require Prolly.CountMinSketch, as: Sketch
require Prolly.HyperLogLog, as: HLL

sizes = [1_000, 10_000, 100_000, 1_000_000]
hashes = [:md5, :sha, :sha256]
value = "this is an example value to check"

bench = Enum.reduce(sizes, %{}, fn(size, acc) ->
  sketch = Sketch.new(3, size, hashes)
  bloom_filter = BloomFilter.new(size, hashes)

  hyper_log_log_phash2_16 =
    HLL.new(16, fn(value) -> :erlang.phash2(value) end)
  hyper_log_log_phash2_16 =
    Enum.reduce(1..size, hyper_log_log_phash2_16, fn(val, acc) ->
      HLL.update(acc, val)
    end)

  hyper_log_log_phash2_64 =
    HLL.new(64, fn(value) -> :erlang.phash2(value) end)
  hyper_log_log_phash2_64 =
    Enum.reduce(1..size, hyper_log_log_phash2_64, fn(val, acc) ->
      HLL.update(acc, val)
    end)

  acc
  |> Map.put(
    "sketch update #{size}",
    fn -> Sketch.update(sketch, value) end
  )
  |> Map.put(
    "sketch get_count #{size}",
    fn -> Sketch.get_count(sketch, value) end
  )
  |> Map.put(
    "bloom filter update #{size}",
    fn -> BloomFilter.update(bloom_filter, value) end
  )
  |> Map.put(
    "bloom filter possible_member? #{size}",
    fn -> BloomFilter.possible_member?(bloom_filter, value) end
  )
  |> Map.put(
    "hll phash2 m=16 update #{size}",
    fn -> HLL.update(hyper_log_log_phash2_16, value) end
  )
  |> Map.put(
    "hll phash2 m=16 count #{size}",
    fn -> HLL.count(hyper_log_log_phash2_16) end
  )
  |> Map.put(
    "hll phash2 m=64 update #{size}",
    fn -> HLL.update(hyper_log_log_phash2_64, value) end
  )
  |> Map.put(
    "hll phash2 m=64 count #{size}",
    fn -> HLL.count(hyper_log_log_phash2_64) end
  )
end)

Benchee.run(
  bench,
  warmup: 5,
  time: 10,
  print: [fast_warning: false]
)
