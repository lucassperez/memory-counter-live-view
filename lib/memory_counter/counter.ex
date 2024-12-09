defmodule MemoryCounter.Counter do
  defstruct [:id, value: 0]

  def new(value \\ 0) do
    %__MODULE__{value: value}
  end
end
