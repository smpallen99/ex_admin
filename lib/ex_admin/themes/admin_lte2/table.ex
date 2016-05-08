defmodule ExAdmin.Theme.AdminLte2.Table do
  @moduledoc false
  # import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import ExAdmin.Table
  use Xain

  @table_opts [class: "table"]

  def theme_panel(conn, schema) do
    div(".box") do
      div ".box-header.with-border" do
        h3(Map.get schema, :name, "")
      end
      div(".box-body") do
        do_panel(conn, schema, @table_opts)
      end
    end
  end

  def theme_attributes_table(conn, resource, schema, resource_model) do
    div ".box" do
      div ".box-header.with-border"  do
        h3(Map.get schema, :name, "#{String.capitalize resource_model} Details")
      end
      div ".box-body" do
        do_attributes_table_for(conn, resource, resource_model, schema, @table_opts)
      end
    end
  end

  def theme_attributes_table_for(conn, resource, schema, resource_model) do
    do_attributes_table_for(conn, resource, resource_model, schema, @table_opts)
  end
end
