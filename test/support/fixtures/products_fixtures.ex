defmodule Aipos.ProductsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Products` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        description: "some description",
        image: "some image",
        name: "some name"
      })
      |> Aipos.Products.create_product()

    product
  end
end
