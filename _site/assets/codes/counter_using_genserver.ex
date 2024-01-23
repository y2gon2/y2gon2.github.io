defmodule Counter do
  alias ElixirSense.Providers.Suggestion.GenericReducer
  use GenServer

  #  ------ client API --------

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def increment do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_value do
    GenServer.call(__MODULE__, :get_value)
  end

  # ----------------------------

  # ----- server callback -----

  def init(initial_value) do
    {:ok, initial_value}
  end

  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  def handle_call(:get_value, _from, state) do
    {:noreply, state, state}
  end

  # ----------------------------
end
