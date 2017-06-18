# Prolly

Probabilistic data structures

[![Build Status](https://travis-ci.org/ckampfe/prolly.svg?branch=master)](https://travis-ci.org/ckampfe/prolly)

## Installation

This package is [available in Hex](https://hex.pm/packages/prolly), and can be
installed by adding `prolly` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:prolly, "~> 0.2"}]
end
```

## Use

For examples and use, see [the documentation](https://hexdocs.pm/prolly/api-reference.html).

## Datastructures

- [x] CountMinSketch
- [x] Bloom filter
- [x] HyperLogLog
- [ ] K-Minimum Values

## Rationale

The goals of this library are, in order:

1. Correctness
2. Readability
3. Performance

There are probably other implementations of these data structures in Elixir or Erlang -- or C, for that matter
-- that are more performant. That's ok.

I would rather this library be more digestible and self-evidently correct than the other way around.
That's not to say performance doesn't matter. These kinds of datastructures are useful only insofar as they are performant,
so this library will do its best to realize that goal while still being the most approachable of the bunch.

## Benchmarks

To run the benchmarks:

```
$ mix deps.get && mix deps.compile && mix compile
$ mix run benchmark.exs
```

Benchmarks as of `20170618`:

```
xcxk066$> mix run benchmark.exs
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-4870HQ CPU @ 2.50GHz
Number of Available Cores: 8
Available memory: 17.179869184 GB
Elixir 1.4.4
Erlang 19.3
Benchmark suite executing with the following configuration:
warmup: 5.00 s
time: 10.00 s
parallel: 1
inputs: none specified
Estimated total run time: 8.00 min


Benchmarking bloom filter possible_member? 1000...
Benchmarking bloom filter possible_member? 10000...
Benchmarking bloom filter possible_member? 100000...
Benchmarking bloom filter possible_member? 1000000...
Benchmarking bloom filter update 1000...
Benchmarking bloom filter update 10000...
Benchmarking bloom filter update 100000...
Benchmarking bloom filter update 1000000...
Benchmarking hll phash2 m=16 count 1000...
Benchmarking hll phash2 m=16 count 10000...
Benchmarking hll phash2 m=16 count 100000...
Benchmarking hll phash2 m=16 count 1000000...
Benchmarking hll phash2 m=16 update 1000...
Benchmarking hll phash2 m=16 update 10000...
Benchmarking hll phash2 m=16 update 100000...
Benchmarking hll phash2 m=16 update 1000000...
Benchmarking hll phash2 m=64 count 1000...
Benchmarking hll phash2 m=64 count 10000...
Benchmarking hll phash2 m=64 count 100000...
Benchmarking hll phash2 m=64 count 1000000...
Benchmarking hll phash2 m=64 update 1000...
Benchmarking hll phash2 m=64 update 10000...
Benchmarking hll phash2 m=64 update 100000...
Benchmarking hll phash2 m=64 update 1000000...
Benchmarking sketch get_count 1000...
Benchmarking sketch get_count 10000...
Benchmarking sketch get_count 100000...
Benchmarking sketch get_count 1000000...
Benchmarking sketch update 1000...
Benchmarking sketch update 10000...
Benchmarking sketch update 100000...
Benchmarking sketch update 1000000...

Name                                            ips        average  deviation         median
bloom filter possible_member? 1000         538.47 K        1.86 μs  ±2132.66%        2.00 μs
bloom filter possible_member? 10000        526.57 K        1.90 μs  ±2363.16%        2.00 μs
bloom filter possible_member? 100000       519.92 K        1.92 μs  ±2115.96%        2.00 μs
bloom filter possible_member? 1000000      515.75 K        1.94 μs  ±2688.88%        2.00 μs
hll phash2 m=16 count 1000                 365.48 K        2.74 μs  ±1171.81%        3.00 μs
hll phash2 m=16 count 10000                342.62 K        2.92 μs  ±1253.85%        3.00 μs
hll phash2 m=16 count 1000000              335.43 K        2.98 μs  ±1191.45%        3.00 μs
hll phash2 m=16 count 100000               335.38 K        2.98 μs  ±1244.69%        3.00 μs
bloom filter update 1000                   284.11 K        3.52 μs   ±852.57%        3.00 μs
bloom filter update 10000                  273.51 K        3.66 μs   ±814.49%        3.00 μs
bloom filter update 100000                 266.74 K        3.75 μs   ±863.87%        3.00 μs
bloom filter update 1000000                259.53 K        3.85 μs   ±746.74%        4.00 μs
sketch get_count 1000                      250.27 K        4.00 μs   ±817.72%        4.00 μs
sketch get_count 10000                     245.67 K        4.07 μs   ±716.67%        4.00 μs
sketch get_count 100000                    234.84 K        4.26 μs   ±785.77%        4.00 μs
sketch get_count 1000000                   226.83 K        4.41 μs   ±661.33%        4.00 μs
sketch update 1000                         176.35 K        5.67 μs   ±392.28%        5.00 μs
sketch update 10000                        174.11 K        5.74 μs   ±390.15%        5.00 μs
sketch update 100000                       165.37 K        6.05 μs   ±467.76%        6.00 μs
hll phash2 m=16 update 100000              163.23 K        6.13 μs   ±403.00%        5.00 μs
hll phash2 m=16 update 1000000             162.67 K        6.15 μs   ±385.00%        5.00 μs
hll phash2 m=16 update 1000                157.02 K        6.37 μs   ±405.85%        6.00 μs
hll phash2 m=16 update 10000               156.02 K        6.41 μs   ±413.49%        6.00 μs
sketch update 1000000                      147.72 K        6.77 μs   ±347.44%        6.00 μs
hll phash2 m=64 update 1000                143.84 K        6.95 μs   ±304.67%        6.00 μs
hll phash2 m=64 update 1000000             142.57 K        7.01 μs   ±308.13%        6.00 μs
hll phash2 m=64 update 100000              142.12 K        7.04 μs   ±328.42%        6.00 μs
hll phash2 m=64 update 10000               137.58 K        7.27 μs   ±307.34%        7.00 μs
hll phash2 m=64 count 10000                122.83 K        8.14 μs   ±226.07%        8.00 μs
hll phash2 m=64 count 1000                 120.94 K        8.27 μs   ±248.02%        8.00 μs
hll phash2 m=64 count 100000               120.79 K        8.28 μs   ±261.38%        8.00 μs
hll phash2 m=64 count 1000000              120.31 K        8.31 μs   ±222.56%        8.00 μs

Comparison:
bloom filter possible_member? 1000         538.47 K
bloom filter possible_member? 10000        526.57 K - 1.02x slower
bloom filter possible_member? 100000       519.92 K - 1.04x slower
bloom filter possible_member? 1000000      515.75 K - 1.04x slower
hll phash2 m=16 count 1000                 365.48 K - 1.47x slower
hll phash2 m=16 count 10000                342.62 K - 1.57x slower
hll phash2 m=16 count 1000000              335.43 K - 1.61x slower
hll phash2 m=16 count 100000               335.38 K - 1.61x slower
bloom filter update 1000                   284.11 K - 1.90x slower
bloom filter update 10000                  273.51 K - 1.97x slower
bloom filter update 100000                 266.74 K - 2.02x slower
bloom filter update 1000000                259.53 K - 2.07x slower
sketch get_count 1000                      250.27 K - 2.15x slower
sketch get_count 10000                     245.67 K - 2.19x slower
sketch get_count 100000                    234.84 K - 2.29x slower
sketch get_count 1000000                   226.83 K - 2.37x slower
sketch update 1000                         176.35 K - 3.05x slower
sketch update 10000                        174.11 K - 3.09x slower
sketch update 100000                       165.37 K - 3.26x slower
hll phash2 m=16 update 100000              163.23 K - 3.30x slower
hll phash2 m=16 update 1000000             162.67 K - 3.31x slower
hll phash2 m=16 update 1000                157.02 K - 3.43x slower
hll phash2 m=16 update 10000               156.02 K - 3.45x slower
sketch update 1000000                      147.72 K - 3.65x slower
hll phash2 m=64 update 1000                143.84 K - 3.74x slower
hll phash2 m=64 update 1000000             142.57 K - 3.78x slower
hll phash2 m=64 update 100000              142.12 K - 3.79x slower
hll phash2 m=64 update 10000               137.58 K - 3.91x slower
hll phash2 m=64 count 10000                122.83 K - 4.38x slower
hll phash2 m=64 count 1000                 120.94 K - 4.45x slower
hll phash2 m=64 count 100000               120.79 K - 4.46x slower
hll phash2 m=64 count 1000000              120.31 K - 4.48x slower
```