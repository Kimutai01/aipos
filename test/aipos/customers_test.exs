defmodule Aipos.CustomersTest do
  use Aipos.DataCase

  alias Aipos.Customers

  describe "customers" do
    alias Aipos.Customers.Customer

    import Aipos.CustomersFixtures

    @invalid_attrs %{address: nil, days_since_last_purchase: nil, email: nil, loyalty_points: nil, membership_level: nil, name: nil, phone: nil, total_orders: nil, total_spent: nil}

    test "list_customers/0 returns all customers" do
      customer = customer_fixture()
      assert Customers.list_customers() == [customer]
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = customer_fixture()
      assert Customers.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      valid_attrs = %{address: "some address", days_since_last_purchase: 42, email: "some email", loyalty_points: 42, membership_level: "some membership_level", name: "some name", phone: "some phone", total_orders: 42, total_spent: "120.5"}

      assert {:ok, %Customer{} = customer} = Customers.create_customer(valid_attrs)
      assert customer.address == "some address"
      assert customer.days_since_last_purchase == 42
      assert customer.email == "some email"
      assert customer.loyalty_points == 42
      assert customer.membership_level == "some membership_level"
      assert customer.name == "some name"
      assert customer.phone == "some phone"
      assert customer.total_orders == 42
      assert customer.total_spent == Decimal.new("120.5")
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Customers.create_customer(@invalid_attrs)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = customer_fixture()
      update_attrs = %{address: "some updated address", days_since_last_purchase: 43, email: "some updated email", loyalty_points: 43, membership_level: "some updated membership_level", name: "some updated name", phone: "some updated phone", total_orders: 43, total_spent: "456.7"}

      assert {:ok, %Customer{} = customer} = Customers.update_customer(customer, update_attrs)
      assert customer.address == "some updated address"
      assert customer.days_since_last_purchase == 43
      assert customer.email == "some updated email"
      assert customer.loyalty_points == 43
      assert customer.membership_level == "some updated membership_level"
      assert customer.name == "some updated name"
      assert customer.phone == "some updated phone"
      assert customer.total_orders == 43
      assert customer.total_spent == Decimal.new("456.7")
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = customer_fixture()
      assert {:error, %Ecto.Changeset{}} = Customers.update_customer(customer, @invalid_attrs)
      assert customer == Customers.get_customer!(customer.id)
    end

    test "delete_customer/1 deletes the customer" do
      customer = customer_fixture()
      assert {:ok, %Customer{}} = Customers.delete_customer(customer)
      assert_raise Ecto.NoResultsError, fn -> Customers.get_customer!(customer.id) end
    end

    test "change_customer/1 returns a customer changeset" do
      customer = customer_fixture()
      assert %Ecto.Changeset{} = Customers.change_customer(customer)
    end
  end
end
