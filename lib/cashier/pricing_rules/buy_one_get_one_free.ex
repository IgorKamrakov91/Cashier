defmodule Cashier.PricingRules.BuyOneGetOneFree do
  @moduledoc """
  Buy-one-get-one-free: every second item is free.

  Odd items are charged at full price.
  """

  @behaviour Cashier.PricingRule

  @impl true
  def calculate(quantity, price, _opts) do
    payable = div(quantity, 2) + rem(quantity, 2)

    Decimal.mult(price, payable)
  end
end
