defmodule Cashier.Product do
  @moduledoc """
  A product with a code, name, and price (stored as `Decimal`).
  """

  @enforce_keys [:code, :name, :price]
  defstruct [:code, :name, :price]

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          price: Decimal.t()
        }

  @doc """
  Creates a new product. Price is cast to Decimal.

  ## Examples

      iex> Cashier.Product.new("GR1", "Green tea", "3.11")
      %Cashier.Product{code: "GR1", name: "Green tea", price: Decimal.new("3.11")}

  """
  @spec new(String.t(), String.t(), String.t() | integer() | Decimal.t()) :: t()
  def new(code, name, price) do
    %__MODULE__{
      code: code,
      name: name,
      price: Decimal.new(price)
    }
  end
end
