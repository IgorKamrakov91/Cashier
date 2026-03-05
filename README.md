# Cashier

A supermarket checkout system built in Elixir with flexible, pluggable pricing rules.

## Features

- **Shopping cart** — scan items in any order, compute total on demand
- **Pluggable pricing rules** — add, remove, or swap rules without changing checkout logic
- **Built-in rules:**
  - **Buy-one-get-one-free** (e.g., green tea)
  - **Bulk discount** — fixed price drop at a quantity threshold (e.g., strawberries)
  - **Fraction price** — percentage-based discount at a quantity threshold (e.g., coffee at 2/3 price)
- **Decimal arithmetic** — no floating-point rounding issues in financial calculations
- **OTP-based** — each checkout session is a GenServer process

## Getting Started

### Prerequisites

- Elixir ~> 1.18
- Erlang/OTP 26+

### Setup

```bash
mix deps.get
mix compile
```

### Run Tests

```bash
mix test
```

### Static Analysis

```bash
mix credo        # code style
mix dialyzer     # type checking
```

## Architecture

```
lib/cashier/
  product.ex              # Product struct (code, name, price as Decimal)
  catalog.ex              # Product registry with lookup by code
  pricing_rule.ex         # Behaviour — contract for all pricing rules
  checkout.ex             # GenServer — cart session with scan/total API
  pricing_rules/
    buy_one_get_one_free.ex  # BOGO rule
    bulk_discount.ex         # Fixed price at quantity threshold
    fraction_price.ex        # Fraction of original price at threshold
```

### Design Decisions

**Pricing rules as a behaviour with `{module, opts}` tuples.** Each rule implements `calculate(items, product_code, opts)`. Rules are passed to the checkout at creation time, making them fully swappable. The CEO can change from BOGO to a 30% discount by simply swapping the rule tuple — no code changes needed.

**GenServer per checkout session.** Models a real-world cart — items are scanned one at a time, total is computed on demand. Each cart is an isolated process.

**Decimal for money.** Avoids floating-point issues. The `FractionPrice` rule computes the discount on the batch total (`quantity * price * numerator / denominator`) rather than per-item to minimize rounding.

**Catalog as a module attribute.** Products are compiled into the module for fast lookups. The interface (`fetch/1`, `fetch!/1`, `all/0`) is designed to be swappable for a database-backed implementation later.

## Test Data

| Basket                 | Total   |
|------------------------|---------|
| GR1, SR1, GR1, GR1, CF1 | £22.45 |
| GR1, GR1               | £3.11  |
| SR1, SR1, GR1, SR1     | £16.61 |
| GR1, CF1, SR1, CF1, CF1 | £30.57 |

All baskets are verified in the test suite (`mix test`).

## Try It

Launch an interactive shell and play with the checkout:

```bash
iex -S mix
```

Then paste the following to simulate a shopping session:

```elixir
# 1. Set up pricing rules
pricing_rules = [
  {Cashier.PricingRules.BuyOneGetOneFree, product_code: "GR1"},
  {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: "4.50"},
  {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
]

# 2. Start a checkout
{:ok, co} = Cashier.Checkout.new(pricing_rules)

# 3. Scan some green tea (buy-one-get-one-free)
Cashier.Checkout.scan(co, "GR1")
Cashier.Checkout.scan(co, "GR1")
Cashier.Checkout.total(co)
#=> #Decimal<3.11>  — you pay for one!

# 4. Add strawberries (bulk discount at 3+)
Cashier.Checkout.scan(co, "SR1")
Cashier.Checkout.scan(co, "SR1")
Cashier.Checkout.scan(co, "SR1")
Cashier.Checkout.total(co)
#=> #Decimal<16.61>  — strawberries dropped to £4.50 each

# 5. Add coffees (2/3 price at 3+)
Cashier.Checkout.scan(co, "CF1")
Cashier.Checkout.scan(co, "CF1")
Cashier.Checkout.total(co)
#=> #Decimal<39.07>  — 2 coffees at full price

Cashier.Checkout.scan(co, "CF1")
Cashier.Checkout.total(co)
#=> #Decimal<42.18>  — 3rd coffee triggers discount, all coffees now at 2/3 price

# 6. Try an unknown product
Cashier.Checkout.scan(co, "NOPE")
#=> {:error, "unknown product code: NOPE"}
```

### Quick verification of spec baskets

```elixir
# Helper to test a basket in one go
test_basket = fn items ->
  {:ok, co} = Cashier.Checkout.new(pricing_rules)
  Enum.each(items, &Cashier.Checkout.scan(co, &1))
  Cashier.Checkout.total(co)
end

test_basket.(~w[GR1 SR1 GR1 GR1 CF1])    #=> #Decimal<22.45>
test_basket.(~w[GR1 GR1])                 #=> #Decimal<3.11>
test_basket.(~w[SR1 SR1 GR1 SR1])         #=> #Decimal<16.61>
test_basket.(~w[GR1 CF1 SR1 CF1 CF1])     #=> #Decimal<30.57>
```

### Browse the product catalog

```elixir
Cashier.Catalog.all()
Cashier.Catalog.fetch!("GR1")
```
