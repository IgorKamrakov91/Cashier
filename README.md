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
- **OTP-based** — each checkout is a supervised GenServer with idle timeout

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
  catalog.ex              # Product catalog — configurable via app env
  pricing_rule.ex         # Behaviour — contract for all pricing rules
  checkout.ex             # Supervised GenServer — cart session with scan/total/stop
  application.ex          # OTP app with DynamicSupervisor for checkouts
  pricing_rules/
    buy_one_get_one_free.ex  # BOGO rule
    bulk_discount.ex         # Fixed price at quantity threshold
    fraction_price.ex        # Fraction of original price at threshold
```

### Design Decisions

**Pricing rules as a behaviour with `{module, opts}` tuples.** Each rule implements `calculate(quantity, price, opts)`. Rules are validated and indexed by product code at checkout creation time. The CEO can change from BOGO to a 30% discount by simply swapping the rule tuple — no code changes needed.

**Supervised GenServer per checkout session.** Checkouts are started under a `DynamicSupervisor` with `:temporary` restart strategy. Each cart has an idle timeout (default: 30 minutes) to prevent process leaks from abandoned sessions. Graceful shutdown via `stop/1`.

**Decimal for money.** Avoids floating-point issues. The `FractionPrice` rule computes the discount on the batch total (`quantity * price * numerator / denominator`) rather than per-item to minimize rounding.

**Configurable catalog.** Products default to a built-in set but can be overridden at runtime via application config (`config :cashier, :catalog_products, %{...}`), enabling runtime product management without recompilation.

**Frequency map for items.** Cart items are stored as `%{"GR1" => 2, "SR1" => 1}` instead of a flat list, making quantity lookups O(1).

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
  {Cashier.PricingRules.BulkDiscount, product_code: "SR1", threshold: 3, discount_price: Decimal.new("4.50")},
  {Cashier.PricingRules.FractionPrice, product_code: "CF1", threshold: 3, fraction: {2, 3}}
]

# 2. Start a checkout
{:ok, co} = Cashier.new(pricing_rules)

# 3. Scan some green tea (buy-one-get-one-free)
Cashier.scan(co, "GR1")
Cashier.scan(co, "GR1")
Cashier.total(co)
#=> #Decimal<3.11>  — you pay for one!

# 4. Add strawberries (bulk discount at 3+)
Cashier.scan(co, "SR1")
Cashier.scan(co, "SR1")
Cashier.scan(co, "SR1")
Cashier.total(co)
#=> #Decimal<16.61>  — strawberries dropped to £4.50 each

# 5. Add coffees (2/3 price at 3+)
Cashier.scan(co, "CF1")
Cashier.scan(co, "CF1")
Cashier.total(co)
#=> 2 coffees at full price

Cashier.scan(co, "CF1")
Cashier.total(co)
#=> 3rd coffee triggers discount, all coffees now at 2/3 price

# 6. Try an unknown product
Cashier.scan(co, "NOPE")
#=> {:error, "unknown product code: \"NOPE\""}

# 7. Done — stop the checkout
Cashier.stop(co)
```

### Quick verification of spec baskets

```elixir
test_basket = fn items ->
  {:ok, co} = Cashier.new(pricing_rules)
  Enum.each(items, &Cashier.scan(co, &1))
  total = Cashier.total(co)
  Cashier.stop(co)
  total
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
