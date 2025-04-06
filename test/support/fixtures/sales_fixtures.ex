defmodule Aipos.SalesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Sales` context.
  """

  @doc """
  Generate a sale.
  """
  def sale_fixture(attrs \\ %{}) do
    {:ok, sale} =
      attrs
      |> Enum.into(%{
        amount_tendered: "120.5",
        change_due: "120.5",
        payment_method: "some payment_method",
        status: "some status",
        total_amount: "120.5"
      })
      |> Aipos.Sales.create_sale()

    sale
  end

  @doc """
  Generate a sale_item.
  """
  def sale_item_fixture(attrs \\ %{}) do
    {:ok, sale_item} =
      attrs
      |> Enum.into(%{
        name: "some name",
        price: "120.5",
        quantity: 42,
        subtotal: "120.5"
      })
      |> Aipos.Sales.create_sale_item()

    sale_item
  end
end
