defmodule Cashier.PricingRule do
  @moduledoc """
  Behaviour for pricing rules applied during checkout.

  Each pricing rule is a module that knows how to calculate the total
  for a specific product. Rules are designed to be composable and
  configurable — they can be swapped, added, or removed without
  changing the checkout logic.

  ## Implementing a rule

  A pricing rule is represented as a tuple `{module, opts}` where:
  - `module` implements this behaviour
  - `opts` is a keyword list containing `:product_code` and any
    rule-specific configuration passed to `calculate/3`

  The checkout is responsible for routing: it matches each product to
  its rule via `:product_code` in opts, counts the quantity, looks up
  the unit price, and passes them to `calculate/3`. Rules only need
  to compute the discounted total.

  ## Example

      defmodule MyRule do
        @behaviour Cashier.PricingRule

        @impl true
        def calculate(quantity, price, _opts) do
          # custom pricing logic returning a Decimal total
          Decimal.mult(price, quantity)
        end
      end

      # Usage: {MyRule, product_code: "GR1"}
  """

  @doc """
  Calculates the total price for a product given its quantity and unit price.

  ## Parameters

  - `quantity` — number of items of this product in the cart
  - `price` — the original unit price as a `Decimal`
  - `opts` — configuration options specific to the rule implementation

  ## Returns

  The total price as a `Decimal` for the given product.
  """
  @callback calculate(
              quantity :: non_neg_integer(),
              price :: Decimal.t(),
              opts :: keyword()
            ) :: Decimal.t()
end
