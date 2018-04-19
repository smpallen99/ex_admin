defmodule ExAdmin.ViewHelpers do
  @moduledoc false
  use Xain
  import ExAdmin.Utils
  import ExAdmin.Gettext
  require Logger

  @endpoint Application.get_env(:ex_admin, :endpoint)

  def endpoint, do: @endpoint

  # defmacro __using__(_opts) do
  #   import unquote(__MODULE__)
  #   import UcxNotifier.Admin.ViewHelpers.Table
  # end

  @doc """
  Build an action item link.
  """
  def action_item_link(name, opts) do
    {:custom, [{name, opts}]}
  end

  def flashes(conn) do
    markup safe: true do
      messages =
        Enum.reduce([:notice, :error], [], fn which, acc ->
          acc ++ get_flash(conn, which)
        end)

      if messages != [] do
        div ".flashes" do
          Enum.map(messages, fn {which, flash} ->
            div(".flash.flash_#{which} #{flash}")
          end)
        end
      end
    end
  end

  def get_flash(conn, which) do
    case Phoenix.Controller.get_flash(conn, which) do
      nil ->
        []

      flash ->
        [{which, flash}]
    end
  end

  def page_title(conn, resource) do
    plural = displayable_name_plural(conn)
    singular = Inflex.singularize(plural)

    case ExAdmin.Utils.action_name(conn) do
      :index ->
        plural

      :show ->
        cond do
          function_exported?(
            ExAdmin.get_registered(resource.__struct__).__struct__,
            :display_name,
            1
          ) ->
            apply(ExAdmin.get_registered(resource.__struct__).__struct__, :display_name, [
              resource
            ])

          function_exported?(resource.__struct__, :display_name, 1) ->
            apply(resource.__struct__, :display_name, [resource])

          true ->
            ExAdmin.Helpers.resource_identity(resource)
        end

      action when action in [:edit, :update] ->
        gettext("Edit") <> " #{singular}"

      action when action in [:new, :create] ->
        gettext("New") <> " #{singular}"

      _ ->
        ""
    end
  end

  def status_tag(nil), do: status_tag(false)

  def status_tag(status) do
    span(".status_tag.#{status} #{status}")
  end

  def build_link(action, opts, html_opts \\ [])
  def build_link(_action, opts, _) when opts in [nil, []], do: ""

  def build_link(_action, [{name, opts} | _], html_opts) do
    attrs =
      Enum.reduce(opts ++ html_opts, "", fn {k, v}, acc ->
        acc <> "#{k}='#{v}' "
      end)

    Phoenix.HTML.raw("<a #{attrs}>#{name}</a>")
  end

  @js_escape_map Enum.into(
                   [
                     {"^", ""},
                     {~S(\\), ~S(\\\\)},
                     {~S(</), ~S(<\/)},
                     {"\r\n", ~S(\n)},
                     {"\n", ~S(\n)},
                     {"\r", ~S(\n)},
                     {~S("), ~S(\")},
                     {"'", "\\'"}
                   ],
                   %{}
                 )
  # {~S(\"), ~S(\\")},

  def escape_javascript(unescaped) do
    # Phoenix.HTML.safe _escape_javascript(unescaped)
    # IO.puts "escape_javascript: unescaped: #{inspect unescaped}`"
    res =
      Phoenix.HTML.safe_to_string(unescaped)
      |> String.replace("\n", "")
      |> _escape_javascript

    # IO.puts "escape_javascript: #{inspect res}"
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
    Regex.replace(~r/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'^])/u, javascript, fn match ->
      @js_escape_map[match]
    end)
  end

  def decimal_to_currency(%Decimal{} = num, opts \\ []) do
    del = opts[:delimiter] || "$"
    sep = opts[:seperator] || "."
    rnd = opts[:round] || 2

    neg_opts =
      case opts[:negative] do
        nil -> {"-", ""}
        {pre, post} -> {"#{pre}", "#{post}"}
        pre -> {"#{pre}", ""}
      end

    case Decimal.round(num, rnd) |> Decimal.to_string() |> String.split(".") do
      [int, dec] ->
        del <> wrap_negative(int <> sep <> String.pad_trailing(dec, 2, "0"), neg_opts)

      [int] ->
        del <> wrap_negative(int <> sep <> "00", neg_opts)
    end
  end

  defp wrap_negative("-" <> num, {neg_pre, neg_post}) do
    "#{neg_pre}#{num}#{neg_post}"
  end

  defp wrap_negative(num, _), do: num

  def truncate(string, opts \\ []) when is_binary(string) do
    length = Keyword.get(opts, :length, 30)
    omission = Keyword.get(opts, :omission, "...")

    if String.length(string) < length do
      string
    else
      String.slice(string, 0, length) <> omission
    end
  end

  def auto_link(resource) do
    case resource.__struct__.__schema__(:fields) do
      [_, field | _] ->
        name = Map.get(resource, field, "Unknown")
        a(name, href: admin_resource_path(resource, :show))

      _ ->
        ""
    end
  end
end
