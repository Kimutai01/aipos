defmodule Aipos.OrganizationsTest do
  use Aipos.DataCase

  alias Aipos.Organizations

  describe "organizations" do
    alias Aipos.Organizations.Organization

    import Aipos.OrganizationsFixtures

    @invalid_attrs %{address: nil, email: nil, logo: nil, name: nil, phone: nil}

    test "list_organizations/0 returns all organizations" do
      organization = organization_fixture()
      assert Organizations.list_organizations() == [organization]
    end

    test "get_organization!/1 returns the organization with given id" do
      organization = organization_fixture()
      assert Organizations.get_organization!(organization.id) == organization
    end

    test "create_organization/1 with valid data creates a organization" do
      valid_attrs = %{address: "some address", email: "some email", logo: "some logo", name: "some name", phone: "some phone"}

      assert {:ok, %Organization{} = organization} = Organizations.create_organization(valid_attrs)
      assert organization.address == "some address"
      assert organization.email == "some email"
      assert organization.logo == "some logo"
      assert organization.name == "some name"
      assert organization.phone == "some phone"
    end

    test "create_organization/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizations.create_organization(@invalid_attrs)
    end

    test "update_organization/2 with valid data updates the organization" do
      organization = organization_fixture()
      update_attrs = %{address: "some updated address", email: "some updated email", logo: "some updated logo", name: "some updated name", phone: "some updated phone"}

      assert {:ok, %Organization{} = organization} = Organizations.update_organization(organization, update_attrs)
      assert organization.address == "some updated address"
      assert organization.email == "some updated email"
      assert organization.logo == "some updated logo"
      assert organization.name == "some updated name"
      assert organization.phone == "some updated phone"
    end

    test "update_organization/2 with invalid data returns error changeset" do
      organization = organization_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizations.update_organization(organization, @invalid_attrs)
      assert organization == Organizations.get_organization!(organization.id)
    end

    test "delete_organization/1 deletes the organization" do
      organization = organization_fixture()
      assert {:ok, %Organization{}} = Organizations.delete_organization(organization)
      assert_raise Ecto.NoResultsError, fn -> Organizations.get_organization!(organization.id) end
    end

    test "change_organization/1 returns a organization changeset" do
      organization = organization_fixture()
      assert %Ecto.Changeset{} = Organizations.change_organization(organization)
    end
  end
end
