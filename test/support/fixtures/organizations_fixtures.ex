defmodule Aipos.OrganizationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Aipos.Organizations` context.
  """

  @doc """
  Generate a organization.
  """
  def organization_fixture(attrs \\ %{}) do
    {:ok, organization} =
      attrs
      |> Enum.into(%{
        address: "some address",
        email: "some email",
        logo: "some logo",
        name: "some name",
        phone: "some phone"
      })
      |> Aipos.Organizations.create_organization()

    organization
  end
end
