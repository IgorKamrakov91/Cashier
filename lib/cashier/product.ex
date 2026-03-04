defmodule Cashier.Product do
  @moduledoc """
  Represents a product in the store.

  Prices are stored as `Decimal` to avoid floating-point precision issues
  in financial calculations.
  """

  @enforce_keys [:code, :name, :price]
  defstruct [:code, :name, :price]

  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          price: Decimal.t()
        }

  @doc """
  Creates a new product.

  Price can be given as a string, integer, or Decimal.

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
