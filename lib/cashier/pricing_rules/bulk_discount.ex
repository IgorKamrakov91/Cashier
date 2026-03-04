defmodule Cashier.PricingRules.BulkDiscount do
  @moduledoc """
  Bulk discount pricing rule.

  When the quantity of a product reaches a threshold, the price per item
  drops to a configured discount price.

  ## Configuration

  - `:product_code` (required) — the product code this rule applies to
  - `:threshold` (required) — minimum quantity to trigger the discount
  - `:discount_price` (required) — the new price per item (as string or Decimal)

  ## Example

      rule = {Cashier.PricingRules.BulkDiscount,
              product_code: "SR1", threshold: 3, discount_price: "4.50"}
  """

  @behaviour Cashier.PricingRule

  alias Cashier.Catalog

  @impl true
  def calculate(items, product_code, opts) do
    rule_product_code = Keyword.fetch!(opts, :product_code)

    if product_code != rule_product_code do
      default_total(items, product_code)
    else
      threshold = Keyword.fetch!(opts, :threshold)
      discount_price = opts |> Keyword.fetch!(:discount_price) |> Decimal.new()

      quantity = Enum.count(items, &(&1 == product_code))
      price = if quantity >= threshold, do: discount_price, else: Catalog.fetch!(product_code).price

      Decimal.mult(price, quantity)
    end
  end

  defp default_total(items, product_code) do
    quantity = Enum.count(items, &(&1 == product_code))
    price = Catalog.fetch!(product_code).price

    Decimal.mult(price, quantity)
  end
end
