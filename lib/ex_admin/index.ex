defmodule ExAdmin.Index do
  @moduledoc """
  Override the default index page for an ExAdmin resource

  By default, ExAdmin renders the index table without any additional 
  configuration. It renders each column in the model, except the id, 
  inserted_at, and updated_at columns. 

  ## Default Table Type

  ExAdmin displays a selection checkbox column on the left with a batch
  action control that enables when a checkbox is selected. 

  To customize the index page, use the `index` macro. 

  For example, the following will show on the id an name fields, as 
  well place a selection column and batch actions row on the page:

      defmodule MyProject.ExAdmin.MyModel do
        use ExAdmin.Register
        register_resource MyProject.MyModel do

          index do 
            selectable_column

            column :id
            column :name
          end
        end
      end

  ### Image fields

  For image fields, use the `image: true` option. For example:

      index do 
        column :name
        column :image, [image: true, height: 100], &(ExAdminDemo.Image.url({&1.image, &1}, :thumb))
      end

  ### Custom columns

  Columns can be customized with column/2 where the second argument is
  an anonymous function called with model. Here are a couple examples:

      index do 
        column :id 
        column :name, fn(category) -> 
          Phoenix.HTML.Tag.content_tag :span, category.name, 
            "data-id": category.id, class: "category"
        end
        column "Created", fn(category) -> 
          category.created_at
        end
      end

  ### Override the Actions column

  The Actions column can be customized by adding `column "Actions", fn(x) -> ...`

      column "Actions", fn(r) -> 
        safe_concat link_to("Restore", "/admin/backuprestores/restore/#\{r.id}", "data-method": :put, 
            "data-confirm": "You are about to restore #\{r.file_name}. Are you sure?",
            class: "member_link restore-link"), 
          link_to("Delete", "/admin/backuprestores/#\{r.id}", "data-method": :delete,
            "data-confirm": "Are you sure you want to delete this?",
            class: "member_link")
      end

  ### Associations

  By default, ExAdmin will attempt to render a belongs_to association with a 
  select control, using name field in the association. If you would like to 
  render an association with another field name, or would like to use more than 
  one field, use the :field option. 

      column :account, fields: [:username]

  ### Change the column label

  Use the :label option to override the column name:

      column :name, label: "Custom Name"


  ## As Grid

  By providing option `as: :grid` to the `index` macro, a grid index page 
  is rendered. 

  ### For Example: 

      index as: :grid, default: true do
        cell fn(p) -> 
          div do
            a href: get_route_path(conn, :show, p.id) do
              img(src: ExAdminDemo.Image.url({p.image_file_name, p}, :thumb), height: 100)
            end
          end
          a truncate(p.title), href: get_route_path(conn, :show, p.id)
        end
      end

  """

  require Logger
  require Integer
  import ExAdmin.Utils
  import ExAdmin.DslUtils
  #import UcxCallout.Admin.ViewHelpers, only: [get_route_path: 3]
  import ExAdmin.Helpers
  import Kernel, except: [div: 2, to_string: 1]
  use Xain

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end


  @doc """
  The index macro is used to customize the index page of a resource. 
  
  """
  defmacro index(opts \\ [], do: block) do

    contents = quote do
      unquote(block)
    end

    quote location: :keep, bind_quoted: [options: escape(opts), contents: escape(contents)] do
      def index_view(var!(conn), page, scope_counts) do
        import ExAdmin.Register, except: [actions: 1]
        import ExAdmin.Form, except: [actions: 1]
        import ExAdmin.ViewHelpers

        var!(columns, ExAdmin.Show) = []
        var!(selectable_column, ExAdmin.Index) = nil
        var!(actions, ExAdmin.Index) = nil
        var!(cell, ExAdmin.Index) = nil
        opts = unquote(options)
        unquote(contents)

        columns = var!(columns, ExAdmin.Show) |> Enum.reverse
        selectable = case var!(selectable_column, ExAdmin.Index) do
          nil -> false
          other -> other
        end

        markup do
          cond do 
            opts[:as] == :grid -> 
              ExAdmin.Index.render_index_grid(var!(conn), page, scope_counts, var!(cell, ExAdmin.Index), opts)
            true -> 
              ExAdmin.Index.render_index_table(var!(conn), page, columns, 
                 %{selectable_column: selectable}, scope_counts, var!(actions, ExAdmin.Index))
          end
        end
      end
    end
  end
  
  @doc """
  Define which actions will be displayed in the index view.

  ## Examples

      actions 
      actions [:new, :destroy]
  """
  defmacro actions(opts \\ quote(do: [])) do
    quote do
      var!(actions, ExAdmin.Index) = unquote(opts)
    end
  end

  defmacro cell(fun) do
    quote do 
      var!(cell, ExAdmin.Index) = unquote(fun)
    end
  end

  @doc """
  Add a column of selection check boxes

  Allows users to select individual rows on the index page. Selecting
  columns activates the batch actions button.
  """
  defmacro selectable_column do
    quote do
      var!(selectable_column, ExAdmin.Index) = true
    end
  end

  @doc false
  def default_index_view(conn, page, scope_counts) do
    [_, resource] = conn.path_info 

    case ExAdmin.get_registered_by_controller_route(resource) do
      nil -> 
        throw :invalid_route
      %{__struct__: _} = defn -> 
        columns = case defn.index_filters do
          [] -> []
          [false] -> []
          [f] -> f
        end
        |> case do
          [] -> 
            columns = defn.resource_model.__schema__(:fields)
            |> Enum.filter(&(not &1 in [:inserted_at, :updated_at]))
          other ->
            other
        end
        |> Enum.map(&({translate_field(defn, &1), %{}}))

        if :id in defn.resource_model.__schema__(:fields) and Enum.any?(columns, (&(elem(&1, 0) == :id))) do
          columns = Keyword.put columns, :id, %{link: true}
        end

        markup do
          ExAdmin.Index.render_index_table(var!(conn), page, columns, 
            %{selectable_column: true}, scope_counts, [])
        end
    end
  end

  defp get_resource_fields([]), do: []
  defp get_resource_fields([resource | _]), do: resource.__struct__.__schema__(:fields)

  def render_index_grid(conn, page, scope_counts, cell, opts) do
    columns = Keyword.get opts, :columns, 3
    # resources = page.entries
    # fields = get_resource_fields resources
    count = page.total_entries
    name = resource_model(conn) |> titleize |> Inflex.pluralize
    order = ExQueb.get_sort_order(conn.params["order"]) 
    href = get_route_path(conn, :index) <> "?order="
    defn = ExAdmin.get_registered_by_controller_route(conn.params["resource"])
    batch_actions = not false in defn.batch_actions
    scopes = defn.scopes
    # selectable = selectable and batch_actions

    label = get_resource_label(conn) |> Inflex.pluralize
    resource_model = conn.params["resource"]
    div ".box" do
      batch_action_form conn, batch_actions, scopes, resource_model, scope_counts, fn -> 
      if count == 0 do
        div ".blank_slate_container" do
          span ".blank_slate" do
            if conn.params["q"] do
              text "No #{humanize label} found."
            else
              text "There are no #{humanize label} yet. "
              if ExAdmin.has_action?(conn, defn, :new) do
                a "Create one", href: get_route_path(conn, :new)
              end
            end
          end
        end
      else
        div ".paginated_collection" do
          div ".paginated_collection_contents" do
            div ".index_content" do
              div ".container-fluid" do
                col_width = Kernel.div 12, columns
                Enum.chunk(page.entries, columns, columns, [nil])
                |> Enum.each(fn(list) -> 
                  div ".row" do 
                    Enum.each(list, fn(item) -> 
                      div ".col-md-#{col_width}.col-sm-#{col_width * 2}.col-xs-12" do
                        if item do
                          cell.(item)
                        end
                      end
                    end)
                  end
                end)

                # table(".index_grid", border: "0", cellspacing: "0", 
                #     cellpadding: "0", paginator: "true") do
                #   tbody do
                #     Enum.chunk(page.entries, columns, columns, [nil])
                #     |> Enum.each(fn(list) -> 
                #       tr do 
                #         Enum.each(list, fn(item) -> 
                #           td do
                #             if item do
                #               cell.(item)
                #             end
                #           end
                #         end)
                #       end
                #     end)
                #   end
                # end # table          
              end
            end # .index_content
          end
          div "#index_footer" do
            href 
            |> build_scope_href(conn.params["scope"])
            |> build_order_href(order)
            |> build_filter_href(conn.params["q"])
            |> ExAdmin.Paginate.paginate(page.page_number, page.page_size, page.total_pages, count, name)
            download_links(conn)
          end
        end
      end
      end
    end
  end
  
  @doc false
  def render_index_table(conn, page, columns, %{selectable_column: selectable}, scope_counts, actions) do
    resources = page.entries
    fields = get_resource_fields resources
    count = page.total_entries
    name = resource_model(conn) |> titleize |> Inflex.pluralize
    order = ExQueb.get_sort_order(conn.params["order"]) 
    href = get_route_path(conn, :index) <> "?order="
    defn = ExAdmin.get_registered_by_controller_route(conn.params["resource"])
    batch_actions = not false in defn.batch_actions
    scopes = defn.scopes
    selectable = selectable and batch_actions
    columns = unless Enum.any? columns, &((elem &1, 0) == "Actions") or is_nil(actions) do
      columns ++ [{"Actions", %{fun: fn(resource) -> build_index_links(conn, resource, actions) end}}]
    else
      columns
    end

    label = get_resource_label(conn) |> Inflex.pluralize
    resource_model = conn.params["resource"]

    div ".box" do
      batch_action_form conn, batch_actions, scopes, resource_model, scope_counts, fn -> 
        if count == 0 do
          div ".blank_slate_container" do
            span ".blank_slate" do
              if conn.params["q"] do
                text "No #{humanize label} found."
              else
                text "There are no #{humanize label} yet. "
                if ExAdmin.has_action?(conn, defn, :new) do
                  a "Create one", href: get_route_path(conn, :new)
                end
              end
            end
          end
        else
          div ".box-body.table-responsive.no-padding" do
            # div ".row" do
            #   div ".col-sm-12" do
                 div ".paginated_collection" do
                  table(".table-striped.index.table.index_table") do
                    ExAdmin.Table.table_head(columns, %{selectable: true, path_prefix: href, 
                      sort: "desc", order: order, fields: fields, page: page,
                      filter: build_filter_href("", conn.params["q"]),
                      selectable_column: selectable})
                    build_table_body(conn, resources, columns, %{selectable_column: selectable})
                  end # table          
                 end
              # end # .index_content
            # end
          end
          div ".box-footer.clearfix" do
            href 
            |> build_scope_href(conn.params["scope"])
            |> build_order_href(order)
            |> build_filter_href(conn.params["q"])
            |> ExAdmin.Paginate.paginate(page.page_number, page.page_size, page.total_pages, count, name)
            download_links(conn)
          end
        end
      end
    end
  end

  defp build_scope_href(href, nil), do: href
  defp build_scope_href(href, scope) do
    String.replace(href, "?", "?scope=#{scope}&")
  end

  defp build_order_href(href, {name, sort}), do: href <> "#{name}_#{sort}"
  defp build_order_href(href, _), do: href

  defp build_filter_href(href, nil), do: href
  defp build_filter_href(href, q) do 
    q
    |> Map.to_list
    |> Enum.reduce(href, fn({name, value}, acc) -> 
      acc <> "&q%5B" <> name <> "%5D=" <> value
    end)
  end

  @doc false
  def batch_action_form conn, enabled?, scopes, name, scope_counts, fun do
    msg = "Are you sure you want to delete these #{name}? You wont be able to undo this."
    scopes = unless Application.get_env(:ex_admin, :scopes_index_page, true), do: [], else: scopes
    # enabled? = false
    if enabled? or scopes != [] do
      form "#collection_selection", action: "/admin/#{name}/batch_action", method: :post, "accept-charset": "UTF-8" do
        div style: "margin:0;padding:0;display:inline" do
          csrf = Plug.CSRFProtection.get_csrf_token
          input name: "utf8", type: :hidden, value: "✓"
          input(type: :hidden, name: "_csrf_token", value: csrf)
        end
        input "#batch_action", name: "batch_action", type: :hidden
        div ".box-header" do
          div ".table_tools" do
            if enabled? do
              div "#batch_actions_selector.dropdown_menu" do
                # button ".disabled.dropdown_menu_button.dropdown-toggle.btn.btn-sm.btn-default Batch Actions ", "data-toggle": "dropdown" do
                #   span ".fa.fa-caret-down"
                # end
                # ul ".dropdown-menu" do
                #   li do
                #     a ".batch_action Delete Selected", href: "#", "data-action": :destroy, "data-confirm": msg
                #   end
                # end
                button ".disabled.dropdown_menu_button.btn.btn-xs.btn-default Batch Actions " do
                  span ".fa.fa-caret-down"
                end
                div ".dropdown_menu_list_wrapper", style: "display: none;" do
                  div ".dropdown_menu_nipple"
                  ul ".dropdown_menu_list" do
                    li do
                      a ".batch_action Delete Selected", href: "#", "data-action": :destroy, "data-confirm": msg
                    end
                  end
                end
              end
            end
            if scopes != [] do
              current_scope = ExAdmin.Query.get_scope scopes, conn.params["scope"]
              #ul ".scopes.table_tools_segmented_control", style: "width: calc((100% - 10px) - 108px); float: right;" do
              div ".btn-group", style: "width: calc((100% - 10px) - 108px); float: right;" do
                for {name, _opts} <- scopes do
                  count = scope_counts[name]
                  selected = if "#{name}" == "#{current_scope}", do: ".selected", else: ""
                  # li ".scope.#{name}#{selected}" do
                    a ".table_tools_button.btn-sm.btn.btn-default", href: get_route_path(conn, :index) <> "?scope=#{name}" do
                      # button type: :button, class: "btn btn-default" do
                        text ExAdmin.Utils.humanize("#{name} ")
                        span ".badge.bg-blue #{count}"
                      # end
                    end
                  # end
                end
              end
            end
          end
        end
        div ".box-body" do
          fun.()
        end
      end
    else
      div ".box-body" do
        fun.()
      end
    end
  end

  @doc false
  def download_links(conn) do
    div ".download_links Download: " do
      a "CSV", href: "#{get_route_path(conn, :index)}/csv"
    end
  end

  @doc false
  def parameterize(name, seperator \\ "_")
  def parameterize(atom, seperator) when is_atom(atom) do
    Atom.to_string(atom)
    |> parameterize(seperator)
  end
  def parameterize(string, seperator) do
    Inflex.parameterize(string, seperator)
  end


  @doc false
  def build_table_body(_conn, [], _columns, _opts) do
    tbody
  end
  def build_table_body(conn, resources, columns, opts) do
    model_name = resources |> List.first |> Map.get(:__struct__)
    selectable = Map.get opts, :selectable_column

    tbody do
      Enum.with_index(resources) 
      |> Enum.map(fn{resource, inx} -> 
        odd_even = if Integer.is_even(inx), do: "even", else: "odd"
        id = resource.id
        tr(".#{odd_even}##{model_name}_#{id}") do
          if selectable do
            td(".selectable") do
              div(".resource_selection_cell") do
                input(".collection_selection#batch_action_item_#{id}", type: :checkbox, value: "#{id}",
                  name: "collection_selection[]")
              end
            end
          end
          for field <- columns do
            build_field(resource, conn, field, fn(contents, field_name) -> 
              ExAdmin.Table.handle_contents(contents, field_name)
            end)
          end
        end # tr
      end)
    end
  end

  # TODO: don't like that we can't handle the do block :(

  @doc false
  def build_index_links(conn, resource, actions) do
    # name = controller_name(conn)
    resource_model = resource.__struct__
    base_class = "member_link"
    id = resource.id

    links = case actions do
      [] -> [:show, :edit, :destroy]
      nil -> []
      other -> other
    end

    get_authorized_links(conn, resource_model)
    |> Enum.filter(&(&1 in links))
    |> Enum.reverse
    |> Enum.reduce([], fn(item, acc) -> 
      link = case item do
        :show -> 
          a("View", href: get_route_path(conn, :show, id), class: base_class <> " view_link")
        :edit -> 
          a("Edit", href: get_route_path(conn, :edit, id), class: base_class <> " edit_link")
        :destroy -> 
          a("Delete", href: get_route_path(conn, :delete, id), 
              class: base_class <> " delete_link", "data-confirm": confirm_message, 
              "data-csrf": Plug.CSRFProtection.get_csrf_token,
              "data-method": :delete, rel: :nofollow )
      end
      [link | acc]
    end)
    |> case do
      [] -> []
      list -> 
        [{"Actions", list}]
    end

  end

  @doc false
  def get_authorized_links(conn, resource_model) do
    Enum.reduce [:show, :edit, :destroy], [], fn(item, acc) -> 
      if ExAdmin.Utils.authorized_action?(conn, item, resource_model),
        do: [item | acc], else: acc
    end
  end
end
