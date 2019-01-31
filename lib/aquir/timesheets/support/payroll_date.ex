# TODO: payroll-date struct?
defmodule PayrollDate do

  @external_resource "./lib/aquir/timesheets/support/payroll-days"
  # ezt az egesz lofaszt ugy ahogy van atvarialni
  # mert osszevissza van konvertalgatva minden
  # meg talan PayrollDate -> Payroll.Date
  defmodule Parse do
    def parse_payroll_file(file) do
      by_newline = ~r/[\n]+/

      file
      |> File.read!
      |> String.split(by_newline)
      |> Enum.reject(&comments_and_empty_lines(&1))
      |> Enum.map(&to_individual_dates(&1))
      # |> Enum.map(&line_to_excel_dates(&1))

      # OUTPUT
      # [
      #   ["2/16/2017", "2/28/2017", "3/10/2017", "2/28/2017", "2/20/2017"],
      #   ["3/1/2017", "3/15/2017", "3/24/2017", "3/15/2017"], 
      #   ...
      # ]
    end

    defp comments_and_empty_lines(line) do
      line
      #         match "", "   ", "# blabla"
      |> String.match?(~r/^($|[#\s]+)/)
    end

    # defp line_to_excel_dates(line) do
    #   line
    #   |> to_individual_dates
    #   |> Enum.map(&Excel.convert(&1))
    # end

    defp to_individual_dates(line) do
      line
      |> String.split(~r/[\s-,]+/, trim: true)
    end
  end

  defmodule Convert do
    require Excel.Date
    require Excel.Maker

    p = Parse.parse_payroll_file("./lib/aquir/timesheets/support/payroll-days")
    [a,_,_|_] = List.first(p)
    [_,_,z|_] = List.last(p)

    Excel.Maker.make_converts(a,z)
  end

  # 2019-01-30_1630 QUESTION (No `quote` needed in `defmodule` root?)
  parsed = Parse.parse_payroll_file("./lib/aquir/timesheets/support/payroll-days")
  # require IEx; IEx.pry

  for lines <- parsed do
    [a, z, pay_date, due_date|holidays] = lines

    [aE, zE, pay_dateE, due_dateE] =
      Enum.map(
        [a, z, pay_date, due_date],
        &Excel.Date.to_excel_time/1
      )

    range = Excel.Date.range(a,z)

    payroll_period =
      range
      |> Enum.map(
           fn({excel_date, map_date, mdy_date}) ->
            is_it_holiday = Enum.member?(holidays, mdy_date)

            %{excel_date:   excel_date,
              pretty_date:  Excel.Date.pretty_date(map_date),
              is_holiday?:     is_it_holiday
             }
           end
         )

    for {excel_date, map_date, mdy_date} <- range do
      def get_payroll_period(unquote(excel_date)) do
        %{period_dates: unquote(Macro.escape(payroll_period)),
          due_date:     unquote(due_dateE),
          pay_date:     unquote(pay_dateE),
          period_start: unquote(aE),
          period_end:   unquote(zE)
        }
      end
      def get_payroll_period(unquote(mdy_date)) do
        get_payroll_period(unquote(excel_date))
      end
      def get_payroll_period(unquote(Macro.escape(map_date))) do
        get_payroll_period(unquote(excel_date))
      end
    end
  end
end
