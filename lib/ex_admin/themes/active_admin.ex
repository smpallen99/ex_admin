defmodule ExAdmin.Theme.ActiveAdmin do
  use Xain
  import ExAdmin.Utils
  import ExAdmin.ViewHelpers

  @name "active_admin"

  def name, do: @name

  def get_form_error_class(error) do
    unless error == "", do: ".has-error", else: ""
  end


  def wrap_item_type(:boolean, label, ext_name, contents, error) do
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

  def wrap_item_type(_type, label, ext_name, contents, error) do
    error = get_form_error_class(error)
    label(".col-sm-2.control-label #{humanize label}", for: ext_name)
    div ".col-sm-10#{error}" do
      contents.(ext_name)
    end
  end
end

defimpl ExAdmin.Theme, for: ExAdmin.Theme.ActiveAdmin do
  alias ExAdmin.Theme
  use Xain
  import ExAdmin.Utils
  import ExAdmin.ViewHelpers

end
