ExUnit.start()

defmodule Cashier.Test.CheckoutHelper do
  @moduledoc false

  alias Cashier.Checkout

  @doc """
  Scans a list of product codes into the checkout, asserting each succeeds.
  """
  def scan_items(checkout, items) do
    Enum.each(items, fn item -> :ok = Checkout.scan(checkout, item) end)
  end
end
