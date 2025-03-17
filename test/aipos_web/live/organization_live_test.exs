defmodule AiposWeb.OrganizationLiveTest do
  use AiposWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aipos.OrganizationsFixtures

  @create_attrs %{address: "some address", email: "some email", logo: "some logo", name: "some name", phone: "some phone"}
  @update_attrs %{address: "some updated address", email: "some updated email", logo: "some updated logo", name: "some updated name", phone: "some updated phone"}
  @invalid_attrs %{address: nil, email: nil, logo: nil, name: nil, phone: nil}

  defp create_organization(_) do
    organization = organization_fixture()
    %{organization: organization}
  end

  describe "Index" do
    setup [:create_organization]

    test "lists all organizations", %{conn: conn, organization: organization} do
      {:ok, _index_live, html} = live(conn, ~p"/organizations")

      assert html =~ "Listing Organizations"
      assert html =~ organization.address
    end

    test "saves new organization", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/organizations")

      assert index_live |> element("a", "New Organization") |> render_click() =~
               "New Organization"

      assert_patch(index_live, ~p"/organizations/new")

      assert index_live
             |> form("#organization-form", organization: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#organization-form", organization: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/organizations")

      html = render(index_live)
      assert html =~ "Organization created successfully"
      assert html =~ "some address"
    end

    test "updates organization in listing", %{conn: conn, organization: organization} do
      {:ok, index_live, _html} = live(conn, ~p"/organizations")

      assert index_live |> element("#organizations-#{organization.id} a", "Edit") |> render_click() =~
               "Edit Organization"

      assert_patch(index_live, ~p"/organizations/#{organization}/edit")

      assert index_live
             |> form("#organization-form", organization: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#organization-form", organization: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/organizations")

      html = render(index_live)
      assert html =~ "Organization updated successfully"
      assert html =~ "some updated address"
    end

    test "deletes organization in listing", %{conn: conn, organization: organization} do
      {:ok, index_live, _html} = live(conn, ~p"/organizations")

      assert index_live |> element("#organizations-#{organization.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#organizations-#{organization.id}")
    end
  end

  describe "Show" do
    setup [:create_organization]

    test "displays organization", %{conn: conn, organization: organization} do
      {:ok, _show_live, html} = live(conn, ~p"/organizations/#{organization}")

      assert html =~ "Show Organization"
      assert html =~ organization.address
    end

    test "updates organization within modal", %{conn: conn, organization: organization} do
      {:ok, show_live, _html} = live(conn, ~p"/organizations/#{organization}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Organization"

      assert_patch(show_live, ~p"/organizations/#{organization}/show/edit")

      assert show_live
             |> form("#organization-form", organization: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#organization-form", organization: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/organizations/#{organization}")

      html = render(show_live)
      assert html =~ "Organization updated successfully"
      assert html =~ "some updated address"
    end
  end
end
