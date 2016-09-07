defmodule ExAdmin.Controller do
  @moduledoc false
  def get_registered_by_controller_route!(%Plug.Conn{} = conn, resource_name \\ nil) do
    resource_name = resource_name || conn.params["resource"]
    res = get_registered_by_controller_route(resource_name)
    if res == %{} do
      raise Phoenix.Router.NoRouteError, conn: conn, router: __MODULE__
    else
      res
    end
  end

  def get_registered_by_controller_route(resource_name) do
    Enum.find ExAdmin.get_registered, %{}, &(Map.get(&1, :controller_route) == resource_name)
  end

  defmacro __using__(_opts) do
    quote do
      import ExAdmin.Controller

      def set_theme(conn, _) do
        assign(conn, :theme, ExAdmin.theme)
      end

      def set_layout(conn, _) do
        layout = Application.get_env(:ex_admin, :layout) || "#{conn.assigns.theme.name}.html"
        put_layout(conn, layout)
      end
    end
  end
end
