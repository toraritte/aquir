 defmodule Excel do
  # TODO: extract this into the Excel templating app

  # TODO: creating a SimpleDate struct would probably be a good idea,
  #       along the lines of %{year: y, month: m, day: d}

  # TODO: check out `use` to preset some module options
  #       see Phoenix's web.ex that nicely sets up all of Phoenix's tools

  # RATIONALE:
  # PayrollDate now calls an Excel macro providing it with
  # start and end dates. This could probably be coordinated with
  # `use` more simply.
  # I don't think the direct macro call is fundamentally wrong
  # I assume it would make it less convoluted. (Although I learned
  # a lot by figuring it out during the process. On the other hand
  # hammering in screws is fun but not the best idea:)

  # TODO: remove hard-coded filenames (e.g., Excel.Template.read<->timesheet.xlsx or
  #       Excel.Template.render<->CORE_approver.png) by using a mix initial
  #       setup like Phoenix (see previous TODO).

  defmodule Date do
    def get_date_from_console do
      {dateStr, 0} = System.cmd("date", ["+%m/%d/%Y"])
      dateStr
      |> String.split("\n")
      |> List.first
      |> mdy_to_map
      |> map_to_mdy
    end

    def mdy_to_map(str) do
      [m, d, y] =
        str
        |> String.split("/")
        |> Enum.map(fn s -> String.to_integer(s) end)
      %{year: y, month: m, day: d}
    end

    def map_to_mdy(%{year: y, month: m, day: d}) do
      "#{m}/#{d}/#{y}"
    end

    def to_excel_time(date) when is_binary(date) do
      date
      |> mdy_to_map
      |> to_excel_time
    end
    def to_excel_time(%{year: y} = date) when is_map(date) do
      full_years = y-1900
      leap_years = div(full_years, 4)
      non_leap_years = full_years - leap_years

      count_from_full_years = leap_years*366 + non_leap_years*365

      result = count_from_full_years + count_from_current_year(date)

      # For some reason, calculating leap years resulted in a value
      # always larger by one than the actual value. I couldn't find
      # the answer in 15 minutes, hence this:
      case rem(y, 4) do
        0 -> result
        _ -> result+1
      end
    end

    defp count_from_current_year(%{year: y, month: m, day: d}) do
      days_up_to_current_month =
        case m-1 do
          0 -> 0;
          n -> Enum.reduce(
                  1..n,
                  0,
                  fn i, acc ->
                    acc + Calendar.ISO.days_in_month(y,i)
                  end)
        end
      days_up_to_current_month + d
    end

    def from_excel_time(i) do
      i
      |> from_excel_time(:map)
      |> map_to_mdy
    end
    def from_excel_time(i, :map) do
      calculate_date(i, 1900, 1)
    end

    defp calculate_date(d, year, month) do
      days_in_month = Calendar.ISO.days_in_month(year, month)

      case d <= days_in_month do
        true ->
          %{year: year, month: month, day: d}
        false ->
          new_d     = d - days_in_month
          new_year  = next_year(year, month)
          new_month = next_month(month)

          calculate_date(new_d, new_year, new_month)
      end
    end

    defp next_year(year,  12),  do: year+1
    defp next_year(year,  _),   do: year

    defp next_month(12),     do: 1
    defp next_month(month),  do: month+1

    def day_of_the_week(%{year: y, month: m, day: d}) do
      day_num = Calendar.ISO.day_of_week(y,m,d)
      days  =
        ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)
        |> List.to_tuple
      elem(days, day_num-1)
    end

    def pretty_date(%{year: y, month: m, day: d} = map_date) do
        months =
          ~w(January February March April May June July August September October November December)
          |> List.to_tuple
        "#{day_of_the_week(map_date)}, #{elem(months,m-1)} #{d}, #{y}"
    end

    # a and z are mdy dates
    def range(a,z) do
      start_excel_date = to_excel_time(a)
      end_excel_date   = to_excel_time(z)

      start_map_date =  mdy_to_map(a)

      range(start_map_date, start_excel_date, end_excel_date, [])
    end
    def range(date, z, z, acc) do
      date_tuple = {z, date, map_to_mdy(date)}

      [date_tuple|acc]
      |> Enum.reverse
    end
    def range(%{year: y, month: 12, day: d} = date, a, z, acc) do

      new_date =
        case Calendar.ISO.days_in_month(y,12) == d do
          true ->
            %{year: y+1, month: 1, day: 1}
          false ->
            %{year: y, month: 12, day: d+1}
        end

      date_tuple = {a, date, map_to_mdy(date)}

      range(new_date, a+1, z, [date_tuple|acc])
    end
    def range(%{year: y, month: m, day: d} = date, a, z, acc) do

      new_date =
        case Calendar.ISO.days_in_month(y,m) == d do
          true ->
            %{year: y, month: m+1, day: 1}
          false ->
            %{year: y, month: m, day: d+1}
        end

      date_tuple = {a, date, map_to_mdy(date)}

      range(new_date, a+1, z, [date_tuple|acc])
    end

    # unquote mayhem
    defmacro make_convert(excel_date, map_date, mdy_date) do
      quote bind_quoted: [e: excel_date, m: map_date, mdy_date: mdy_date] do
        # Left this here for posterity and because it took me a while
        # to figure out. (I know, rocket science.)
        #
        #     {_, _, l} = m
        #     mdy_date =
        #       l
        #       |> Enum.into(%{})
        #       |> Date.map_to_mdy()

        def excel_date_to_map(unquote(e)),         do: unquote(m)
        def map_to_excel_date(unquote(m)),         do: unquote(e)
        def excel_date_to_mdy(unquote(e)),         do: unquote(mdy_date)
        def mdy_to_excel_date(unquote(mdy_date)),  do: unquote(e)
        def map_to_mdy(unquote(m)),                do: unquote(mdy_date)
        def mdy_to_map(unquote(mdy_date)),         do: unquote(m)
      end
    end
  end

  # Most of the error checking should be on the client-side (others, formats etc)
  defmodule Parse do
    def read do
      {:ok, xlsx} = :zip.unzip('_excel_template/timesheet.xlsx', [:memory])
      xlsx
    end

    def retrieve_needed(zip_list) do
      n = ['xl/worksheets/sheet1.xml',
           'xl/sharedStrings.xml'
          ]

      zip_list
      |> Enum.filter(fn({f,_}) ->
           Enum.member?(n, f)
         end)
    end

    def massage(params) do
      {extra, time_params} = Map.split(params["ts"], ~w(name title department pay_date due_date period_start period_end))

      %{ extras: extra,
         times:  do_massage(time_params)
       }
    end

    def do_massage(time_params) do
      time_params
      |> parse_to_maps()
      |> sanitize_pipeline()
      |> Enum.into(%{})
    end

    def parse_to_maps(time_params) do
      Enum.reduce(
        time_params,
        %{},
        fn({id, time_str}, acc) ->
          [i_str,label] = id |> String.split("_", parts: 2)

          i        = i_str   |> String.to_integer()
          label_id = label   |> String.to_atom()

          k  = Map.new([{label_id, time_str}])

          map =
            case acc[i] do
              nil -> k
              m   -> Map.merge(k,m)
            end

          Map.put(acc, i, map)
        end)
    end

    defp sanitize_pipeline(time_params) do
      Enum.map(
        time_params,
        fn({excel_date, time_cells}) ->
          new_t =
            time_cells
            |> tuplize_time()
            |> pm_adjust()
            |> add_daily_sum()
            |> check_others()

          {excel_date, new_t}
        end)
    end

    def pm_adjust(time_cells, order \\ daily_time_columns_in_strict_order() )
    def pm_adjust(time_cells, [_]) do
      time_cells
    end
    def pm_adjust(time_cells, [a,b|rest]) do

      { t1, {h2,m2}=t2 } = {time_cells[a], time_cells[b]}

      new_time_cells =
        case to_minutes(t1) <= to_minutes(t2) do
          false -> Map.put(time_cells, b, {h2+12, m2})
          true  -> time_cells
        end

      pm_adjust(new_time_cells, [b|rest])
    end

    def to_minutes({h,m}),       do: h*60+m
    def to_hour_minute_tuple(m), do: { div(m,60), rem(m,60) }

    def add_daily_sum(time_cells) do
      Map.put(time_cells, :daily_sum, daily_sum(time_cells))
    end

    def daily_sum(time_cells) do
      # [ams, ame, pms, pme] =
      #   [amst, amet, pmst, pmet]
      #   |> Enum.map(&to_minutes/1)

      new_t = extract_and_map_non_others(time_cells, &to_minutes/1)

      to_hour_minute_tuple(
        (new_t.am_end - new_t.am_start) + (new_t.pm_end - new_t.pm_start)
      )
    end

    def daily_time_columns_in_strict_order do
      [:am_start, :am_end, :pm_start, :pm_end]
    end

    def extract_and_map_non_others(time_cells, f \\ fn(a) -> a end) do
      daily_time_columns_in_strict_order()
      |> Enum.map(
           fn(key) ->
             value = time_cells[key]
             {key, f.(value)}
           end)
      |> Enum.into(%{})
    end

    def tuplize_time(p) do
      p                               # map
      |> extract_and_map_non_others() # map
      |> Enum.map(&time_to_tuple/1)   # list
      |> Enum.into(p)                 # list -> map = map
    end

    def time_to_tuple({t, time_str}) do
      time_tuple =
        time_str
        |> String.split(":")
        |> Enum.map(
            fn(s) ->
              [d] = Regex.run(~r/\d+/, s)
              String.to_integer(d)
            end)
        |> List.to_tuple

      {t, time_tuple}
    end

    # TODO: this could be broken if someone edits the <select> tags manually and submits them
    def check_others(%{others: other, others_time: o} = time_cells) do

      other_atom = if (other == ""), do: :none, else: String.to_atom(other)
      o_integer  = if (o == ""),     do: 0,     else: String.to_integer(o)

      Map.merge(time_cells, %{ others: other_atom, others_time: o_integer})
    end
  end

  defmodule Template do

    def render(params) do
      massaged_params = Excel.Parse.massage(params)
IO.puts 27
      Excel.Parse.read()
      |> Enum.map(&render_xml(&1, massaged_params))
    end

    def render_xml(
      {'xl/worksheets/sheet1.xml', xml},
      %{ times:  times,
        extras: %{"department"   => department,
                  "period_start" => period_start,
                  "period_end"   => period_end,
                  "pay_date"     => pay_date,
                  "due_date"     => due_date}}) do

      t = date_row_template(department)

      submitDate =
        Excel.Date.get_date_from_console
        |> Excel.Date.to_excel_time

      new_xml =
        EEx.eval_string(
          xml,
          [ dateRows:    render_date_rows(t, times),
            from:        period_start,
            to:          period_end,
            due_date:    due_date,
            pay_date:    pay_date,
            submitDate:  submitDate,
            sum_row:     sum_row()
          ])

      {'xl/worksheets/sheet1.xml', new_xml}
    end

    def render_xml(
      {'xl/sharedStrings.xml', xml},
      %{ extras: %{"name"  => name,
                   "title" => title}}) do

      new_xml = EEx.eval_string(xml, [name: name, title: title])
      {'xl/sharedStrings.xml', new_xml}
    end
    # def render_xml('xl/media/image2.png') do
      
    # end
    # def render_xml('xl/media/image1.png') do
      
    # end
    def render_xml(other, _params), do: other

    def collect_assigns({:ok, tokens}, default) do
      collect_assigns(tokens, %{}, default)
    end
    def collect_assigns([{:expr,_,_,chars} | rest], acc, default) do
      assign =
        chars
        |> String.Chars.to_string()
        |> String.trim()
        |> String.to_atom()

      new_default =
        case default do
          [] ->
            '<%=' ++ chars ++ '%>'
            |> String.Chars.to_string()
          d -> d
        end

      collect_assigns(rest, Map.put(acc, assign, new_default), default)
    end
    def collect_assigns([_|rest], acc, default), do: collect_assigns(rest, acc, default)
    def collect_assigns([], acc, _), do: Map.to_list(acc)

    def get_default_bindings(str, default) do
      str
      |> EEx.Tokenizer.tokenize(1)
      |> collect_assigns(default)
    end

    # def partial_eval_string(source, bindings, default \\ []) do
    #   new_bindings =
    #     source
    #     |> get_default_bindings(default)
    #     |> Keyword.merge(bindings)

    #   EEx.eval_string(source, new_bindings)
    # end

    def date_row_template(dept \\ "CORE") do
         ~s|<row r="<%= row_number %>" spans="1:19" s="10" customFormat="1" ht="18" customHeight="1" x14ac:dyDescent="0.2">|
      <> ~s|<c r="A<%= row_number %>" s="22"><v><%= date     %></v></c>|
      <> ~s|<c r="B<%= row_number %>" s="27"><v><%= am_start %></v></c>|
      <> ~s|<c r="C<%= row_number %>" s="27"><v><%= am_end   %></v></c>|
      <> ~s|<c r="D<%= row_number %>" s="27"><v><%= pm_start %></v></c>|
      <> ~s|<c r="E<%= row_number %>" s="27"><v><%= pm_end   %></v></c>|
      <> department?(dept)
      <> ~s|<c r="H<%= row_number %>" s="26"><v><%= ot       %></v></c>|
      <> ~s|<c r="I<%= row_number %>" s="26"><v><%= bjd      %></v></c>|
      <> ~s|<c r="J<%= row_number %>" s="26"><v><%= hol      %></v></c>|
      <> ~s|<c r="K<%= row_number %>" s="26"><v><%= ph       %></v></c>|
      <> ~s|<c r="L<%= row_number %>" s="26"><v><%= pto      %></v></c>|
      <> ~s|<c r="M<%= row_number %>" s="26"><v><%= pdo      %></v></c>|
      <> ~s|<c r="N<%= row_number %>" s="26"><f>SUM(F<%= row_number %>:M<%= row_number %>)</f></c>|
      <> ~s|</row>|
    end

    def sum_row do
        ~s|<row r="25" spans="1:14" s="10" customFormat="1" ht="18" customHeight="1" thickBot="1" x14ac:dyDescent="0.25">|
      <> ~s|<c r="A25" s="17"/>|
      <> ~s|<c r="B25" s="18"/>|
      <> ~s|<c r="D25" s="28"/>|
      <> ~s|<c r="E25" s="40" t="s"><v>21</v></c>|
      <> ~s|<c r="F25" s="29"><f>SUM(F9:F24)</f></c>|
      <> ~s|<c r="G25" s="41"><f>SUM(G9:G24)</f></c>|
      <> ~s|<c r="H25" s="29"><f t="shared" ref="H25:M25" si="0">SUM(H9:H24)</f></c>|
      <> ~s|<c r="I25" s="29"><f t="shared" si="0"/></c>|
      <> ~s|<c r="J25" s="29"><f t="shared" si="0"/></c>|
      <> ~s|<c r="K25" s="29"><f t="shared" si="0"/></c>|
      <> ~s|<c r="L25" s="29"><f t="shared" si="0"/></c>|
      <> ~s|<c r="M25" s="29"><f t="shared" si="0"/></c>|
      <> ~s|<c r="N25" s="29"><f>SUM(N9:N24)</f></c>|
      <> ~s|</row>|
    end

    defp department?("CORE") do
         ~s|<c r="F<%= row_number %>" s="26"><v><%= daily_sum %></v></c>|
      <> ~s|<c r="G<%= row_number %>" s="26"/>|
    end
    defp department?("SIP") do
         ~s|<c r="F<%= row_number %>" s="43"><v>0</v></c>|
      <> ~s|<c r="G<%= row_number %>" s="43"/>|
    end

    def render_date_rows(template, times) do
      # relevant rows are [9, 24]
      times
      |> Enum.with_index() # list
      |> Enum.map( &date_row_bindings/1 )
      |> add_null_rows_if_needed()
      # |> Enum.reverse()
      |> Enum.map( &EEx.eval_string(template, &1) )
      |> Enum.join()
    end

    defp add_null_rows_if_needed(l, acc \\ [])
    defp add_null_rows_if_needed(l, _)   when length(l)   == 16 do
      l
    end
    defp add_null_rows_if_needed(_, acc) when length(acc) == 16 do
      acc |> Enum.reverse()
    end
    defp add_null_rows_if_needed([h|t], acc) do
      add_null_rows_if_needed(t, [h|acc])
    end
    defp add_null_rows_if_needed([],    acc) do
      bindings = null_date_row_bindings( [row_number:  length(acc)+9] )

      add_null_rows_if_needed([], [bindings|acc])
    end

    defp null_date_row_bindings(bindings_to_add) do
      date_row_template()
      |> get_default_bindings("")
      |> Keyword.merge(bindings_to_add)
    end

    def to_cell_time({h,m}) do
      new_h =
        case h > 12 do
          true  -> h-12
          false -> h
        end

      (new_h + m/60)/24
    end

    def date_row_bindings({{excel_date, times}, index}) do
      base_bindings = [row_number: index+9, date: excel_date]

      non_others =
        Excel.Parse.extract_and_map_non_others(
          times,
          &to_cell_time/1
        )
        |> Map.to_list()
        |> Enum.concat([{:daily_sum, Excel.Parse.to_minutes(times.daily_sum)/60}])

      bindings_to_add =
        case times.others do
          :none ->
            base_bindings
            ++ non_others

          # Not checking for other (i.e., time-off requests etc) to zero out
          # non_others. That should be the job of the client-side code or
          # the employee (e.g., some people only work 4 hours so it's hard to
          # make correct assumptions).
          other ->
            base_bindings
            ++ [{other, times.others_time}]
            ++ non_others
        end

      null_date_row_bindings(bindings_to_add)
    end
  end

  defmodule Maker do
    require Excel.Date

    defmacro make_converts(start_date, end_date) do
      quote do
        dates = Excel.Date.range(unquote(start_date), unquote(end_date))

        for {excel, map, mdy} <- dates do
          Excel.Date.make_convert(excel, Macro.escape(map), mdy)
        end
      end
    end
  end
end

# alias Excel.Template, as: T; x = T.render params; :zip.zip("a.xlsx",x)
