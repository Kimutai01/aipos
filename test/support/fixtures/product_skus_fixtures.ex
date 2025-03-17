defmodule Aipos.ProductSkusFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.ProductSkus` context.
  """

  @doc """
  Generate a product_sku.
  """
  def product_sku_fixture(attrs \\ %{}) do
    {:ok, product_sku} =
      attrs
      |> Enum.into(%{
        barcode: "some barcode",
        buffer_level: "some buffer_level",
        cost: "some cost",
        description: "some description",
        image: "some image",
        name: "some name",
        price: "some price",
        rfid_tag: "some rfid_tag",
        stock_quantity: "some stock_quantity"
      })
      |> Aipos.ProductSkus.create_product_sku()

    product_sku
  end
end
