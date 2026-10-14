defmodule Cashier.PricingRules.BulkDiscount do
  @moduledoc """
  Bulk discount: drops unit price when quantity reaches `:threshold`.

  Requires `:threshold` (integer) and `:discount_price` (Decimal).
  """

  @behaviour Cashier.PricingRule

  @impl true
  def validate_options!(opts) do
    threshold = Keyword.get(opts, :threshold)
    discount_price = Keyword.get(opts, :discount_price)

    unless is_integer(threshold) and threshold > 0 do
      raise ArgumentError, "bulk discount :threshold must be a positive integer"
    end

    unless match?(%Decimal{}, discount_price) and is_integer(discount_price.coef) and
             Decimal.compare(discount_price, 0) != :lt do
      raise ArgumentError, "bulk discount :discount_price must be a finite, non-negative Decimal"
    end

    :ok
  end

  @impl true
  def calculate(quantity, price, opts) do
    threshold = Keyword.fetch!(opts, :threshold)
    discount_price = Keyword.fetch!(opts, :discount_price)

    effective_price = if quantity >= threshold, do: discount_price, else: price

    Decimal.mult(effective_price, quantity)
  end
end
