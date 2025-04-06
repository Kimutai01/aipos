defmodule Aipos.SalesTest do
  use Aipos.DataCase

  alias Aipos.Sales

  describe "sales" do
    alias Aipos.Sales.Sale

    import Aipos.SalesFixtures

    @invalid_attrs %{amount_tendered: nil, change_due: nil, payment_method: nil, status: nil, total_amount: nil}

    test "list_sales/0 returns all sales" do
      sale = sale_fixture()
      assert Sales.list_sales() == [sale]
    end

    test "get_sale!/1 returns the sale with given id" do
      sale = sale_fixture()
      assert Sales.get_sale!(sale.id) == sale
    end

    test "create_sale/1 with valid data creates a sale" do
      valid_attrs = %{amount_tendered: "120.5", change_due: "120.5", payment_method: "some payment_method", status: "some status", total_amount: "120.5"}

      assert {:ok, %Sale{} = sale} = Sales.create_sale(valid_attrs)
      assert sale.amount_tendered == Decimal.new("120.5")
      assert sale.change_due == Decimal.new("120.5")
      assert sale.payment_method == "some payment_method"
      assert sale.status == "some status"
      assert sale.total_amount == Decimal.new("120.5")
    end

    test "create_sale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_sale(@invalid_attrs)
    end

    test "update_sale/2 with valid data updates the sale" do
      sale = sale_fixture()
      update_attrs = %{amount_tendered: "456.7", change_due: "456.7", payment_method: "some updated payment_method", status: "some updated status", total_amount: "456.7"}

      assert {:ok, %Sale{} = sale} = Sales.update_sale(sale, update_attrs)
      assert sale.amount_tendered == Decimal.new("456.7")
      assert sale.change_due == Decimal.new("456.7")
      assert sale.payment_method == "some updated payment_method"
      assert sale.status == "some updated status"
      assert sale.total_amount == Decimal.new("456.7")
    end

    test "update_sale/2 with invalid data returns error changeset" do
      sale = sale_fixture()
      assert {:error, %Ecto.Changeset{}} = Sales.update_sale(sale, @invalid_attrs)
      assert sale == Sales.get_sale!(sale.id)
    end

    test "delete_sale/1 deletes the sale" do
      sale = sale_fixture()
      assert {:ok, %Sale{}} = Sales.delete_sale(sale)
      assert_raise Ecto.NoResultsError, fn -> Sales.get_sale!(sale.id) end
    end

    test "change_sale/1 returns a sale changeset" do
      sale = sale_fixture()
      assert %Ecto.Changeset{} = Sales.change_sale(sale)
    end
  end

  describe "sale_items" do
    alias Aipos.Sales.SaleItem

    import Aipos.SalesFixtures

    @invalid_attrs %{name: nil, price: nil, quantity: nil, subtotal: nil}

    test "list_sale_items/0 returns all sale_items" do
      sale_item = sale_item_fixture()
      assert Sales.list_sale_items() == [sale_item]
    end

    test "get_sale_item!/1 returns the sale_item with given id" do
      sale_item = sale_item_fixture()
      assert Sales.get_sale_item!(sale_item.id) == sale_item
    end

    test "create_sale_item/1 with valid data creates a sale_item" do
      valid_attrs = %{name: "some name", price: "120.5", quantity: 42, subtotal: "120.5"}

      assert {:ok, %SaleItem{} = sale_item} = Sales.create_sale_item(valid_attrs)
      assert sale_item.name == "some name"
      assert sale_item.price == Decimal.new("120.5")
      assert sale_item.quantity == 42
      assert sale_item.subtotal == Decimal.new("120.5")
    end

    test "create_sale_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_sale_item(@invalid_attrs)
    end

    test "update_sale_item/2 with valid data updates the sale_item" do
      sale_item = sale_item_fixture()
      update_attrs = %{name: "some updated name", price: "456.7", quantity: 43, subtotal: "456.7"}

      assert {:ok, %SaleItem{} = sale_item} = Sales.update_sale_item(sale_item, update_attrs)
      assert sale_item.name == "some updated name"
      assert sale_item.price == Decimal.new("456.7")
      assert sale_item.quantity == 43
      assert sale_item.subtotal == Decimal.new("456.7")
    end

    test "update_sale_item/2 with invalid data returns error changeset" do
      sale_item = sale_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Sales.update_sale_item(sale_item, @invalid_attrs)
      assert sale_item == Sales.get_sale_item!(sale_item.id)
    end

    test "delete_sale_item/1 deletes the sale_item" do
      sale_item = sale_item_fixture()
      assert {:ok, %SaleItem{}} = Sales.delete_sale_item(sale_item)
      assert_raise Ecto.NoResultsError, fn -> Sales.get_sale_item!(sale_item.id) end
    end

    test "change_sale_item/1 returns a sale_item changeset" do
      sale_item = sale_item_fixture()
      assert %Ecto.Changeset{} = Sales.change_sale_item(sale_item)
    end
  end
end
