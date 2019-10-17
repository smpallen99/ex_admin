defmodule ExAdmin.Register do
  @moduledoc """
  Allows registering a resource or a page to be displayed with ExAdmin.

  For each model you wanted rendered by ExAdmin, use the
  `register_resource` call. For each general page (like a dashboard),
  use the `register_page` call.

  To allow ExAdmin to manage the resource with defaults, do not place
  any additional code in the block of `register_resource`.

  ## Examples

  Register the Survey.Answer model with all defaults.

      defmodule Survey.ExAdmin.Answer do
        use ExAdmin.Register

        register_resource Survey.Answer do
        end
      end

  ## Commands available in the register_resource do block

  * `menu` - Customize the properties of the menu item
  * `index` - Customize the index page
  * `show` - Customize the show page
  * `form` - Customize the form page
  * `query` - Customize the `Ecto` queries for each page
  * `options` - Change various options for a resource
  * `member_action` - Add a custom action for id based requests
  * `filter` - Disable/Customize the filter pages
  * `controller` - Override the default controller
  * `action_items` - Define which actions are available for a resource
  * `batch_actions` - Customize the batch_actions shown on the index page
  * `csv` - Customize the csv export file
  * `collection_action` - Add a custom action for collection based requests
  * `clear_action_items!` - Remove the action item buttons
  * `action_item` - Defines custom action items
  * `changesets` - Defines custom changeset functions

  """

  if File.dir?("/tmp") do
    @filename "/tmp/ex_admin_registered"
  else
    @filename System.tmp_dir() <> "/ex_admin_registered"
  end

  import ExAdmin.Utils
  import ExAdmin.DslUtils

  defmacro __using__(_) do
    quote do
      use ExAdmin.Index, except: [actions: 1]
      use ExAdmin.Show
      use ExAdmin.Form, except: [actions: 1]
      use ExAdmin.CSV
      import unquote(__MODULE__)
      import Phoenix.HTML.Tag
      import Ecto.Query, only: [from: 2]
      import Xain, except: [input: 1, input: 2, input: 3, menu: 1, form: 2]
      import ExAdmin.ViewHelpers
      Module.register_attribute(__MODULE__, :member_actions, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :collection_actions, accumulate: true, persist: true)
    end
  end

  File.rm(@filename)
  File.touch(@filename)

  @doc """
  Register an Ecto model.

  Once registered, ExAdmin adds the resource to the administration
  pages. If no additional code is added to the do block, the resource
  will be rendered with defaults, including:

  * A paginated index page listing all columns in the model's database
    table
  * A details page (show) listing fields and simple associations
  * New and edit pages
  * A menu item
  * A CSV export link on the index page

  # Default Association Rendering

  ExAdmin will render an association using the following algorithm in the following order:

  * Look for a `:name` field in the association
  * Look for a display_name/1 function in the Admin Resource Module
  * Look for a display_name/1 function in the Model's Module
  * Use the 2nd field in the Model's schema

  """
  defmacro register_resource(mod, do: block) do
    quote location: :keep do
      import ExAdmin.ViewHelpers
      import ExAdmin.Utils
      require Logger

      @all_options [:edit, :show, :new, :delete]

      Module.register_attribute(__MODULE__, :query, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :index_filters, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :batch_actions, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :selectable_column, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :form_items, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :controller_plugs, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :sidebars, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :scopes, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :actions, accumulate: true, persist: true)
      Enum.each(@all_options, &Module.put_attribute(__MODULE__, :actions, &1))
      module = unquote(mod)
      Module.put_attribute(__MODULE__, :module, module)
      Module.put_attribute(__MODULE__, :query, nil)
      Module.put_attribute(__MODULE__, :selectable_column, nil)
      Module.put_attribute(__MODULE__, :changesets, [])
      Module.put_attribute(__MODULE__, :update_changeset, :changeset)
      Module.put_attribute(__MODULE__, :create_changeset, :changeset)

      @name_column Module.get_attribute(__MODULE__, :name_column) ||
                     apply(ExAdmin.Helpers, :get_name_field, [module])

      alias unquote(mod)
      import Ecto.Query

      def config do
        apply(__MODULE__, :__struct__, [])
      end

      unquote(block)

      query_opts =
        case Module.get_attribute(__MODULE__, :query) do
          nil ->
            list =
              module.__schema__(:associations)
              |> Enum.map(&ExAdmin.Register.build_query_association(module, &1))
              |> Enum.filter(&(not is_nil(&1)))

            query = %{all: [preload: list]}
            Module.put_attribute(__MODULE__, :query, query)
            query

          other ->
            other
        end

      controller =
        case Module.get_attribute(__MODULE__, :controller) do
          nil ->
            controller_mod = String.to_atom("#{module}Controller")
            Module.put_attribute(__MODULE__, :controller, controller_mod)

          other ->
            Logger.warn("Should not get here - controller: #{inspect(other)}")
        end

      menu_opts =
        case Module.get_attribute(__MODULE__, :menu) do
          false ->
            %{none: true}

          nil ->
            %{priority: 10, label: base_name(module) |> Inflex.pluralize()}

          other ->
            Enum.into(other, %{})
        end

      controller_route = base_name(module) |> Inflex.underscore() |> Inflex.pluralize()

      controller_route =
        case Module.get_attribute(__MODULE__, :options) do
          nil ->
            controller_route

          options ->
            Keyword.get(options, :controller_route, controller_route)
        end

      plugs =
        case Module.get_attribute(__MODULE__, :controller_plugs) do
          nil -> []
          list -> Enum.reverse(list)
        end

      sidebars =
        case Module.get_attribute(__MODULE__, :sidebars) do
          nil -> []
          list -> Enum.reverse(list)
        end

      scopes =
        case Module.get_attribute(__MODULE__, :scopes) do
          nil -> []
          list -> Enum.reverse(list)
        end

      controller_filters =
        (Module.get_attribute(__MODULE__, :controller_filters) || [])
        |> ExAdmin.Helpers.group_reduce_by_reverse()

      action_labels =
        ExAdmin.Register.get_action_labels(Module.get_attribute(__MODULE__, :actions))

      actions =
        ExAdmin.Register.get_action_items(
          Module.get_attribute(__MODULE__, :actions),
          @all_options
        )
        |> ExAdmin.Register.custom_action_actions(
          Module.get_attribute(__MODULE__, :member_actions),
          module,
          :member_actions
        )
        |> ExAdmin.Register.custom_action_actions(
          Module.get_attribute(__MODULE__, :collection_actions),
          module,
          :collection_actions
        )

      defstruct controller: @controller,
                controller_methods: Module.get_attribute(__MODULE__, :controller_methods),
                title_actions: &ExAdmin.default_resource_title_actions/2,
                type: :resource,
                resource_model: module,
                resource_name: resource_name(module),
                query_opts: query_opts,
                controller_route: controller_route,
                menu: menu_opts,
                actions: actions,
                action_labels: action_labels,
                member_actions: Module.get_attribute(__MODULE__, :member_actions),
                collection_actions: Module.get_attribute(__MODULE__, :collection_actions),
                controller_filters: controller_filters,
                index_filters: Module.get_attribute(__MODULE__, :index_filters),
                selectable_column: Module.get_attribute(__MODULE__, :selectable_column),
                position_column: Module.get_attribute(__MODULE__, :position_column),
                name_column: @name_column,
                batch_actions: Module.get_attribute(__MODULE__, :batch_actions),
                changesets: Module.get_attribute(__MODULE__, :changesets),
                plugs: plugs,
                sidebars: sidebars,
                scopes: scopes,
                create_changeset: @create_changeset,
                update_changeset: @update_changeset

      def run_query(repo, defn, action, id \\ nil) do
        %__MODULE__{}
        |> Map.get(:resource_model)
        |> ExAdmin.Query.run_query(repo, defn, action, id, @query)
      end

      def run_query_counts(repo, defn, action, id \\ nil) do
        %__MODULE__{}
        |> Map.get(:resource_model)
        |> ExAdmin.Query.run_query_counts(repo, defn, action, id, @query)
      end

      def build_admin_search_query(keywords) do
        cond do
          function_exported?(@module, :admin_search_query, 1) ->
            apply(@module, :admin_search_query, [keywords])

          function_exported?(__MODULE__, :admin_search_query, 1) ->
            apply(__MODULE__, :admin_search_query, [keywords])

          true ->
            suggest_admin_search_query(keywords)
        end
      end

      defp suggest_admin_search_query(keywords) do
        field = @name_column
        query = from(r in @module, order_by: ^field)

        case keywords do
          nil ->
            query

          "" ->
            query

          keywords ->
            from(r in query, where: ilike(field(r, ^field), ^"%#{keywords}%"))
        end
      end

      def changeset_fn(defn, action) do
        Keyword.get(defn.changesets, action, &defn.resource_model.changeset/2)
      end

      def plugs(), do: @controller_plugs

      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end

  @doc false
  def get_action_labels(nil), do: []

  def get_action_labels([opts | _]) when is_list(opts) do
    opts[:labels] || []
  end

  def get_action_labels(_), do: []

  @doc false
  def get_action_items(nil, _), do: []

  def get_action_items(actions, all_options) when is_list(actions) do
    {atoms, keywords} =
      List.flatten(actions)
      |> Enum.reduce({[], []}, fn
        atom, {acca, acck} when is_atom(atom) -> {[atom | acca], acck}
        kw, {acca, acck} -> {acca, [kw | acck]}
      end)

    atoms = Enum.reverse(atoms)
    keywords = Enum.reverse(Keyword.drop(keywords, [:labels]))

    cond do
      keywords[:only] && keywords[:except] ->
        raise "options :only and :except cannot be used together"

      keywords[:only] ->
        Keyword.delete(keywords, :only) ++ keywords[:only]

      keywords[:except] ->
        Keyword.delete(keywords, :except) ++ (all_options -- keywords[:except])

      true ->
        keywords ++ atoms
    end
  end

  def custom_action_actions(actions, custom_actions, module, type) do
    custom_actions
    |> Enum.reduce(actions, fn {name, opts}, acc ->
      fun =
        quote do
          name = unquote(name)

          human_name =
            case unquote(opts)[:opts][:label] do
              nil -> humanize(name)
              label -> label
            end

          attrs = []

          attrs =
            if unquote(opts)[:opts][:class] do
              class = unquote(opts)[:opts][:class]
              attrs ++ [class: class]
            else
              attrs
            end

          attrs =
            if unquote(opts)[:opts][:data_confirm] do
              data_confirm = unquote(opts)[:opts][:data_confirm]
              attrs ++ ["data-confirm": data_confirm]
            else
              attrs
            end

          module = unquote(module)
          type = unquote(type)

          if type == :member_actions do
            fn id ->
              resource = struct(module.__struct__, id: id)
              url = ExAdmin.Utils.admin_resource_path(resource, :member, [name])

              attrs = [href: url, "data-method": :put] ++ attrs

              ExAdmin.ViewHelpers.action_item_link(human_name, attrs)
            end
          else
            fn id ->
              resource = module
              url = ExAdmin.Utils.admin_resource_path(resource, :collection, [name])
              attrs = [href: url] ++ attrs
              ExAdmin.ViewHelpers.action_item_link(human_name, attrs)
            end
          end
        end

      action = if type == :member_actions, do: :show, else: :index
      [{action, fun} | acc]
    end)
  end

  @doc """
  Override the controller for a resource.

  Allows custom actions, filters, and plugs for the controller. Commands
  in the controller block include:

  * `define_method` - Create a controller action with the body of
    the action
  * `before_filter` - Add a before_filter to the controller
  * `after_filter` - Add an after callback to the controller
  * `redirect_to` - Redirects to another page
  * `plug` - Add a plug to the controller

  """
  defmacro controller(do: block) do
    quote do
      Module.register_attribute(__MODULE__, :controller_methods, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :controller_filters, accumulate: true, persist: true)
      Module.put_attribute(__MODULE__, :controller_methods, [])

      unquote(block)
    end
  end

  defmacro controller(controller_mod) do
    quote do
      Module.put_attribute(__MODULE__, :controller, unquote(controller_mod))
    end
  end

  @doc """
  Override the changesets for a controller's update action
  """
  defmacro update_changeset(changeset) do
    quote do
      Module.put_attribute(__MODULE__, :update_changeset, unquote(changeset))
    end
  end

  @doc """
  Override the changesets for a controller's create action
  """
  defmacro create_changeset(changeset) do
    quote do
      Module.put_attribute(__MODULE__, :create_changeset, unquote(changeset))
    end
  end

  @doc """
  Override an action on a controller.

  Allows the customization of controller actions.

  ## Examples

  Override the index action to redirect to the root page.

      controller do
        define_method(:index) do
          redirect_to "/"
        end
      end


  """
  defmacro define_method(name, do: block) do
    quote do
      methods = Module.get_attribute(__MODULE__, :controller_methods)

      Module.put_attribute(__MODULE__, :controller_methods, [{unquote(name), []} | methods])
      unquote(block)
    end
  end

  @doc """
  Add a before_filter to a controller.

  The before filter is executed before the controller action(s) are
  executed.

  Normally, the function should return the conn struct. However, if you
  want to modify the params, then return the tuple `{conn, new_parms}`.

  ## Examples

  The following example illustrates how to add a sync action that will
  be run before the index page is loaded.

      controller do
        before_filter :sync, only: [:index]

        def sync(conn, _) do
          BackupRestore.sync
          conn
        end
      end

      controller do
        before_filter :no_change, except: [:create, :modify]

        def no_change(conn, params) do
          {conn, put_in(params, [:setting, :no_mod], true)}
        end
      end
  """
  defmacro before_filter(name, opts \\ []) do
    quote location: :keep do
      Module.put_attribute(
        __MODULE__,
        :controller_filters,
        {:before_filter, {unquote(name), unquote(opts)}}
      )
    end
  end

  @doc """
  Add an after filter to a controller.

  The after filter is executed after the controller action(s) are
  executed and before the page is rendered/redirected. In the case of `update`
  and `create`, it is only called on success.

  Normally, the function should return the conn struct. However, you can also
  return a `{conn, params, resource}` to modify the params and resource.

  ## Examples

      controller do
        after_filter :do_after, only: [:create, :update]

        def do_after(conn, params, resource, :create) do
          user = Repo.all(User) |> hd
          resource = Product.changeset(resource, %{user_id: user.id})
          |> Repo.update!
          {Plug.Conn.assign(conn, :product, resource), params, resource}
        end
        def do_after(conn, _params, _resource, :update) do
          Plug.Conn.assign(conn, :answer, 42)
        end
      end
  """
  defmacro after_filter(name, opts \\ []) do
    quote location: :keep do
      Module.put_attribute(
        __MODULE__,
        :controller_filters,
        {:after_filter, {unquote(name), unquote(opts)}}
      )
    end
  end

  @doc """
  Override the changeset function for `update` and `create` actions.
  By default, `changeset/2` for the resource will be used.

  ## Examples

  The following example illustrates how to configure custom changeset functions
  for create and update actions.

      changesets create: &__MODULE__.create_changeset/2,
                 update: &__MODULE__.update_changeset/2

      def create_changeset(model, params) do
        Ecto.Changeset.cast(model, params, ~w(name password), ~w(age))
      end

      def update_changeset(model, params) do
        Ecto.Changeset.cast(model, params, ~w(name), ~w(age password))
      end
  """
  defmacro changesets(opts) do
    quote location: :keep do
      Module.put_attribute(__MODULE__, :changesets, unquote(opts))
    end
  end

  @doc """
  Redirect to a given path.

  Use this command in a controller block to redirect to another page.
  """
  defmacro redirect_to(path) do
    quote do
      [{name, opts} | tail] = Module.get_attribute(__MODULE__, :controller_methods)
      new_opts = [{:redirect_to, unquote(path)} | opts]
      Module.put_attribute(__MODULE__, :controller_methods, [{name, new_opts} | tail])
    end
  end

  @doc """
  Add a plug to the controller.

  Add custom plugs to a controller.

  ## Example

      controller do
        plug :my_plug, the_answer: 42
      end

  """
  defmacro plug(name, opts \\ []) do
    quote do
      Module.put_attribute(__MODULE__, :controller_plugs, {unquote(name), unquote(opts)})
    end
  end

  @doc """
  Register a static page.

  Use `register_page` to create a static page, like a dashboard, or
  welcome page to the admin interface.

  See the default dashboard page for an example.
  """
  defmacro register_page(name, do: block) do
    quote location: :keep do
      import ExAdmin.Register, except: [column: 1]
      use ExAdmin.Page

      Module.register_attribute(__MODULE__, :query, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :index_filters, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :batch_actions, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :selectable_column, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :form_items, accumulate: true, persist: true)
      Module.register_attribute(__MODULE__, :sidebars, accumulate: true, persist: true)
      Module.put_attribute(__MODULE__, :controller_plugs, nil)
      page_name = unquote(name)
      unquote(block)

      # query_opts = Module.get_attribute(__MODULE__, :query)
      menu_opts =
        case Module.get_attribute(__MODULE__, :menu) do
          false ->
            %{none: true}

          nil ->
            %{label: page_name, priority: 99}

          other ->
            Enum.into(other, %{})
        end

      controller_methods = Module.get_attribute(__MODULE__, :controller_methods)
      page_name = Kernel.to_string(page_name)

      plugs =
        case Module.get_attribute(__MODULE__, :controller_plugs) do
          nil -> []
          list -> Enum.reverse(list)
        end

      sidebars =
        case Module.get_attribute(__MODULE__, :sidebars) do
          nil -> []
          list -> Enum.reverse(list)
        end

      defstruct controller:
                  Module.concat(Application.get_env(:ex_admin, :project), AdminController),
                controller_methods: Module.get_attribute(__MODULE__, :controller_methods),
                type: :page,
                page_name: page_name,
                title_actions: &ExAdmin.default_page_title_actions/2,
                controller_route: page_name |> Inflex.parameterize("_"),
                menu: menu_opts,
                member_actions: Module.get_attribute(__MODULE__, :member_actions),
                collection_actions: Module.get_attribute(__MODULE__, :collection_actions),
                controller_filters: Module.get_attribute(__MODULE__, :controller_filters),
                index_filters: [false],
                # selectable_column: Module.get_attribute(__MODULE__, :selectable_column),
                batch_actions: Module.get_attribute(__MODULE__, :batch_actions),
                plugs: plugs,
                sidebars: sidebars,
                scopes: []

      def plugs(), do: @controller_plugs

      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end

  @doc """
  Add a sidebar to the page.


  The available options are:

  * `:only` - Filters the list of actions for the filter.
  * `:except` - Filters out actions in the except atom or list.

  ## Examples

      sidebar "ExAdmin Demo", only: [:index, :show] do
        Phoenix.View.render ExAdminDemo.AdminView, "sidebar_links.html", []
      end

      sidebar :Orders, only: :show do
        attributes_table_for resource do
          row "title", fn(_) -> { resource.title } end
          row "author", fn(_) -> { resource.author } end
        end
      end

      # customize the panel

      sidebar "Expert Administration", box_attributes: ".box.box-warning",
                  header_attributes: ".box-header.with-border.text-yellow" do
        Phoenix.View.render MyApp.AdminView, "sidebar_warning.html", []
      end
  """
  defmacro sidebar(name, opts \\ [], do: block) do
    contents =
      quote do
        unquote(block)
      end

    quote location: :keep,
          bind_quoted: [name: escape(name), opts: escape(opts), contents: escape(contents)] do
      fun_name = "side_bar_#{name}" |> String.replace(" ", "_") |> String.to_atom()

      def unquote(fun_name)(var!(conn), var!(resource)) do
        _ = var!(conn)
        _ = var!(resource)
        unquote(contents)
      end

      Module.put_attribute(__MODULE__, :sidebars, {name, opts, {__MODULE__, fun_name}})
    end
  end

  @doc """
  Scope the index page.

  ## Examples

        scope :all, default: true

        scope :available, fn(q) ->
          now = Ecto.Date.utc
          where(q, [p], p.available_on <= ^now)
        end

        scope :drafts, fn(q) ->
          now = Ecto.Date.utc
          where(q, [p], p.available_on > ^now)
        end

        scope :featured_products, [], fn(q) ->
          where(q, [p], p.featured == true)
        end

        scope :featured

  """
  defmacro scope(name) do
    quote location: :keep do
      Module.put_attribute(__MODULE__, :scopes, {unquote(name), []})
    end
  end

  defmacro scope(name, opts_or_fun) do
    quote location: :keep do
      opts_or_fun = unquote(opts_or_fun)

      if is_function(opts_or_fun) do
        scope(unquote(name), [], unquote(opts_or_fun))
      else
        Module.put_attribute(__MODULE__, :scopes, {unquote(name), opts_or_fun})
      end
    end
  end

  defmacro scope(name, opts, fun) do
    contents =
      quote do
        unquote(fun)
      end

    quote location: :keep,
          bind_quoted: [name: escape(name), opts: escape(opts), contents: escape(contents)] do
      fun_name = "scope_#{name}" |> String.replace(" ", "_") |> String.to_atom()

      def unquote(fun_name)(var!(resource)) do
        unquote(contents).(var!(resource))
      end

      opts = [{:fun, {__MODULE__, fun_name}} | opts]
      Module.put_attribute(__MODULE__, :scopes, {name, opts})
    end
  end

  @doc """
  Customize the resource admin page by setting options for the page.

  The available actions are:

  * TBD
  """
  defmacro options(opts) do
    quote do
      Module.put_attribute(__MODULE__, :options, unquote(opts))
    end
  end

  @doc """
  Customize the menu of a page.

  The available options are:

  * `:priority` - Sets the position of the menu, with 0 being the
    left most menu item
  * `:label` - The name used in the menu
  * `:if` - Only display the menu item if the condition returns non false/nil
  * `:url` - The custom URL used in the menu link

  ## Examples

  The following example adds a custom label, sets the priority, and is
  only displayed if the current user is a superadmin.

      menu label: "Backup & Restore", priority: 14, if: &__MODULE__.is_superadmin/1

  This example disables the menu item:

      menu false

  """
  defmacro menu(opts) do
    quote do
      Module.put_attribute(__MODULE__, :menu, unquote(opts))
    end
  end

  @doc """
  Add query options to the Ecto queries.

  For the most part, use `query` to setup preload options. Query
  customization can be done for all pages, or individually specified.

  ## Examples

  Load the belongs_to :category, has_many :phone_numbers, and
  the has_many :groups for all pages for the resource.

      query do
        %{
          all: [preload: [:category, :phone_numbers, :groups]],
        }
      end

  Load the has_many :contacts association, as well as the has_many
  :phone_numbers of the contact

      query do
        %{show: [preload: [contacts: [:phone_numbers]]] }
      end

  A more complicated example that defines a default preload, with a
  more specific preload for the show page.

      query do
        %{
          all: [preload: [:group]],
          show: [preload: [:group, messages: [receiver: [:category, :phone_numbers]]]]
        }
      end

  Change the index page default sort order to ascending.

      query do
        %{index: [default_sort_order: :asc]}
      end

  Change the index page default sort field and order.

      query do
        %{index: [default_sort: [asc: :name]]}
      end

  Change the index page default sort field.

      query do
        %{index: [default_sort_field: :name]}
      end
  """
  defmacro query(do: qry) do
    quote do
      Module.put_attribute(__MODULE__, :query, unquote(qry))
    end
  end

  @doc """
  Add a column to a table.

  Can be used on the index page, or in the table attributes on the
  show page.

  A number of options are valid:

  * `label` - Change the name of the column heading
  * `fields` - Add the fields to be included in an association
  * `link` - Set to true to add a link to an association
  * `fn/1` - An anonymous function to be called to render the field
  * `collection` - Add the collection for a belongs_to association
  """
  defmacro column(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts(unquote(opts), unquote(fun))
      var!(columns, ExAdmin.Show) = [{unquote(name), opts} | var!(columns, ExAdmin.Show)]
    end
  end

  @doc """
  Drag&drop control for sortable tables.

  `fa_icon_name` is one of [Font Awesome icons](https://fortawesome.github.io/Font-Awesome/icons/),
  default - ["bars"](http://fortawesome.github.io/Font-Awesome/icon/bars/)
  """
  defmacro sort_handle_column(fa_icon_name \\ "bars") do
    quote do
      column("", [], fn _ ->
        i("", class: "fa fa-#{unquote(fa_icon_name)} handle", "aria-hidden": "true")
      end)
    end
  end

  @doc """
  Add a row to the attributes table on the show page.

  See `column/3` for a list of options.
  """
  defmacro row(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts(unquote(opts), unquote(fun))
      var!(rows, ExAdmin.Show) = [{unquote(name), opts} | var!(rows, ExAdmin.Show)]
    end
  end

  @doc """
  Add a link to a path
  """
  defmacro link_to(name, path, opts \\ quote(do: [])) do
    quote do
      opts = Keyword.merge([to: unquote(path)], unquote(opts))
      Phoenix.HTML.Link.link("#{unquote(name)}", opts)
    end
  end

  @doc false
  # Note: `actions/2` has been deprecated. Please use `action_items/1` instead
  defmacro actions(:all, opts \\ quote(do: [])) do
    require Logger
    Logger.warn("actions/2 has been deprecated. Please use action_items/1 instead")

    quote do
      opts = unquote(opts)
      Module.put_attribute(__MODULE__, :actions, unquote(opts))
    end
  end

  @doc """
  Define which actions will be displayed.
  Action labels could be overriden with `labels` option.

  ## Examples

      action_items except: [:new, :delete, :edit]
      action_items only: [:new]
      action_items labels: [delete: "Revoke"]

  Notes:

  * this replaces the deprecated `actions/2` macro
  * `action_items` macro will not remove any custom actions defined by the `action_item` macro.

  """
  defmacro action_items(opts \\ nil) do
    quote do
      opts = unquote(opts)
      Module.put_attribute(__MODULE__, :actions, unquote(opts))
    end
  end

  @doc """
  Add an id based action and show page link.

  Member actions are those actions that act on an individual record in
  the database.

  ## Examples

  The following example illustrates how to add a restore action to
  a backup and restore page.

      member_action :restore,  &__MODULE__.restore_action/2

      ...

      def restore_action(conn, params) do
        case BackupRestore.restore Repo.get(BackupRestore, params[:id]) do
          {:ok, filename} ->
            Controller.put_flash(conn, :notice, "Restore \#{filename} complete.")
          {:error, message} ->
            Controller.put_flash(conn, :error, "Restore Failed: \#{message}.")
        end
        |> Controller.redirect(to: ExAdmin.Utils.admin_resource_path(conn, :index))
      end

  The above example adds the following:

  * a custom `restore` action to the controller, accessible by the route
      /admin/:resource/:id/member/restore
  * a "Restore" action link to the show page

  ## Options

  * an optional label: "Button Label"

  """
  defmacro member_action(name, fun, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :member_actions,
        {unquote(name), [fun: unquote(fun), opts: unquote(opts)]}
      )
    end
  end

  @doc """
  Add a action that acts on a collection and adds a link to the index page.

  ## Examples

  The following example shows how to add a backup action on the index
  page.

      collection_action :backup, &__MODULE__.backup_action/2, label: "Backup Database!"

      def backup_action(conn, _params) do
        Repo.insert %BackupRestore{}
        Controller.put_flash(conn, :notice, "Backup complete.")
        |> Controller.redirect(to: ExAdmin.Utils.admin_resource_path(conn, :index))
      end

  The above example adds the following:

  * a custom `backup` action to the controller, accessible by the route
      /admin/:resource/collection/backup
  * a "Backup Database!" action link to the show page

  ## Options

  * an optional label: "Button Label" (shown above)

  """
  defmacro collection_action(name, fun, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :collection_actions,
        {unquote(name), [fun: unquote(fun), opts: unquote(opts)]}
      )
    end
  end

  @doc """
  Clear the default [:edit, :show, :new, :delete] action items.

  Can be used alone, or followed with `action_item` to add custom actions.
  """

  defmacro clear_action_items! do
    quote do
      Module.delete_attribute(__MODULE__, :actions)
      Module.register_attribute(__MODULE__, :actions, accumulate: true, persist: true)
    end
  end

  @doc """
  Add a custom action button to the page.

  ## Examples

  The following example demonstrates how to add a custom button to your
  index page, with no other action buttons due to the `clear_action_items!`
  call.

      clear_action_items!

      action_item :index, fn ->
        action_item_link "Something Special", href: "/my/custom/route"
      end

  An example of adding a link to the show page

      action_item :show, fn id ->
        action_item_link "Show Link", href: "/custom/link", "data-method": :put, id: id
      end
  """
  defmacro action_item(opts, fun) do
    fun = Macro.escape(fun, unquote: true)

    quote do
      Module.put_attribute(__MODULE__, :actions, {unquote(opts), unquote(fun)})
    end
  end

  @doc """
  Customize the filter pages on the right side of the index page.

  ## Examples

  Disable the filter view:

      filter false

  Only show index columns and filters for the specified fields:

      filter [:name, :email, :inserted_at]
      filter [:name, :inserted_at, email: [label: "EMail Address"]]
      filter [:name, :inserted_at, posts: [order_by: [asc: :name]]]

  Note: Restricting fields with the `filter` macro also removes the field columns
  from the default index table.

  """
  defmacro filter(disable) when disable in [nil, false] do
    quote do
      Module.put_attribute(__MODULE__, :index_filters, false)
    end
  end

  defmacro filter(fields) when is_list(fields) do
    quote do
      Module.put_attribute(__MODULE__, :index_filters, unquote(fields))
    end
  end

  defmacro filter(field, opts \\ quote(do: [])) do
    quote do
      Module.put_attribute(__MODULE__, :index_filters, {unquote(field), unquote(opts)})
    end
  end

  @doc """
  Disable the batch_actions button the index page.

  ## Examples

      batch_actions false
  """
  defmacro batch_actions(false) do
    quote do
      Module.put_attribute(__MODULE__, :batch_actions, false)
    end
  end

  @doc false
  def build_query_association(module, field) do
    case module.__schema__(:association, field) do
      %Ecto.Association.BelongsTo{cardinality: :one} ->
        field

      %Ecto.Association.Has{cardinality: :many} ->
        check_preload(field, :preload_many)

      _ ->
        nil
    end
  end

  defp check_preload(field, key) do
    if Application.get_env(:ex_admin, key, true) do
      field
    else
      nil
    end
  end
end
