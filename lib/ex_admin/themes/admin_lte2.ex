defmodule ExAdmin.Theme.AdminLte2 do
  @moduledoc false
  use Xain
  import ExAdmin.Utils
  # import ExAdmin.ViewHelpers
  import ExAdmin.Form, only: [required_abbr: 1]

  @name "admin_lte2"

  def name, do: @name

  def get_form_error_class(error) do
    unless error == "", do: ".has-error", else: ""
  end

  def build_form_error(error) do
    label ".control-label" do
      i(".fa.fa-times-circle-o")
      text(" #{ExAdmin.Form.error_messages(error)}")
    end
  end

  def wrap_item_type(:boolean, label, ext_name, contents, error, _required) do
    error = get_form_error_class(error)

    div ".col-sm-offset-2.col-sm-10#{error}" do
      div ".checkbox" do
        label do
          contents.(ext_name)
          humanize(label) |> text
        end
      end
    end
  end

  def wrap_item_type(_type, label, ext_name, contents, error, required) do
    error = get_form_error_class(error)

    markup do
      label ".col-sm-2.control-label", for: ext_name do
        text(humanize(label))
        required_abbr(required)
      end

      div ".col-sm-10#{error}" do
        contents.(ext_name)
      end
    end
  end
end
