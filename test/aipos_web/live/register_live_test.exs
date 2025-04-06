defmodule AiposWeb.RegisterLiveTest do
  use AiposWeb.ConnCase

  import Phoenix.LiveViewTest
  import Aipos.RegistersFixtures

  @create_attrs %{name: "some name", status: "some status"}
  @update_attrs %{name: "some updated name", status: "some updated status"}
  @invalid_attrs %{name: nil, status: nil}

  defp create_register(_) do
    register = register_fixture()
    %{register: register}
  end

  describe "Index" do
    setup [:create_register]

    test "lists all registers", %{conn: conn, register: register} do
      {:ok, _index_live, html} = live(conn, ~p"/registers")

      assert html =~ "Listing Registers"
      assert html =~ register.name
    end

    test "saves new register", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/registers")

      assert index_live |> element("a", "New Register") |> render_click() =~
               "New Register"

      assert_patch(index_live, ~p"/registers/new")

      assert index_live
             |> form("#register-form", register: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#register-form", register: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/registers")

      html = render(index_live)
      assert html =~ "Register created successfully"
      assert html =~ "some name"
    end

    test "updates register in listing", %{conn: conn, register: register} do
      {:ok, index_live, _html} = live(conn, ~p"/registers")

      assert index_live |> element("#registers-#{register.id} a", "Edit") |> render_click() =~
               "Edit Register"

      assert_patch(index_live, ~p"/registers/#{register}/edit")

      assert index_live
             |> form("#register-form", register: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#register-form", register: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/registers")

      html = render(index_live)
      assert html =~ "Register updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes register in listing", %{conn: conn, register: register} do
      {:ok, index_live, _html} = live(conn, ~p"/registers")

      assert index_live |> element("#registers-#{register.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#registers-#{register.id}")
    end
  end

  describe "Show" do
    setup [:create_register]

    test "displays register", %{conn: conn, register: register} do
      {:ok, _show_live, html} = live(conn, ~p"/registers/#{register}")

      assert html =~ "Show Register"
      assert html =~ register.name
    end

    test "updates register within modal", %{conn: conn, register: register} do
      {:ok, show_live, _html} = live(conn, ~p"/registers/#{register}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Register"

      assert_patch(show_live, ~p"/registers/#{register}/show/edit")

      assert show_live
             |> form("#register-form", register: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#register-form", register: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/registers/#{register}")

      html = render(show_live)
      assert html =~ "Register updated successfully"
      assert html =~ "some updated name"
    end
  end
end
