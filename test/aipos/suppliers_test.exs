defmodule Aipos.SuppliersTest do
  use Aipos.DataCase

  alias Aipos.Suppliers

  describe "suppliers" do
    alias Aipos.Suppliers.Supplier

    import Aipos.SuppliersFixtures

    @invalid_attrs %{address: nil, contact_name: nil, email: nil, last_order_date: nil, lead_time: nil, name: nil, notes: nil, payment_terms: nil, phone: nil, status: nil, tags: nil}

    test "list_suppliers/0 returns all suppliers" do
      supplier = supplier_fixture()
      assert Suppliers.list_suppliers() == [supplier]
    end

    test "get_supplier!/1 returns the supplier with given id" do
      supplier = supplier_fixture()
      assert Suppliers.get_supplier!(supplier.id) == supplier
    end

    test "create_supplier/1 with valid data creates a supplier" do
      valid_attrs = %{address: "some address", contact_name: "some contact_name", email: "some email", last_order_date: ~D[2025-04-27], lead_time: 42, name: "some name", notes: "some notes", payment_terms: "some payment_terms", phone: "some phone", status: "some status", tags: ["option1", "option2"]}

      assert {:ok, %Supplier{} = supplier} = Suppliers.create_supplier(valid_attrs)
      assert supplier.address == "some address"
      assert supplier.contact_name == "some contact_name"
      assert supplier.email == "some email"
      assert supplier.last_order_date == ~D[2025-04-27]
      assert supplier.lead_time == 42
      assert supplier.name == "some name"
      assert supplier.notes == "some notes"
      assert supplier.payment_terms == "some payment_terms"
      assert supplier.phone == "some phone"
      assert supplier.status == "some status"
      assert supplier.tags == ["option1", "option2"]
    end

    test "create_supplier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Suppliers.create_supplier(@invalid_attrs)
    end

    test "update_supplier/2 with valid data updates the supplier" do
      supplier = supplier_fixture()
      update_attrs = %{address: "some updated address", contact_name: "some updated contact_name", email: "some updated email", last_order_date: ~D[2025-04-28], lead_time: 43, name: "some updated name", notes: "some updated notes", payment_terms: "some updated payment_terms", phone: "some updated phone", status: "some updated status", tags: ["option1"]}

      assert {:ok, %Supplier{} = supplier} = Suppliers.update_supplier(supplier, update_attrs)
      assert supplier.address == "some updated address"
      assert supplier.contact_name == "some updated contact_name"
      assert supplier.email == "some updated email"
      assert supplier.last_order_date == ~D[2025-04-28]
      assert supplier.lead_time == 43
      assert supplier.name == "some updated name"
      assert supplier.notes == "some updated notes"
      assert supplier.payment_terms == "some updated payment_terms"
      assert supplier.phone == "some updated phone"
      assert supplier.status == "some updated status"
      assert supplier.tags == ["option1"]
    end

    test "update_supplier/2 with invalid data returns error changeset" do
      supplier = supplier_fixture()
      assert {:error, %Ecto.Changeset{}} = Suppliers.update_supplier(supplier, @invalid_attrs)
      assert supplier == Suppliers.get_supplier!(supplier.id)
    end

    test "delete_supplier/1 deletes the supplier" do
      supplier = supplier_fixture()
      assert {:ok, %Supplier{}} = Suppliers.delete_supplier(supplier)
      assert_raise Ecto.NoResultsError, fn -> Suppliers.get_supplier!(supplier.id) end
    end

    test "change_supplier/1 returns a supplier changeset" do
      supplier = supplier_fixture()
      assert %Ecto.Changeset{} = Suppliers.change_supplier(supplier)
    end
  end
end
