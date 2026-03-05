defmodule Cashier.PricingRules.BuyOneGetOneFree do
  @moduledoc """
  Buy-one-get-one-free pricing rule.

  For every two items of the target product, the customer pays for only one.
  If an odd number is purchased, the last one is charged at full price.

  ## Configuration

  No additional configuration required beyond `:product_code`.

  ## Example

      rule = {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"}
  """

  @behaviour Cashier.PricingRule

  @impl true
  def calculate(quantity, price, _opts) do
    payable = div(quantity, 2) + rem(quantity, 2)

    Decimal.mult(price, payable)
  end
end
