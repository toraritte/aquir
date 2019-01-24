defmodule AquirWeb.ErrorHelpers do

  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  # 2019-01-24_1208 TODO (Make `error_tag/2` accessible)

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    errors = form.errors
    if msg_list = Keyword.get(errors, field) do
      error_spans =
        Enum.map(
          msg_list,
          fn (msg) ->
            content_tag :span, msg, class: "help-block"
          end)

      content_tag(:div, error_spans)
    end
  end

  # 2019-01-24_0929 TODO (Translate error messages with `Gettext`)
  @doc """
  Translates an error message using gettext.
  """
  #def translate_error({msg, opts}) do
  #  # When using gettext, we typically pass the strings we want
  #  # to translate as a static argument:
  #  #
  #  #     # Translate "is invalid" in the "errors" domain
  #  #     dgettext "errors", "is invalid"
  #  #
  #  #     # Translate the number of files with plural rules
  #  #     dngettext "errors", "1 file", "%{count} files", count
  #  #
  #  # Because the error messages we show in our forms and APIs
  #  # are defined inside Ecto, we need to translate them dynamically.
  #  # This requires us to call the Gettext module passing our gettext
  #  # backend as first argument.
  #  #
  #  # Note we use the "errors" domain, which means translations
  #  # should be written to the errors.po file. The :count option is
  #  # set by Ecto and indicates we should also apply plural rules.
  #  if count = opts[:count] do
  #    Gettext.dngettext(AquirWeb.Gettext, "errors", msg, msg, count, opts)
  #  else
  #    Gettext.dgettext(AquirWeb.Gettext, "errors", msg, opts)
  #  end
  #end
end
