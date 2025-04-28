defmodule Aipos.CustomersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Customers` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        address: "some address",
        days_since_last_purchase: 42,
        email: "some email",
        loyalty_points: 42,
        membership_level: "some membership_level",
        name: "some name",
        phone: "some phone",
        total_orders: 42,
        total_spent: "120.5"
      })
      |> Aipos.Customers.create_customer()

    customer
  end
end
