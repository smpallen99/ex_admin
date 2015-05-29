defmodule ExAdmin.Register do

  # Module.register_attribute ExAdmin, :registered, accumulate: true, persist: true
  @filename "/tmp/ex_admin_registered" 

  import ExAdmin.Utils

  defmacro __using__(_) do
    quote do
      use ExAdmin.Index
      use ExAdmin.Show
      use ExAdmin.Form, except: [actions: 1]
      use ExAdmin.CSV
      import unquote(__MODULE__)
      import Ecto.Query, only: [from: 2]
      import Xain, except: [input: 1, input: 2, input: 3, menu: 1, form: 2]
      Module.register_attribute __MODULE__, :member_actions, accumulate: true, persist: true
      Module.register_attribute __MODULE__, :collection_actions, accumulate: true, persist: true
    end
  end

  File.rm @filename
  File.touch @filename

  defmacro register_resource(mod, [do: block]) do
    quote location: :keep do
      require Logger
      Module.register_attribute __MODULE__, :query, accumulate: false, persist: true
      Module.register_attribute __MODULE__, :index_filters, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :batch_actions, accumulate: true, persist: true 
      Module.register_attribute __MODULE__, :selectable_column, accumulate: false, persist: true
      module = unquote(mod) 
      Module.put_attribute(__MODULE__, :module, module)

      alias unquote(mod)
      import ExAuth
      import Ecto.Query
      
      def config do
        apply __MODULE__, :__struct__, []
      end
      
      unquote(block)

      query_opts = Module.get_attribute(__MODULE__, :query)
      controller = case Module.get_attribute(__MODULE__, :controller) do
        nil -> 
          controller_mod = String.to_atom("#{module}Controller")
          Module.put_attribute(__MODULE__, :controller, controller_mod)
        other -> 
          Logger.warn "Should not get here - controller: #{inspect other}"
      end

      menu_opts = case Module.get_attribute(__MODULE__, :menu) do
        nil -> 
          %{ priority: 10, 
             label: (base_name(module) |> Inflex.pluralize)}
        other -> 
          Enum.into other, %{}
      end
      all_options = [:edit, :show, :new, :delete]
      actions = case Module.get_attribute(__MODULE__, :actions) do
        nil -> all_options
        list when is_list(list) -> list
        opts -> 
          case Enum.into opts, %{} do
            %{except: except} -> all_options -- except
            %{only: only} -> only
          end
      end

      defstruct controller: @controller, 
                controller_methods: Module.get_attribute(__MODULE__, :controller_methods),
                title_actions: &ExAdmin.default_resource_title_actions/2,
                type: :resource,
                resource_name: module,
                query_opts: query_opts,
                controller_route: (base_name(module) |> Inflex.parameterize("_") |> Inflex.pluralize),
                menu: menu_opts, 
                actions: actions, 
                member_actions: Module.get_attribute(__MODULE__, :member_actions),
                collection_actions: Module.get_attribute(__MODULE__, :collection_actions),
                controller_filters: Module.get_attribute(__MODULE__, :controller_filters), 
                index_filters: Module.get_attribute(__MODULE__, :index_filters),
                selectable_column: Module.get_attribute(__MODULE__, :selectable_column), 
                batch_actions: Module.get_attribute(__MODULE__, :batch_actions)


      def run_query(repo, action, id \\ nil) do
        resource_name = %__MODULE__{}
        |> Map.get(:resource_name)
        |> ExAdmin.Query.run_query(repo, action, id, @query)
      end
      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end



  defmacro controller([do: block]) do
    quote do
      Module.register_attribute(__MODULE__, :controller_methods, accumulate: false, persist: true)
      Module.register_attribute(__MODULE__, :controller_filters, accumulate: true, persist: true)
      Module.put_attribute(__MODULE__, :controller_methods, [])
      unquote(block)
    end
  end
  defmacro controller(controller_mod) do
    quote do
      Module.put_attribute __MODULE__, :controller, unquote(controller_mod)
    end
  end

  defmacro define_method(name, [do: block]) do
    quote do
      methods = Module.get_attribute(__MODULE__, :controller_methods)

      Module.put_attribute(__MODULE__, :controller_methods, [{unquote(name), []} | methods])
      #Module.put_attribute(__MODULE__, :last_controller_method, unquote(name))
      unquote(block)
    end
  end

  defmacro before_filter(name, opts) do
    quote do
      Module.put_attribute(__MODULE__, :controller_filters, {:before_filter, {unquote(name), unquote(opts)}})
    end
  end

  defmacro redirect_to(path) do
    quote do
      [{name, opts} | tail] = Module.get_attribute(__MODULE__, :controller_methods)
      new_opts = [{:redirect_to, unquote(path)} | opts]
      Module.put_attribute(__MODULE__, :controller_methods, [{name, new_opts} | tail])
    end
  end

  defmacro register_page(name, [do: block]) do
    quote do
      page_name = unquote(name)
      unquote(block)

      menu_opts = case Module.get_attribute(__MODULE__, :menu) do
        :none -> 
          %{none: true}
        nil -> 
          %{label: page_name, priority: 99}
        other -> 
          Enum.into other, %{}
      end

      controller_methods = Module.get_attribute(__MODULE__, :controller_methods)

      defstruct controller: UcxCallout.AdminController,
                controller_methods: controller_methods,
                type: :page,
                resource_name: String.to_atom(page_name),
                title_actions: &ExAdmin.default_page_title_actions/2,
                controller_route: (page_name |> Inflex.parameterize("_")),
                menu: menu_opts

      File.write!(unquote(@filename), "#{__MODULE__}\n", [:append])
    end
  end

  defmacro menu(opts) do
    quote do
      Module.put_attribute __MODULE__, :menu, unquote(opts)
    end 
  end

  defmacro query(do: qry) do
    quote do
      Module.put_attribute __MODULE__, :query, unquote(qry)
    end
  end

  defmacro column(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts unquote(opts), unquote(fun)
      var!(columns, ExAdmin.Show) = [{unquote(name), (opts)} | var!(columns, ExAdmin.Show)]
    end
  end

  defmacro row(name, opts \\ [], fun \\ nil) do
    quote do
      opts = ExAdmin.DslUtils.fun_to_opts unquote(opts), unquote(fun)
      var!(rows, ExAdmin.Show) = [{unquote(name), opts} | var!(rows, ExAdmin.Show)]
    end
  end

  defmacro link_to(name, path, opts \\ quote(do: [])) do
    quote do
      opts = Keyword.merge [to: unquote(path)], unquote(opts)
      Phoenix.HTML.Link.link "#{unquote(name)}", opts
    end
  end

  defmacro actions(:all, opts \\ quote(do: [])) do
    quote do
      opts = unquote(opts)
      Module.put_attribute __MODULE__, :actions, unquote(opts)
    end
  end

  defmacro member_action(name, fun) do
    quote do
      Module.put_attribute __MODULE__, :member_actions, {unquote(name), unquote(fun)}
    end
  end
  defmacro collection_action(name, fun) do
    quote do
      Module.put_attribute __MODULE__, :collection_actions, {unquote(name), unquote(fun)}
    end
  end

  defmacro clear_action_items! do
    quote do
      Module.register_attribute __MODULE__, :actions, accumulate: true, persist: true
    end
  end
  defmacro action_item(opts, fun) do
    fun = Macro.escape(fun, unquote: true)
    quote do
      Module.put_attribute __MODULE__, :actions, {unquote(opts), unquote(fun)}
    end
  end

  defmacro filter(false) do
    quote do
      Module.put_attribute __MODULE__, :index_filters, false
    end
  end
  defmacro filter(field, opts \\ quote(do: [])) do
    quote do 
      Module.put_attribute __MODULE__, :index_filters, {unquote(field), unquote(opts)}
    end
  end

  defmacro batch_actions(false) do
    quote do
      Module.put_attribute __MODULE__, :batch_actions, false
    end
  end

end

