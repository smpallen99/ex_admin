defmodule ExAdmin.Theme.ActiveAdmin.Index do
  @moduledoc false
  import Kernel, except: [div: 2]
  import Xain
  import ExAdmin.Utils
  import ExAdmin.Index
  require Integer
  import ExAdmin.Helpers
  import ExAdmin.Gettext
  require Logger
  alias ExAdmin.Schema

  def wrap_index_grid(fun) do
    markup do
      div ".box", style: "min-height: 400px" do
        fun.()
      end
    end
  end

  def wrap_index_table(fun) do
    markup do
      div ".box", style: "min-height: 400px" do
        fun.()
      end
    end
  end

  def blank_slate_page(conn, %{defn: defn, label: label}) do
    markup do
      div ".blank_slate_container" do
        span ".blank_slate" do
          unless is_nil(conn.params["q"]) and is_nil(conn.params["scope"]) do
            text(gettext("No %{label} found.", label: humanize(label)))
          else
            text(gettext("There are no %{label} yet. ", label: humanize(label)))

            if ExAdmin.has_action?(conn, defn, :new) do
              a(gettext("Create one"), href: admin_resource_path(conn, :new))
            end
          end
        end
      end
    end
  end

  def paginated_collection_table(conn, opts) do
    resources = opts[:resources]
    selectable = opts[:selectable_column]
    columns = opts[:column_list]
    page = opts[:page]
    order = opts[:order]
    scope = conn.params["scope"]

    markup do
      div ".box-body.table-responsive.no-padding" do
        div ".paginated_collection" do
          table ".table-striped.index.table.index_table" do
            ExAdmin.Table.table_head(columns, %{
              selectable: true,
              path_prefix: opts[:href],
              sort: "desc",
              order: order,
              fields: opts[:fields],
              page: page,
              filter: build_filter_href("", conn.params["q"]),
              scope: scope,
              selectable_column: selectable
            })

            build_table_body(conn, resources, columns, %{selectable_column: selectable})
          end

          # table
        end
      end

      do_footer(conn, opts)
    end
  end

  def paginated_collection_grid(conn, opts) do
    columns = opts[:columns]
    page = opts[:page]

    markup do
      div ".paginated_collection" do
        div ".paginated_collection_contents" do
          div ".index_content" do
            div ".index_as_grid.index" do
              table ".index_grid",
                border: "0",
                cellspacing: "0",
                cellpadding: "0",
                paginator: "true" do
                tbody do
                  Enum.chunk(page.entries, columns, columns, [nil])
                  |> Enum.map(fn list ->
                    tr do
                      Enum.map(list, fn item ->
                        td do
                          if item do
                            opts[:cell].(item)
                          end
                        end
                      end)
                    end
                  end)
                end
              end
            end
          end

          # .index_content
        end

        do_footer(conn, opts)
      end
    end
  end

  def do_footer(conn, opts) do
    page = opts[:page]

    markup do
      div ".box-footer.clearfix" do
        opts[:href]
        |> build_scope_href(conn.params["scope"])
        |> build_order_href(opts[:order])
        |> build_filter_href(conn.params["q"])
        |> ExAdmin.Paginate.paginate(
          page.page_number,
          page.page_size,
          page.total_pages,
          opts[:count],
          opts[:name]
        )

        download_links(conn, opts)
      end
    end
  end

  def handle_action_links(list, resource, labels, page_num) do
    base_class = "member_link"

    markup do
      for item <- Enum.reverse(list) do
        label = labels[item]

        case item do
          :show ->
            link_text = label || gettext("View")

            a(
              link_text,
              href: admin_resource_path(resource, :show),
              class: base_class <> " view_link",
              title: link_text
            )

          :edit ->
            link_text = label || gettext("Edit")

            a(
              link_text,
              href: admin_resource_path(resource, :edit),
              class: base_class <> " edit_link",
              title: link_text
            )

          :delete ->
            link_text = label || gettext("Delete")

            a(
              link_text,
              href: admin_resource_path(resource, :destroy),
              class: base_class <> " delete_link",
              "data-confirm": confirm_message(),
              "data-remote": true,
              "data-method": :delete,
              "data-params": "page=" <> to_string(page_num),
              rel: :nofollow,
              title: link_text
            )
        end
      end
    end
  end

  def batch_action_form(conn, enabled?, scopes, name, scope_counts, fun) do
    msg =
      gettext(
        "Are you sure you want to delete these %{name}? You wont be able to undo this.",
        name: name
      )

    scopes = unless Application.get_env(:ex_admin, :scopes_index_page, true), do: [], else: scopes

    if enabled? or scopes != [] do
      markup do
        form "#collection_selection",
          action: "/admin/#{name}/batch_action",
          method: :post,
          "accept-charset": "UTF-8" do
          div style: "margin:0;padding:0;display:inline" do
            csrf = Plug.CSRFProtection.get_csrf_token()
            input(name: "utf8", type: :hidden, value: "✓")
            input(type: :hidden, name: "_csrf_token", value: csrf)
          end

          input("#batch_action", name: "batch_action", type: :hidden)

          div ".box-header" do
            div ".table_tools" do
              if enabled? do
                div "#batch_actions_selector.dropdown_menu" do
                  button ".disabled.dropdown_menu_button.btn.btn-xs.btn-default " <>
                           gettext("Batch Actions") do
                    span(".fa.fa-caret-down")
                  end

                  div ".dropdown_menu_list_wrapper", style: "display: none;" do
                    div(".dropdown_menu_nipple")

                    ul ".dropdown_menu_list" do
                      li do
                        a(
                          ".batch_action " <> gettext("Delete Selected"),
                          href: "#",
                          "data-action": :destroy,
                          "data-confirm": msg
                        )
                      end
                    end
                  end
                end
              end

              if scopes != [] do
                current_scope = ExAdmin.Query.get_scope(scopes, conn.params["scope"])

                ul ".scopes.table_tools_segmented_control",
                  style: "width: calc((100% - 10px) - 108px); float: right;" do
                  order_segment =
                    case conn.params["order"] do
                      nil -> ""
                      order -> "&order=#{order}"
                    end

                  for {name, _opts} <- scopes do
                    count = scope_counts[name]
                    selected = if "#{name}" == "#{current_scope}", do: ".selected", else: ""

                    li ".scope.#{name}#{selected}" do
                      href =
                        admin_resource_path(conn, :index, [[scope: name]])
                        |> build_filter_href(conn.params["q"])

                      a ".table_tools_button.btn-sm.btn.btn-default", href: href <> order_segment do
                        text(ExAdmin.Utils.humanize("#{name} "))
                        span(".badge.bg-blue #{count}")
                      end
                    end
                  end
                end
              end
            end
          end

          div ".box-body" do
            fun.()
          end
        end
      end
    else
      div ".box-body" do
        fun.()
      end
    end
  end

  def build_table_body(_conn, [], _columns, _opts) do
    tbody()
  end

  def build_table_body(conn, resources, columns, opts) do
    model_name = get_resource_model(resources)
    selectable = Map.get(opts, :selectable_column)

    markup do
      tbody do
        Enum.with_index(resources)
        |> Enum.map(fn {resource, inx} ->
          odd_even = if Integer.is_even(inx), do: "even", else: "odd"
          id = Map.get(resource, Schema.primary_key(resource))

          tr ".#{odd_even}##{model_name}_#{id}" do
            if selectable do
              td ".selectable" do
                div ".resource_selection_cell" do
                  input(
                    ".collection_selection#batch_action_item_#{id}",
                    type: :checkbox,
                    value: "#{id}",
                    name: "collection_selection[]"
                  )
                end
              end
            end

            for field <- columns do
              build_field(resource, conn, field, fn contents, field_name ->
                ExAdmin.Table.handle_contents(contents, field_name)
              end)
            end
          end

          # tr
        end)
      end
    end
  end
end
