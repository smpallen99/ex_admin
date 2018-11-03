defmodule ExAdmin.Theme.AdminLte2.Table do
  @moduledoc false
  # import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  import ExAdmin.Table
  import ExAdmin.Gettext
  alias ExAdmin.Utils
  use Xain

  @table_opts [class: "table"]

  def theme_panel(conn, schema) do
    markup do
      div get_in(schema, [:opts, :box_style]) || ".box" do
        unless get_in(schema, [:opts, :no_header]) do
          div get_in(schema, [:opts, :box_header_style]) || ".box-header.with-border" do
            h3(Keyword.get(schema, :name, ""))
          end
        end

        div get_in(schema, [:opts, :box_body_style]) || ".box-body" do
          do_panel(conn, schema, @table_opts)
        end
      end
    end
  end

  def theme_attributes_table(conn, resource, schema, resource_model) do
    markup do
      div ".box" do
        div ".box-header.with-border" do
          h3(
            schema[:name] ||
              gettext("%{resource_model} Details", resource_model: Utils.humanize(resource_model))
          )
        end

        div ".box-body" do
          do_attributes_table_for(conn, resource, resource_model, schema, @table_opts)
        end
      end
    end
  end

  def theme_attributes_table_for(conn, resource, schema, resource_model) do
    do_attributes_table_for(conn, resource, resource_model, schema, @table_opts)
  end
end
