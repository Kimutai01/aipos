defmodule Aipos.ProductSkusTest do
  use Aipos.DataCase

  alias Aipos.ProductSkus

  describe "product_skus" do
    alias Aipos.ProductSkus.ProductSku

    import Aipos.ProductSkusFixtures

    @invalid_attrs %{barcode: nil, buffer_level: nil, cost: nil, description: nil, image: nil, name: nil, price: nil, rfid_tag: nil, stock_quantity: nil}

    test "list_product_skus/0 returns all product_skus" do
      product_sku = product_sku_fixture()
      assert ProductSkus.list_product_skus() == [product_sku]
    end

    test "get_product_sku!/1 returns the product_sku with given id" do
      product_sku = product_sku_fixture()
      assert ProductSkus.get_product_sku!(product_sku.id) == product_sku
    end

    test "create_product_sku/1 with valid data creates a product_sku" do
      valid_attrs = %{barcode: "some barcode", buffer_level: "some buffer_level", cost: "some cost", description: "some description", image: "some image", name: "some name", price: "some price", rfid_tag: "some rfid_tag", stock_quantity: "some stock_quantity"}

      assert {:ok, %ProductSku{} = product_sku} = ProductSkus.create_product_sku(valid_attrs)
      assert product_sku.barcode == "some barcode"
      assert product_sku.buffer_level == "some buffer_level"
      assert product_sku.cost == "some cost"
      assert product_sku.description == "some description"
      assert product_sku.image == "some image"
      assert product_sku.name == "some name"
      assert product_sku.price == "some price"
      assert product_sku.rfid_tag == "some rfid_tag"
      assert product_sku.stock_quantity == "some stock_quantity"
    end

    test "create_product_sku/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ProductSkus.create_product_sku(@invalid_attrs)
    end

    test "update_product_sku/2 with valid data updates the product_sku" do
      product_sku = product_sku_fixture()
      update_attrs = %{barcode: "some updated barcode", buffer_level: "some updated buffer_level", cost: "some updated cost", description: "some updated description", image: "some updated image", name: "some updated name", price: "some updated price", rfid_tag: "some updated rfid_tag", stock_quantity: "some updated stock_quantity"}

      assert {:ok, %ProductSku{} = product_sku} = ProductSkus.update_product_sku(product_sku, update_attrs)
      assert product_sku.barcode == "some updated barcode"
      assert product_sku.buffer_level == "some updated buffer_level"
      assert product_sku.cost == "some updated cost"
      assert product_sku.description == "some updated description"
      assert product_sku.image == "some updated image"
      assert product_sku.name == "some updated name"
      assert product_sku.price == "some updated price"
      assert product_sku.rfid_tag == "some updated rfid_tag"
      assert product_sku.stock_quantity == "some updated stock_quantity"
    end

    test "update_product_sku/2 with invalid data returns error changeset" do
      product_sku = product_sku_fixture()
      assert {:error, %Ecto.Changeset{}} = ProductSkus.update_product_sku(product_sku, @invalid_attrs)
      assert product_sku == ProductSkus.get_product_sku!(product_sku.id)
    end

    test "delete_product_sku/1 deletes the product_sku" do
      product_sku = product_sku_fixture()
      assert {:ok, %ProductSku{}} = ProductSkus.delete_product_sku(product_sku)
      assert_raise Ecto.NoResultsError, fn -> ProductSkus.get_product_sku!(product_sku.id) end
    end

    test "change_product_sku/1 returns a product_sku changeset" do
      product_sku = product_sku_fixture()
      assert %Ecto.Changeset{} = ProductSkus.change_product_sku(product_sku)
    end
  end
end
