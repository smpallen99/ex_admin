defmodule ExAdmin.ViewHelpers do
  @moduledoc false
  use Xain
  import ExAdmin.Utils

  @endpoint Application.get_env(:ex_admin, :endpoint)

  def endpoint, do: @endpoint

  # defmacro __using__(_opts) do
  #   import unquote(__MODULE__)
  #   import UcxNotifier.Admin.ViewHelpers.Table 
  # end

  def title_bar(conn, resource) do
    markup do
      div("#title_bar.title_bar") do
        title_bar_left(conn, resource)
        title_bar_right(conn)
      end
    end
  end

  def flashes(conn) do
    markup do
      messages = Enum.reduce [:notice, :error], [], fn(which, acc) -> 
        acc ++ get_flash(conn, which)
      end
      unless messages == [] do
        div(".flashes") do
          Enum.each messages, fn({which, flash}) -> 
            div(".flash.flash_#{which} #{flash}")
          end
        end
      end
    end
  end

  def get_flash(conn, which) do
    case Phoenix.Controller.get_flash(conn, which) do
      nil -> []
      flash -> 
        [{which, flash}]
    end
  end

  def page_title(conn, resource) do
    plural = get_resource_label conn
    singular = Inflex.singularize plural
    case ExAdmin.Utils.action_name(conn) do
      :index -> 
        plural
      :show -> 
        ExAdmin.Helpers.resource_identity(resource)
      :edit -> 
        "Edit #{singular}"
      :new -> 
        "New #{singular}"
      _ -> 
        ""
    end
  end


  defp title_bar_left(conn, resource) do
    div("#titlebar_left") do
      span(".breadcrumb") do
        a(href: "/admin")
        span(".breadcrumb_sep")
      end

      h2("#page_title #{page_title(conn, resource)}")
    end
  end
  
  defp title_bar_right(conn) do
    #controller = controller_name(conn)
    #try do
      div("#titlebar_right") do
        ExAdmin.get_title_actions(conn)
        # div(".action_items") do
        #   span(".action_item") do
        #     a("New #{controller}", href: get_route_path(conn, controller, :new))
        #   end
        # end
      end
    # rescue 
    #   _ -> 
    #     div(acc, "#titlebar_right") 
    # end
  end
  
  @js_escape_map Enum.into([{"^", ""}, { ~S(\\), ~S(\\\\)}, {~S(</), ~S(<\/)}, {"\r\n", ~S(\n)}, {"\n", ~S(\n)}, {"\r", ~S(\n)}, 
    {~S("), ~S(\")}, 
    {"'", "\\'" }], %{})
    #{~S(\"), ~S(\\")}, 

  def escape_javascript(unescaped) do
    #Phoenix.HTML.safe _escape_javascript(unescaped) 
    #IO.puts "escape_javascript: unescaped: #{inspect unescaped}`"
    res = Phoenix.HTML.safe_to_string(unescaped) 
    |> String.replace("\n", "")
    |> _escape_javascript
    #IO.puts "escape_javascript: #{inspect res}"
    res
  end
  def _escape_javascript({:safe, list}) do
    _escape_javascript(list) 
  end
  def _escape_javascript([h | t]) do
    [_escape_javascript(h) | _escape_javascript(t)]
  end
  def _escape_javascript([]), do: []
  def _escape_javascript(javascript) when is_binary(javascript) do
    Regex.replace(~r/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'^])/u, javascript, fn(match) -> @js_escape_map[match] end)
  end
end
