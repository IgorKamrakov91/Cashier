defmodule Cashier.PricingRule do
  @moduledoc """
  Behaviour for pricing rules.

  A rule is a `{module, opts}` tuple where opts must include `:product_code`.
  The checkout routes each product to its rule, looks up the quantity and
  unit price, and calls `calculate/3`. The rule only computes the total.

      defmodule MyRule do
        @behaviour Cashier.PricingRule

        @impl true
        def calculate(quantity, price, _opts) do
          Decimal.mult(price, quantity)
        end
      end

  """

  @doc "Returns the total price for `quantity` items at the given unit `price`."
  @callback calculate(
              quantity :: non_neg_integer(),
              price :: Decimal.t(),
              opts :: keyword()
            ) :: Decimal.t()

  @doc """
  Validates rule-specific options at checkout creation time.

  This callback is optional so existing custom rules that only implement
  `calculate/3` remain supported.
  """
  @callback validate_options!(opts :: keyword()) :: :ok

  @optional_callbacks validate_options!: 1
end
