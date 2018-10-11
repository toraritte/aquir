defmodule Aquir do
  @moduledoc """
  Aquir keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
Agent.start_link(fn -> :ok end, name: :lofa)

f = fn (command, t) ->
      apply(Agent, command, [
        :lofa,
        fn _ ->
          Process.sleep(t)
          IO.puts("|#{inspect(self())}| #{command} finished")
        end
      ])
    end

t = 4000
f.(:cast, t)

f.(:update, t)

try do
  f.(pid, :update, 7000)
catch
  :exit, reason -> IO.inspect(reason)
end

Enum.each(
  [cast: t, update: t],
  &f.(:lofa, elem(&1,0), elem(&1,1))
)



end
