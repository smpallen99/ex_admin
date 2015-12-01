defmodule ExAdmin.Index do
  @moduledoc """
  Override the default index page for an ExAdmin resource

  By default, ExAdmin renders the index table without any additional 
  configuration. It renders each column in the model, except the id, 
  inserted_at, and updated_at columns. 

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

  ## Custom columns

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

  ## Override the Actions column

  The Actions column can be customized by adding `column "Actions", fn(x) -> ...`

      column "Actions", fn(r) -> 
        safe_concat link_to("Restore", "/admin/backuprestores/restore/#\{r.id}", "data-method": :put, 
            "data-confirm": "You are about to restore #\{r.file_name}. Are you sure?",
            class: "member_link restore-link"), 
          link_to("Delete", "/admin/backuprestores/#\{r.id}", "data-method": :delete,
            "data-confirm": "Are you sure you want to delete this?",
            class: "member_link")
      end

  ## Associations

  By default, ExAdmin will attempt to render a belongs_to association with a 
  select control, using name field in the association. If you would like to 
  render an association with another field name, or would like to use more than 
  one field, use the :field option. 

      column :account, fields: [:username]

  ## Change the column label

  Use the :label option to override the column name:

      column :name, label: "Custom Name"
  """

  require Logger
  require Integer
  import ExAdmin.Utils
  import ExAdmin.DslUtils
  #import UcxCallout.Admin.ViewHelpers, only: [get_route_path: 3]
  import ExAdmin.Helpers
  import Kernel, except: [div: 2, to_string: 1]
  use Xain
  alias Phoenix.HTML.Link
  import Phoenix.HTML

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

    quote location: :keep, bind_quoted: [opts: escape(opts), contents: escape(contents)] do
      def index_view(var!(conn), page) do
        var!(columns, ExAdmin.Show) = []
        var!(selectable_column, ExAdmin.Index) = nil
        unquote(contents)
        columns = var!(columns, ExAdmin.Show) |> Enum.reverse
        # columns |> Enum.each(&(Logger.warn "------ column: #{inspect &1}"))
        
        selectable = case var!(selectable_column, ExAdmin.Index) do
          nil -> false
          other -> other
        end

        markup do
          ExAdmin.Index.render_index_table(var!(conn), page, columns, %{selectable_column: selectable})
        end

      end
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
  def default_index_view(conn, page) do
    [_, resource] = conn.path_info 

    case ExAdmin.get_registered_by_controller_route(resource) do
      nil -> 
        throw :invalid_route
      %{__struct__: _} = defn -> 
        columns = defn.resource_model.__schema__(:fields)
        |> Enum.filter(&(not &1 in [:id, :inserted_at, :updated_at]))
        |> Enum.map(&({translate_field(&1), %{}}))
        
        markup do
          ExAdmin.Index.render_index_table(var!(conn), page, columns, 
            %{selectable_column: true})
        end
    end
  end

  defp translate_field(field) do
    case Regex.scan ~r/(.+)_id$/, Atom.to_string(field) do
      [[_, assoc]] -> String.to_atom(assoc)
      _ -> field
    end
  end

  defp get_resource_fields([]), do: []
  defp get_resource_fields([resource | _]), do: resource.__struct__.__schema__(:fields)

  @doc false
  def render_index_table(conn, page, columns, %{selectable_column: selectable}) do
    href = get_route_path(conn, :index) <> "?order="
    resources = page.entries
    fields = get_resource_fields resources
    count = page.total_entries
    name = resource_model(conn) |> titleize |> Inflex.pluralize
    order = ExQueb.get_sort_order(conn.params["order"]) 
    href = get_route_path(conn, :index) <> "?order="
    Logger.warn "order... #{inspect order}"
    defn = ExAdmin.get_registered_by_controller_route(conn.params["resource"])
    batch_actions = not false in defn.batch_actions
    selectable = selectable and batch_actions
    columns = unless Enum.any? columns, &((elem &1, 0) == "Actions") do
      columns ++ [{"Actions", %{fun: fn(resource) -> build_index_links(conn, resource) end}}]
    else
      columns
    end

    label = get_resource_label(conn) |> Inflex.pluralize
    resource_model = conn.params["resource"]

    batch_action_form batch_actions, resource_model, fn -> 
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
              div ".index_as_table" do
                table("#contacts.index_table.index", border: "0", cellspacing: "0", 
                    cellpadding: "0", paginator: "true") do
                  ExAdmin.Table.table_head(columns, %{selectable: true, path_prefix: href, 
                    sort: "desc", order: order, fields: fields, page: page, 
                    selectable_column: selectable})
                  build_table_body(conn, resources, columns, %{selectable_column: selectable})
                end # table          
              end
            end # .index_content
          end
          div "#index_footer" do
            href = case order do
              {name, sort} -> href <> "#{name}_#{sort}"
              _ -> href
            end
            ExAdmin.Paginate.paginate(href, page.page_number, page.page_size, page.total_pages, count, name)
            download_links(conn)
          end
        end
      end
    end
  end

  @doc false
  def batch_action_form enabled?, name, fun do
    msg = "Are you sure you want to delete these #{name}? You wont be able to undo this."
    if enabled? do
      form "#collection_selection", action: "/admin/#{name}/batch_action", method: :post, "accept-charset": "UTF-8" do
        div style: "margin:0;padding:0;display:inline" do
          input name: "utf8", type: :hidden, value: "✓"
        end
        input "#batch_action", name: "batch_action", type: :hidden
        div ".table_tools" do
          div "#batch_actions_selector.dropdown_menu" do
            a ".disabled.dropdown_menu_button Batch Actions", href: "#"
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
        fun.()
      end
    else
      fun.()
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
  def build_index_links(conn, resource) do
    # name = controller_name(conn)
    resource_model = resource.__struct__
    base_class = "member_link"
    id = resource.id
    # [ Link.link("View", to: get_route_path(conn, :show, id), class: base_class <> " view_link"),
    #   Link.link("Edit", to: get_route_path(conn, :edit, id), class: base_class <> " edit_link"),
    #   Link.link("Delete", to: get_route_path(conn, :delete, id), 
    #       class: base_class <> " delete_link", "data-confirm": confirm_message, 
    #       "data-method": :delete, rel: :nofollow ) ] 
    # |> html_escape
    get_authorized_links(conn, resource_model)
    |> Enum.reduce([], fn(item, acc) -> 
      link = case item do
        :show -> 
          Link.link("View", to: get_route_path(conn, :show, id), class: base_class <> " view_link")
        :edit -> 
          Link.link("Edit", to: get_route_path(conn, :edit, id), class: base_class <> " edit_link")
        :destroy -> 
          Link.link("Delete", to: get_route_path(conn, :delete, id), 
            class: base_class <> " delete_link", "data-confirm": confirm_message, 
            "data-csrf": Plug.CSRFProtection.get_csrf_token,
            "data-method": :delete, rel: :nofollow )
      end
      [link | acc]
    end)
    |> html_escape

    # a("View", href: get_route_path(conn, :show, id), class: base_class <> " view_link")
    # a("Edit", href: get_route_path(conn, :edit, id), class: base_class <> " edit_link")
    # a("Delete", href: get_route_path(conn, :delete, id), 
    #     class: base_class <> " delete_link", "data-confirm": confirm_message, 
    #     "data-method": :delete, rel: :nofollow )
  end
   #   columns ++ [{"Actions", %{fun: fn(resource) -> build_index_links(conn, resource) end}}]

  @doc false
  def get_authorized_links(conn, resource_model) do
    Enum.reduce [:show, :edit, :destroy], [], fn(item, acc) -> 
      if ExAdmin.Utils.authorized_action?(conn, item, resource_model),
        do: [item | acc], else: acc
    end
  end
end
