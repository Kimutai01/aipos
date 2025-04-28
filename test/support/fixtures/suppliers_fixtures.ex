defmodule Aipos.SuppliersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Suppliers` context.
  """

  @doc """
  Generate a supplier.
  """
  def supplier_fixture(attrs \\ %{}) do
    {:ok, supplier} =
      attrs
      |> Enum.into(%{
        address: "some address",
        contact_name: "some contact_name",
        email: "some email",
        last_order_date: ~D[2025-04-27],
        lead_time: 42,
        name: "some name",
        notes: "some notes",
        payment_terms: "some payment_terms",
        phone: "some phone",
        status: "some status",
        tags: ["option1", "option2"]
      })
      |> Aipos.Suppliers.create_supplier()

    supplier
  end
end
