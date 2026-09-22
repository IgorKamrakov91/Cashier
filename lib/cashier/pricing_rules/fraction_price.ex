defmodule Cashier.PricingRules.FractionPrice do
  @moduledoc """
  Fraction-based discount: all items drop to a fraction of the original
  price once quantity reaches `:threshold`.

  Requires `:threshold` (integer) and `:fraction` as `{numerator, denominator}`.
  The fraction is applied to the batch total to minimise rounding.
  """

  @behaviour Cashier.PricingRule

  @impl true
  def validate_options!(opts) do
    threshold = Keyword.get(opts, :threshold)
    fraction = Keyword.get(opts, :fraction)

    unless is_integer(threshold) and threshold > 0 do
      raise ArgumentError, "fraction price :threshold must be a positive integer"
    end

    unless valid_fraction?(fraction) do
      raise ArgumentError,
            "fraction price :fraction must be a {non-negative integer, positive integer} tuple"
    end

    :ok
  end

  @impl true
  def calculate(quantity, price, opts) do
    threshold = Keyword.fetch!(opts, :threshold)
    fraction = Keyword.fetch!(opts, :fraction)

    if quantity >= threshold do
      apply_fraction(price, quantity, fraction)
    else
      Decimal.mult(price, quantity)
    end
  end

  defp apply_fraction(price, quantity, {numerator, denominator}) do
    price
    |> Decimal.mult(quantity)
    |> Decimal.mult(numerator)
    |> Decimal.div(denominator)
    |> Decimal.round(2)
  end

  defp valid_fraction?({numerator, denominator})
       when is_integer(numerator) and numerator >= 0 and is_integer(denominator) and
              denominator > 0,
       do: true

  defp valid_fraction?(_fraction), do: false
end
