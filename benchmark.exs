require Prolly.CountMinSketch, as: Sketch
alias Prolly.BloomFilter

sizes = [1_000, 10_000, 100_000, 1_000_000, 10_000_000]
hashes = [:md5, :sha, :sha256]
value = "this is an example value to check"

bench = Enum.reduce(sizes, %{}, fn(size, acc) ->
  sketch = Sketch.new(3, size, hashes)
  bloom_filter = BloomFilter.new(size, hashes)

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
end)

Benchee.run(
  bench,
  warmup: 5,
  time: 10,
  print: [fast_warning: false]
)
