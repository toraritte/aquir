defmodule Aquir.Commanded.ContextWrapper do

  defmacro __using__(modules) do

    # use Wrapper, [B,C]
    #
    #> modules =
    #  [
    #    {:__aliases__, [line: 5, counter: -576460752303423229], [:B]},
    #    {:__aliases__, [line: 5, counter: -576460752303423229], [:C]}
    #  ]
    #
    # use Wrapper, B
    #
    # modules = {:__aliases__, [line: 1, counter: -576460752303423005], [:B]}

    modules =
      case is_list(modules) do
        false -> [modules]
        true  -> modules
      end

    user_defs =
      Enum.reduce(modules, [], fn(mod_ast, acc) ->
        exports =
          mod_ast
          |> Macro.expand(__ENV__)
          |> apply(:module_info, [:exports])

        pre_defs = [module_info: 0, module_info: 1, __info__: 1]

        [ {mod_ast, exports -- pre_defs} | acc]
      end)

    for {module, exports} <- user_defs do
      for {func_name, arity} <- exports do
        args = make_args(arity)
        quote do
          def unquote(func_name)(unquote_splicing(args)) do
            unquote(module).unquote(func_name)(unquote_splicing(args))
          end
        end
      end
    end
  end

  defp make_args(0), do: []
  defp make_args(arity) do
    Enum.map 1..arity, &(Macro.var :"arg#{&1}", __MODULE__)
  end
end

# defmodule WrapperTest do
#   use ExUnit.Case, async: true

#   use Wrapper, :lists

#   test "max function works properly" do
#     assert (max [1, 2]) == 2
#   end
# end
