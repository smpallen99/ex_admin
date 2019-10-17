Code.ensure_compiled(ExAdmin.Utils)

defmodule ExAdmin.Sidebar do
  @moduledoc false
  require Logger
  require Ecto.Query
  use Xain

  def sidebars_visible?(_conn, %{sidebars: []}), do: false

  def sidebars_visible?(conn, %{sidebars: sidebars}) do
    Enum.reduce(sidebars, false, fn {_, opts, _}, acc ->
      acc || visible?(conn, opts)
    end)
  end

  def sidebar_view(_conn, %{sidebars: []}, _), do: nil

  def sidebar_view(conn, %{sidebars: sidebars}, resource) do
    for sidebar <- sidebars do
      _sidebar_view(conn, sidebar, resource)
    end
  end

  defp _sidebar_view(conn, {name, opts, {mod, fun}}, resource) do
    if visible?(conn, opts) do
      ExAdmin.Theme.Helpers.theme_module(conn, Layout).sidebar_view(
        conn,
        {name, opts, {mod, fun}},
        resource
      )
    else
      ""
    end
  end

  def visible?(conn, opts) do
    Phoenix.Controller.action_name(conn)
    |> _visible?(Enum.into(opts, %{}))
  end

  def _visible?(action, %{only: only}) when is_atom(only) do
    if action == only, do: true, else: false
  end

  def _visible?(action, %{only: only}) when is_list(only) do
    if action in only, do: true, else: false
  end

  def _visible?(action, %{except: except}) when is_atom(except) do
    if action == except, do: false, else: true
  end

  def _visible?(action, %{except: except}) when is_list(except) do
    if action in except, do: false, else: true
  end

  def _visible?(_, _), do: true

  def get_actions(item, opts) do
    case opts[item] || [] do
      atom when is_atom(atom) -> [atom]
      other -> other
    end
  end
end
