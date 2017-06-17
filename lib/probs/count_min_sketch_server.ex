defmodule Prolly.CountMinSketchServer do
  require Prolly.CountMinSketch, as: Sketch
  use GenServer

  # API

  @spec start_link(pos_integer, pos_integer, list(atom)) :: GenServer.on_start
  def start_link(width, depth, hashes \\ [:md5, :sha, :sha256]) do
    GenServer.start_link(__MODULE__, [width, depth, hashes], [name: __MODULE__])
  end

  @spec get_state() :: Sketch.t
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @spec get_count(term) :: integer
  def get_count(value) do
    GenServer.call(__MODULE__, {:get_count, value})
  end

  @spec update(term) :: :ok
  def update(value) do
    GenServer.call(__MODULE__, {:update, value})
  end

  # CALLBACKS

  def init([width, depth, hashes]) do
    state = Sketch.new(width, depth, hashes)
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:get_count, value}, _from, state) do
    count = Sketch.get_count(state, value)
    {:reply, count, state}
  end

  def handle_call({:update, value}, _from, state) do
    new_state = Sketch.update(state, value)
    {:reply, :ok, new_state}
  end
end
