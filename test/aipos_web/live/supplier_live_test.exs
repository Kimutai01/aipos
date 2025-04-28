defmodule AiposWeb.SupplierLiveTest do
  use AiposWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aipos.SuppliersFixtures

  @create_attrs %{address: "some address", contact_name: "some contact_name", email: "some email", last_order_date: "2025-04-27", lead_time: 42, name: "some name", notes: "some notes", payment_terms: "some payment_terms", phone: "some phone", status: "some status", tags: ["option1", "option2"]}
  @update_attrs %{address: "some updated address", contact_name: "some updated contact_name", email: "some updated email", last_order_date: "2025-04-28", lead_time: 43, name: "some updated name", notes: "some updated notes", payment_terms: "some updated payment_terms", phone: "some updated phone", status: "some updated status", tags: ["option1"]}
  @invalid_attrs %{address: nil, contact_name: nil, email: nil, last_order_date: nil, lead_time: nil, name: nil, notes: nil, payment_terms: nil, phone: nil, status: nil, tags: []}

  defp create_supplier(_) do
    supplier = supplier_fixture()
    %{supplier: supplier}
  end

  describe "Index" do
    setup [:create_supplier]

    test "lists all suppliers", %{conn: conn, supplier: supplier} do
      {:ok, _index_live, html} = live(conn, ~p"/suppliers")

      assert html =~ "Listing Suppliers"
      assert html =~ supplier.address
    end

    test "saves new supplier", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("a", "New Supplier") |> render_click() =~
               "New Supplier"

      assert_patch(index_live, ~p"/suppliers/new")

      assert index_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#supplier-form", supplier: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/suppliers")

      html = render(index_live)
      assert html =~ "Supplier created successfully"
      assert html =~ "some address"
    end

    test "updates supplier in listing", %{conn: conn, supplier: supplier} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("#suppliers-#{supplier.id} a", "Edit") |> render_click() =~
               "Edit Supplier"

      assert_patch(index_live, ~p"/suppliers/#{supplier}/edit")

      assert index_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#supplier-form", supplier: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/suppliers")

      html = render(index_live)
      assert html =~ "Supplier updated successfully"
      assert html =~ "some updated address"
    end

    test "deletes supplier in listing", %{conn: conn, supplier: supplier} do
      {:ok, index_live, _html} = live(conn, ~p"/suppliers")

      assert index_live |> element("#suppliers-#{supplier.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#suppliers-#{supplier.id}")
    end
  end

  describe "Show" do
    setup [:create_supplier]

    test "displays supplier", %{conn: conn, supplier: supplier} do
      {:ok, _show_live, html} = live(conn, ~p"/suppliers/#{supplier}")

      assert html =~ "Show Supplier"
      assert html =~ supplier.address
    end

    test "updates supplier within modal", %{conn: conn, supplier: supplier} do
      {:ok, show_live, _html} = live(conn, ~p"/suppliers/#{supplier}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Supplier"

      assert_patch(show_live, ~p"/suppliers/#{supplier}/show/edit")

      assert show_live
             |> form("#supplier-form", supplier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#supplier-form", supplier: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/suppliers/#{supplier}")

      html = render(show_live)
      assert html =~ "Supplier updated successfully"
      assert html =~ "some updated address"
    end
  end
end
