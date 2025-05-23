%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 1998-2025. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%

-module(epp_SUITE).
-export([all/0, suite/0,groups/0,init_per_suite/1, end_per_suite/1,
	 init_per_group/2,end_per_group/2]).

-export([rec_1/1, include_local/1, predef_mac/1,
	 upcase_mac_1/1, upcase_mac_2/1,
	 variable_1/1, otp_4870/1, otp_4871/1, otp_5362/1,
         pmod/1, not_circular/1, skip_header/1, otp_6277/1, gh_4995/1, otp_7702/1,
         otp_8130/1, overload_mac/1, otp_8388/1, otp_8470/1,
         otp_8562/1, otp_8665/1, otp_8911/1, otp_10302/1, otp_10820/1,
         otp_11728/1, encoding/1, extends/1,  function_macro/1,
	 test_error/1, test_warning/1, otp_14285/1,
	 test_if/1,source_name/1,otp_16978/1,otp_16824/1,scan_file/1,file_macro/1,
         deterministic_include/1, nondeterministic_include/1,
         gh_8268/1,
         moduledoc_include/1,
         stringify/1
        ]).

-export([epp_parse_erl_form/2]).

%%
%% Define to run outside of test server
%%
%%-define(STANDALONE,1).

-ifdef(STANDALONE).
-compile(export_all).
-define(line, put(line, ?LINE), ).
-define(config(A,B),config(A,B)).
%% -define(t, test_server).
-define(t, io).
config(priv_dir, _) ->
    filename:absname("./epp_SUITE_priv");
config(data_dir, _) ->
    filename:absname("./epp_SUITE_data").
-else.
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-export([init_per_testcase/2, end_per_testcase/2]).

init_per_testcase(_, Config) ->
    Config.

end_per_testcase(_, _Config) ->
    ok.
-endif.

suite() ->
    [{ct_hooks,[ts_install_cth]},
     {timetrap,{minutes,1}}].

all() ->
    [rec_1, {group, upcase_mac}, include_local, predef_mac,
     {group, variable}, otp_4870, otp_4871, otp_5362, pmod,
     not_circular, skip_header, otp_6277, gh_4995, otp_7702, otp_8130,
     overload_mac, otp_8388, otp_8470, otp_8562,
     otp_8665, otp_8911, otp_10302, otp_10820, otp_11728,
     encoding, extends, function_macro, test_error, test_warning,
     otp_14285, test_if, source_name, otp_16978, otp_16824, scan_file, file_macro,
     deterministic_include, nondeterministic_include,
     gh_8268,
     moduledoc_include,
     stringify].

groups() ->
    [{upcase_mac, [], [upcase_mac_1, upcase_mac_2]},
     {variable, [], [variable_1]}].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.

%% Recursive macros hang or crash epp (OTP-1398).
rec_1(Config) when is_list(Config) ->
    File = filename:join(proplists:get_value(data_dir, Config), "mac.erl"),
    {ok, List} = epp_parse_file(File, [], []),
    %% we should encounter errors
    {value, _} = lists:keysearch(error, 1, List),
    check_errors(List),
    ok.

include_local(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "include_local.erl"),
    FooHrl = filename:join([DataDir,"include","foo.hrl"]),
    BarHrl = filename:join([DataDir,"include","bar.hrl"]),
    %% include_local.erl includes include/foo.hrl which
    %% includes bar.hrl (also in include/) without requiring
    %% any additional include path, and overriding any file
    %% of the same name that the path points to
    {ok, List} = epp:parse_file(File, [DataDir], []),
    {value, {attribute,_,a,{true,true}}} =
	lists:keysearch(a,3,List),
    [{File,1},{FooHrl,1},{BarHrl,1},{FooHrl,5},{File,5}] =
        [ FileLine || {attribute,_,file,FileLine} <- List ],
    ok.

file_macro(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "file_macro.erl"),
    {ok, List} = epp:parse_file(File, [{includes, [DataDir]},
                                       {source_name, "Other source"}]),
    %% Both attribute a and b are defined as ?FILE, they should be the same
    {attribute,_,a,FileA} = lists:keyfind(a, 3, List),
    {attribute,_,b,FileB} = lists:keyfind(b, 3, List),
    "Other source" = FileA = FileB,
    ok.

moduledoc_include(Config) when is_list(Config) ->
    PrivDir = proplists:get_value(priv_dir, Config),
    ModuleFileContent = <<"-module(moduledoc).

                           -moduledoc {file, \"README.md\"}.

                           -export([]).
                          ">>,
    DocFileContent = <<"# README

                        This file is a test
                       ">>,
    CreateFile = fun (Dir, File, Content) ->
                     Dirname = filename:join([PrivDir, Dir]),
                     ok = create_dir(Dirname),
                     Filename = filename:join([Dirname, File]),
                     ok = file:write_file(Filename, Content),
                     Filename
                 end,

    %% positive test: checks that all works as expected
    ModuleName = CreateFile("module_attr", "moduledoc.erl", ModuleFileContent),
    DocName = CreateFile("module_attr", "README.md", DocFileContent),
    {ok, List} = epp:parse_file(ModuleName, []),
    {attribute, _, moduledoc, ModuleDoc} = lists:keyfind(moduledoc, 3, List),
    ?assertEqual({ok, unicode:characters_to_binary(ModuleDoc)}, file:read_file(DocName)),

    %% negative test: checks that we produce an expected warning
    ModuleWarnContent = binary:replace(ModuleFileContent, <<"README">>, <<"NotExistingFile">>),
    ModuleWarnName = CreateFile("module_attr", "moduledoc_err.erl", ModuleWarnContent),
    {ok, ListWarn} = epp:parse_file(ModuleWarnName, []),
    {warning,{_,epp,{moduledoc,file, "NotExistingFile.md"}}} = lists:keyfind(warning, 1, ListWarn),

    ok.

create_dir(Dir) ->
    case file:make_dir(Dir) of
        ok -> ok;
        {error, eexist} -> ok;
        _ -> error
    end.

deterministic_include(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "deterministic_include.erl"),
    {ok, List} = epp:parse_file(File, [{includes, [DataDir]},
                                       {deterministic, true},
                                       {source_name, "deterministic_include.erl"}]),

    %% In deterministic mode, only basenames, rather than full paths, should
    %% be written to the -file() attributes resulting from -include and -include_lib
    ?assert(lists:any(fun
                       ({attribute,_Anno,file,{"baz.hrl",_Line}}) -> true;
                       (_) -> false
                     end,
                     List),
            "Expected a basename in the -file attribute resulting from " ++
            "including baz.hrl in deterministic mode."),
    ?assert(lists:any(fun
                       ({attribute,_Anno,file,{"file.hrl",_Line}}) -> true;
                       (_) -> false
                     end,
                     List),
            "Expected a basename in the -file attribute resulting from " ++
            "including file.hrl in deterministic mode."),
    ok.

nondeterministic_include(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "deterministic_include.erl"),
    {ok, List} = epp:parse_file(File, [{includes, [DataDir]},
                                       {source_name, "deterministic_include.erl"}]),

    %% Outside of deterministic mode, full paths, should be written to
    %% the -file() attributes resulting from -include and -include_lib
    %% to make debugging easier.
    %% We don't try to assume what the full absolute path will be in the
    %% unit test, since that can depend on the environment and how the
    %% test is executed. Instead, we just look for whether there is
    %% the parent directory along with the basename at least.
    IncludeAbsolutePathSuffix = filename:join("include","baz.hrl"),
    ?assert(lists:any(fun
                       ({attribute,_Anno,file,{IncludePath,_Line}}) ->
                         lists:suffix(IncludeAbsolutePathSuffix,IncludePath);
                       (_) -> false
                     end,
                     List),
            "Expected an absolute in the -file attribute resulting from " ++
            "including baz.hrl outside of deterministic mode."),
    IncludeLibAbsolutePathSuffix = filename:join("include","file.hrl"),
    ?assert(lists:any(fun
                       ({attribute,_Anno,file,{IncludePath,_line}}) ->
                         lists:suffix(IncludeLibAbsolutePathSuffix,IncludePath);
                       (_) -> false
                     end,
                     List),
            "Expected an absolute in the -file attribute resulting from " ++
            "including file.hrl outside of deterministic mode."),
    ok.

%%% Here is a little reimplementation of epp:parse_file, which times out
%%% after 4 seconds if the epp server doesn't respond. If we use the
%%% regular epp:parse_file, the test case will time out, and then epp
%%% server will go on growing until we dump core.
epp_parse_file(File, Inc, Predef) ->
    List = do_epp_parse_file(fun() ->
				     epp:open(File, Inc, Predef)
			     end),
    List = do_epp_parse_file(fun() ->
				     Opts = [{name, File},
					     {includes, Inc},
					     {macros, Predef}],
				     epp:open(Opts)
			     end),
    {ok, List}.

do_epp_parse_file(Open) ->
    {ok, Epp} = Open(),
    List = collect_epp_forms(Epp),
    epp:close(Epp),
    List.

collect_epp_forms(Epp) ->
    Result = epp_parse_erl_form(Epp),
    case Result of
	{error, _Error} ->
	    [Result | collect_epp_forms(Epp)];
	{ok, Form} ->
	    [Form | collect_epp_forms(Epp)];
	{eof, _} ->
	    [Result]
    end.

epp_parse_erl_form(Epp) ->
    P = spawn(?MODULE, epp_parse_erl_form, [Epp, self()]),
    receive
	{P, Result} ->
	    Result
    after 4000 ->
	    exit(Epp, kill),
	    exit(P, kill),
	    timeout
    end.

epp_parse_erl_form(Epp, Parent) ->
    Parent ! {self(), epp:parse_erl_form(Epp)}.

check_errors([]) ->
    ok;
check_errors([{error, Info} | Rest]) ->
    {Line, Mod, Desc} = Info,
    case Line of
	I when is_integer(I) -> ok;
	{L,C} when is_integer(L), is_integer(C), C >= 1 -> ok
    end,
    Str = lists:flatten(Mod:format_error(Desc)),
    [Str] = io_lib:format("~s", [Str]),
    check_errors(Rest);
check_errors([_ | Rest]) ->
    check_errors(Rest).


upcase_mac_1(Config) when is_list(Config) ->
    File = filename:join(proplists:get_value(data_dir, Config), "mac2.erl"),
    {ok, List} = epp:parse_file(File, [], []),
    [_, {attribute, _, plupp, Tuple} | _] = List,
    Tuple = {1, 1, 3, 3},
    ok.

upcase_mac_2(Config) when is_list(Config) ->
    File = filename:join(proplists:get_value(data_dir, Config), "mac2.erl"),
    {ok, List} = epp:parse_file(File, [], [{p, 5}, {'P', 6}]),
    [_, {attribute, _, plupp, Tuple} | _] = List,
    Tuple = {5, 5, 6, 6},
    ok.

predef_mac(Config) when is_list(Config) ->
    File = filename:join(proplists:get_value(data_dir, Config), "mac3.erl"),
    {ok, List} = epp:parse_file(File, [], []),
    [_,
     {attribute, Anno, l, Line1},
     {attribute, _, f, File},
     {attribute, _, machine1, _},
     {attribute, _, module, mac3},
     {attribute, _, m, mac3},
     {attribute, _, ms, "mac3"},
     {attribute, _, machine2, _}
     | _] = List,
    Line1 = erl_anno:line(Anno),
    ok.

variable_1(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "variable_1.erl"),
    true = os:putenv("VAR", DataDir),
    %% variable_1.erl includes variable_1_include.hrl and
    %% variable_1_include_dir.hrl.
    {ok, List} = epp:parse_file(File, [], []),
    {value, {attribute,_,a,{value1,value2}}} =
	lists:keysearch(a,3,List),
    ok.

%% undef without module declaration.
otp_4870(Config) when is_list(Config) ->
    Ts = [{otp_4870,
           <<"-undef(foo).
           ">>,
           []}],
    [] = check(Config, Ts),
    ok.

%% crashing erl_scan
otp_4871(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, "otp_4871.erl"),
    ok = file:write_file(File, "-module(otp_4871)."),
    %% Testing crash in erl_scan. Unfortunately there currently is
    %% no known way to crash erl_scan so it is emulated by killing the
    %% file io server. This assumes lots of things about how
    %% the processes are started and how monitors are set up,
    %% so there are some sanity checks before killing.
    {ok,Epp} = epp:open(File, []),
    timer:sleep(1),
    true = current_module(Epp, epp),
    {monitored_by,[Io]} = process_info(Epp, monitored_by),
    true = current_module(Io, file_io_server),
    exit(Io, emulate_crash),
    timer:sleep(1),
    {error,{_Line,epp,cannot_parse}} = otp_4871_parse_file(Epp),
    epp:close(Epp),
    ok.

current_module(Pid, Mod) ->
    {current_function, {Mod, _, _}} = process_info(Pid, current_function),
    true.

otp_4871_parse_file(Epp) ->
    case epp:parse_erl_form(Epp) of
	{ok,_} -> otp_4871_parse_file(Epp);
	Other -> Other
    end.

%% OTP-5362. The -file attribute is recognized.
otp_5362(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),

    Copts = [return, strong_validation,{i,Dir}],

    File_Incl = filename:join(Dir, "incl_5362.erl"),
    File_Incl2 = filename:join(Dir, "incl2_5362.erl"),
    File_Incl3 = filename:join(Dir, "incl3_5362.erl"),
    Incl = <<"-module(incl_5362).

              -include(\"incl2_5362.erl\").

              -include_lib(\"incl3_5362.erl\").

              hi(There) -> % line 7
                   a.
           ">>,
    Incl2 = <<"-file(\"some.file\", 100).

               foo(Bar) -> % line 102
                   foo.
            ">>,
    Incl3 = <<"glurk(Foo) -> % line 1
                  bar.
            ">>,
    ok = file:write_file(File_Incl, Incl),
    ok = file:write_file(File_Incl2, Incl2),
    ok = file:write_file(File_Incl3, Incl3),

    {ok, incl_5362, InclWarnings} = compile:file(File_Incl, Copts),
    true = message_compare(
                   [{File_Incl3,[{{1,1},erl_lint,{unused_function,{glurk,1}}},
                                 {{1,7},erl_lint,{unused_var,'Foo'}}]},
                    {File_Incl,[{{7,15},erl_lint,{unused_function,{hi,1}}},
                                {{7,18},erl_lint,{unused_var,'There'}}]},
                    {"some.file",[{{102,16},erl_lint,{unused_function,{foo,1}}},
                                  {{102,20},erl_lint,{unused_var,'Bar'}}]}],
                   lists:usort(InclWarnings)),

    file:delete(File_Incl),
    file:delete(File_Incl2),
    file:delete(File_Incl3),

    %% A -file attribute referring back to the including file.
    File_Back = filename:join(Dir, "back_5362.erl"),
    File_Back_hrl = filename:join(Dir, "back_5362.hrl"),
    Back = <<"-module(back_5362).

              -export([foo/1]).

              -file(?FILE, 1).
              -include(\"back_5362.hrl\").

              foo(V) -> % line 4
                  bar.
              ">>,
    Back_hrl = [<<"
                  -file(\"">>,File_Back,<<"\", 2).
                 ">>],

    ok = file:write_file(File_Back, Back),
    ok = file:write_file(File_Back_hrl, list_to_binary(Back_hrl)),

    {ok, back_5362, BackWarnings} = compile:file(File_Back, Copts),
    true = message_compare(
                   [{File_Back,[{{4,19},erl_lint,{unused_var,'V'}}]}],
                   BackWarnings),
    file:delete(File_Back),
    file:delete(File_Back_hrl),

    %% Set filename but keep line.
    File_Change = filename:join(Dir, "change_5362.erl"),
    Change = [<<"-module(change_5362).

                -file(?FILE, 100).

                -export([foo/1,bar/1]).

                -file(\"other.file\", ?LINE). % like an included file...
                foo(A) -> % line 105
                    bar.

                -file(\"">>,File_Change,<<"\", 1000).

                bar(B) -> % line 1002
                    foo.
              ">>],

    ok = file:write_file(File_Change, list_to_binary(Change)),

    {ok, change_5362, ChangeWarnings} =
        compile:file(File_Change, Copts),
    true = message_compare(
                   [{File_Change,[{{1002,21},erl_lint,{unused_var,'B'}}]},
                    {"other.file",[{{105,21},erl_lint,{unused_var,'A'}}]}],
                   lists:usort(ChangeWarnings)),

    file:delete(File_Change),

    %% -file attribute ending with a blank (not a newline).
    File_Blank = filename:join(Dir, "blank_5362.erl"),

    Blank = <<"-module(blank_5362).

               -export([q/1,a/1,b/1,c/1]).

               -
               file(?FILE, 18). q(Q) -> foo. % line 18

               a(A) -> % line 20
                   1.

               -file(?FILE, 42).

               b(B) -> % line 44
                   2.

               -file(?FILE, ?LINE). c(C) -> % line 47
                   3.
            ">>,
    ok = file:write_file(File_Blank, Blank),
    {ok, blank_5362, BlankWarnings} = compile:file(File_Blank, Copts),
    true = message_compare(
             [{File_Blank,[{{18,3},erl_lint,{unused_var,'Q'}},
                           {{20,18},erl_lint,{unused_var,'A'}},
                           {{44,18},erl_lint,{unused_var,'B'}},
                           {{47,3},erl_lint,{unused_var,'C'}}]}],
              lists:usort(BlankWarnings)),
    file:delete(File_Blank),

    %% __FILE__ is set by inclusion and by -file attribute
    FILE_incl = filename:join(Dir, "file_5362.erl"),
    FILE_incl1 = filename:join(Dir, "file_incl_5362.erl"),
    FILE = <<"-module(file_5362).

              -export([ff/0, ii/0]).

              -include(\"file_incl_5362.erl\").

              -file(\"other_file\", 100).

              ff() ->
                  ?FILE.">>,
    FILE1 = <<"ii() -> ?FILE.
              ">>,
    FILE_Mod = file_5362,
    ok = file:write_file(FILE_incl, FILE),
    ok = file:write_file(FILE_incl1, FILE1),
    FILE_Copts = [return, {i,Dir},{outdir,Dir}],
    {ok, file_5362, []} = compile:file(FILE_incl, FILE_Copts),
    AbsFile = filename:rootname(FILE_incl, ".erl"),
    {module, FILE_Mod} = code:load_abs(AbsFile, FILE_Mod),
    II = FILE_Mod:ii(),
    "file_incl_5362.erl" = filename:basename(II),
    FF = FILE_Mod:ff(),
    "other_file" = filename:basename(FF),
    code:purge(file_5362),

    file:delete(FILE_incl),
    file:delete(FILE_incl1),

    ok.

pmod(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    Pmod = filename:join(DataDir, "pmod.erl"),
    case epp:parse_file([Pmod], [], []) of
	      {ok,Forms} ->
		  %% io:format("~p\n", [Forms]),
		  [] = [F || {error,_}=F <- Forms],
		  ok
	  end,
    ok.

not_circular(Config) when is_list(Config) ->
    %% Used to generate a compilation error, wrongly saying that it
    %% was a circular definition.

    Ts = [{circular_1,
           <<"-define(S(S), ??S).\n"
             "t() -> \"string\" = ?S(string), ok.\n">>,
           ok}],
    [] = run(Config, Ts),
    ok.

%% Skip some bytes in the beginning of the file.
skip_header(Config) when is_list(Config) ->
    PrivDir = proplists:get_value(priv_dir, Config),
    File = filename:join([PrivDir, "epp_test_skip_header.erl"]),
    ok = file:write_file(File,
			       <<"some bytes
                                  in the beginning of the file
                                  that should be skipped
                                  -module(epp_test_skip_header).
                                  -export([main/1]).

                                  main(_) -> ?MODULE.

                                  ">>),
    {ok, Fd} = file:open(File, [read]),
    io:get_line(Fd, ''),
    io:get_line(Fd, ''),
    io:get_line(Fd, ''),
    {ok, Epp} = epp:open([{fd, Fd}, {name, list_to_atom(File)}, {location, 4}]),

    Forms = epp:parse_file(Epp),
    [] = [Reason || {error, Reason} <- Forms],
    ok = epp:close(Epp),
    ok = file:close(Fd),

    ok.

%% ?MODULE before module declaration.
otp_6277(Config) when is_list(Config) ->
    Ts = [{otp_6277,
           <<"-undef(ASSERT).
              -define(ASSERT, ?MODULE).

              ?ASSERT().">>,
           [{error,{4,epp,{undefined,'MODULE', none}}}]}],
    [] = check(Config, Ts),
    ok.

%% Test -ifdef(MODULE) before module declaration. Should not be
%% considered defined.
gh_4995(Config) when is_list(Config) ->
    Ts = [{gh_4995,
           <<"-ifdef(MODULE).
              -record(r, {x = ?MODULE}).
              -endif.">>,
           []}],
    [] = check(Config, Ts),
    ok.

%% OTP-7702. Wrong line number in stringifying macro expansion.
otp_7702(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, "file_7702.erl"),
    Contents = <<"-module(file_7702).

                  -export([t/0]).

                  -define(RECEIVE(Msg,Body),
                       receive
                           Msg -> Body;
                           M ->
                exit({unexpected_message,M,on_line,?LINE,was_expecting,??Msg})
                       after 10000 ->
                            exit({timeout,on_line,?LINE,was_expecting,??Msg})
                       end).
                   t() ->
                       ?RECEIVE(foo, bar).">>,
    ok = file:write_file(File, Contents),
    {ok, file_7702, []} =
        compile:file(File, [debug_info,return,{outdir,Dir}]),

    BeamFile = filename:join(Dir, "file_7702.beam"),
    {ok, AC} = beam_lib:chunks(BeamFile, [abstract_code]),

    {file_7702,[{abstract_code,{_,Forms}}]} = AC,
    Forms2 = unopaque_forms(Forms),
        [{attribute,{1,1},file,_},
         _,
         _,
         {function,_,t,0,
          [{clause,_,[],[],
            [{'receive',{14,25},
              [_,
               {clause,{14,38},
                [{var,{14,38},'M'}],
                [],
                [{_,_,_,
                  [{tuple,{14,38},
                    [{atom,{14,38},unexpected_message},
                     {var,{14,38},'M'},
                     {atom,{14,38},on_line},
                     {integer,{14,38},14},
                     {atom,{14,38},was_expecting},
                     {string,{14,38},"foo"}]}]}]}],
              {integer,{14,38},10000},
              [{call,{14,38},
                {atom,{14,38},exit},
                [{tuple,{14,38},
                  [{atom,{14,38},timeout},
                   {atom,{14,38},on_line},
                   {integer,{14,38},14},
                   {atom,{14,38},was_expecting},
                   {string,{14,38},"foo"}]}]}]}]}]},
         {eof,{14,43}}] = Forms2,

    file:delete(File),
    file:delete(BeamFile),

    ok.

%% OTP-8130. Misc tests.
otp_8130(Config) when is_list(Config) ->
    true = os:putenv("epp_inc1", "stdlib"),
    Ts = [{otp_8130_1,
           <<"-define(M(A), ??A). "
             "t() ->  "
             "   L = \"{ 34 , \\\"1\\\\x{AAA}\\\" , \\\"34\\\" , X . a , $\\\\x{AAA} }\", "
             "   R = ?M({34,\"1\\x{aaa}\",\"34\",X.a,$\\x{aaa}}),"
             "   Lt = erl_scan:string(L, 1),"
             "   Rt = erl_scan:string(R, 1),"
             "   Lt = Rt, ok. ">>,
          ok},

          {otp_8130_2,
           <<"-define(M(A), ??B). "
             "t() -> B = 18, 18 = ?M(34), ok. ">>,
           ok},

          {otp_8130_2a,
           <<"-define(m(A), ??B). "
             "t() -> B = 18, 18 = ?m(34), ok. ">>,
           ok},

          {otp_8130_3,
           <<"-define(M1(A, B), {A,B}).\n"
             "t0() -> 1.\n"
             "t() ->\n"
             "   {2,7} =\n"
             "      ?M1(begin 1 = fun() -> 1 end(),\n" % Bug -R13B01
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin 1 = fun _Name () -> 1 end(),\n"
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin 1 = fun t0/0(),\n"
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin 2 = byte_size(<<\"34\">>),\n"
             "                2 end,\n"
             "          7),\n"
             "   R2 = math:sqrt(2.0),\n"
             "   {2,7} =\n"
             "      ?M1(begin yes = if R2 > 1 -> yes end,\n"
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin yes = case R2 > 1  of true -> yes end,\n"
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin yes = receive 1 -> 2 after 0 -> yes end,\n"
             "                2 end,\n"
             "          7),\n"
             "   {2,7} =\n"
             "      ?M1(begin yes = try 1 of 1 -> yes after foo end,\n"
             "                2 end,\n"
             "          7),\n"
             "   {[42],7} =\n"
             "      ?M1([42],\n"
             "          7),\n"
             "ok.\n">>,
           ok},

          {otp_8130_4,
           <<"-define(M3(), A).\n"
             "t() -> A = 1, ?M3(), ok.\n">>,
           ok},

          {otp_8130_5,
           <<"-include_lib(\"$epp_inc1/include/qlc.hrl\").\n"
             "t() -> [1] = qlc:e(qlc:q([X || X <- [1]])), ok.\n">>,
           ok},

          {otp_8130_6,
           <<"-include_lib(\"kernel/include/file.hrl\").\n"
             "t() -> 14 = (#file_info{size = 14})#file_info.size, ok.\n">>,
           ok},

          {otp_8130_7_new,
           <<"-record(b, {b}).\n"
             "-define(A, {{a,#b.b).\n"
             "t() -> {{a,2}} = ?A}}, ok.">>,
           ok},

          {otp_8130_8,
           <<"\n-define(A(B), B).\n"
             "-undef(A).\n"
             "-define(A, ok).\n"
             "t() -> ?A.\n">>,
           ok},
          {otp_8130_9,
           <<"-define(a, 1).\n"
             "-define(b, {?a,?a}).\n"
             "t() -> ?b.\n">>,
           {1,1}}

         ],
    [] = run(Config, Ts),

    Cs = [{otp_8130_c1,
           <<"-define(M1(A), if\n"
             "A =:= 1 -> B;\n"
             "true -> 2\n"
             "end).\n"
            "t() -> {?M1(1), ?M1(2)}. \n">>,
           {errors,[{{5,13},erl_lint,{unbound_var,'B'}},
                    {{5,21},erl_lint,{unbound_var,'B'}}],
            []}},

          {otp_8130_c2,
           <<"-define(M(A), A).\n"
             "t() -> ?M(1\n">>,
           {errors,[{{2,9},epp,{arg_error,'M'}}],[]}},

          {otp_8130_c3,
           <<"-define(M(A), A).\n"
             "t() -> ?M.\n">>,
           {errors,[{{2,9},epp,{mismatch,'M'}}],[]}},

          {otp_8130_c4,
           <<"-define(M(A), A).\n"
             "t() -> ?M(1, 2).\n">>,
           {errors,[{{2,9},epp,{mismatch,'M'}}],[]}},

          {otp_8130_c5,
           <<"-define(M(A), A).\n"
             "t() -> ?M().\n">>,
           {errors,[{{2,9},epp,{mismatch,'M'}}],[]}},

          {otp_8130_c6,
           <<"-define(M3(), A).\n"
             "t() -> A = 1, ?3.14159}.\n">>,
           {errors,[{{2,16},epp,{call,[$?,"3.14159"]}}],[]}},

          {otp_8130_c7,
           <<"\nt() -> ?A.\n">>,
           {errors,[{{2,9},epp,{undefined,'A', none}}],[]}},

          {otp_8130_c8,
           <<"\n-include_lib(\"$apa/foo.hrl\").\n">>,
           {errors,[{{2,14},epp,{include,lib,"$apa/foo.hrl"}}],[]}},


          {otp_8130_c9a,
           <<"-define(S, ?S).\n"
             "t() -> ?S.\n">>,
           {errors,[{{2,9},epp,{circular,'S', none}}],[]}},

          {otp_8130_c9b,
           <<"-define(S(), ?S()).\n"
             "t() -> ?S().\n">>,
           {errors,[{{2,9},epp,{circular,'S', 0}}],[]}},

          {otp_8130_c10,
           <<"\n-file.">>,
           {errors,[{{2,6},epp,{bad,file}}],[]}},

          {otp_8130_c11,
           <<"\n-include_lib 92.">>,
           {errors,[{{2,14},epp,{bad,include_lib}}],[]}},

          {otp_8130_c12,
           <<"\n-include_lib(\"kernel/include/fopp.hrl\").\n">>,
           {errors,[{{2,14},epp,{include,lib,"kernel/include/fopp.hrl"}}],[]}},

          {otp_8130_c13,
           <<"\n-include(foo).\n">>,
           {errors,[{{2,10},epp,{bad,include}}],[]}},

          {otp_8130_c14,
           <<"\n-undef({foo}).\n">>,
           {errors,[{{2,8},epp,{bad,undef}}],[]}},

          {otp_8130_c15,
           <<"\n-define(a, 1).\n"
            "-define(a, 1).\n">>,
           {errors,[{{3,9},epp,{redefine,a}}],[]}},

          {otp_8130_c16,
           <<"\n-define(A, 1).\n"
            "-define(A, 1).\n">>,
           {errors,[{{3,9},epp,{redefine,'A'}}],[]}},

          {otp_8130_c17,
           <<"\n-define(A(B), B).\n"
            "-define(A, 1).\n">>,
           []},

          {otp_8130_c18,
           <<"\n-define(A, 1).\n"
            "-define(A(B), B).\n">>,
           []},

          {otp_8130_c19,
           <<"\n-define(a(B), B).\n"
            "-define(a, 1).\n">>,
           []},

          {otp_8130_c20,
           <<"\n-define(a, 1).\n"
            "-define(a(B), B).\n">>,
           []},

          {otp_8130_c21,
           <<"\n-define(A(B, B), B).\n">>,
           {errors,[{{2,14},epp,{duplicated_argument,'B'}}],[]}},

          {otp_8130_c22,
           <<"\n-define(a(B, B), B).\n">>,
           {errors,[{{2,14},epp,{duplicated_argument,'B'}}],[]}},

          {otp_8130_c23,
           <<"\n-file(?b, 3).\n">>,
           {errors,[{{2,8},epp,{undefined,b, none}}],[]}},

          {otp_8130_c24,
           <<"\n-include(\"no such file.erl\").\n">>,
           {errors,[{{2,10},epp,{include,file,"no such file.erl"}}],[]}},

          {otp_8130_c25,
           <<"\n-define(A.\n">>,
           {errors,[{{2,10},epp,{bad,define}}],[]}},

          {otp_8130_7,
           <<"-record(b, {b}).\n"
             "-define(A, {{a,#b.b.\n"
             "t() -> {{a,2}} = ?A}}, ok.">>,
           {errors,[{{2,20},epp,missing_parenthesis},
                    {{3,19},epp,{undefined,'A',none}}],[]}}

          ],
    [] = compile(Config, Cs),

    Cks = [{otp_check_1,
            <<"\n-include_lib(\"epp_test.erl\").\n">>,
            [{error,{2,epp,{depth,"include_lib"}}}]},

           {otp_check_2,
            <<"\n-include(\"epp_test.erl\").\n">>,
            [{error,{2,epp,{depth,"include"}}}]}
           ],
    [] = check(Config, Cks),

    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, "otp_8130.erl"),
    ok = file:write_file(File,
                               "-module(otp_8130).\n"
                               "-define(a, 3.14).\n"
                               "t() -> ?a.\n"),
    {ok,Epp} = epp:open(File, []),
    PreDefMacs = macs(Epp),
    ['BASE_MODULE','BASE_MODULE_STRING','BEAM',
     'FEATURE_AVAILABLE', 'FEATURE_ENABLED','FILE',
     'FUNCTION_ARITY','FUNCTION_NAME',
     'LINE','MACHINE','MODULE','MODULE_STRING',
     'OTP_RELEASE'] = PreDefMacs,
    {ok,[{'-',_},{atom,_,file}|_]} = epp:scan_erl_form(Epp),
    {ok,[{'-',_},{atom,_,module}|_]} = epp:scan_erl_form(Epp),
    {ok,[{atom,_,t}|_]} = epp:scan_erl_form(Epp),
    {eof,_} = epp:scan_erl_form(Epp),
    [a] = macs(Epp) -- PreDefMacs,
    epp:close(Epp),

    %% escript
    ModuleStr = "any_name",
    Module = list_to_atom(ModuleStr),
    fun() ->
            PreDefMacros = [{'MODULE', Module, redefine},
                            {'MODULE_STRING', ModuleStr, redefine},
                            a, {b,2}],
            {ok,Epp2} = epp:open(File, [], PreDefMacros),
            [{atom,_,true}] = macro(Epp2, a),
            [{integer,_,2}] = macro(Epp2, b),
            false = macro(Epp2, c),
            epp:close(Epp2)
    end(),
    fun() ->
            PreDefMacros = [{a,b,c}],
            {error,{bad,{a,b,c}}} = epp:open(File, [], PreDefMacros)
    end(),
    fun() ->
            PreDefMacros = [a, {a,1}],
            {error,{redefine,a}} = epp:open(File, [], PreDefMacros)
    end(),
    fun() ->
            PreDefMacros = [{a,1},a],
            {error,{redefine,a}} = epp:open(File, [], PreDefMacros)
    end(),

    {error,enoent} = epp:open("no such file", []),
    {error,enoent} = epp:parse_file("no such file", [], []),

    _ = ifdef(Config),

    ok.

scan_file(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "source_name.erl"),

    {ok, Toks, [{encoding, _}]} = epp:scan_file(File, []),
    [FileForm1, ModuleForm, ExportForm,
     FileForm2, FileForm3, FunctionForm,
     {eof,_}] = Toks,
    [{'-',_}, {atom,_,file}, {'(',_} | _ ]   = FileForm1,
    [{'-',_}, {atom,_,module}, {'(',_} | _ ] = ModuleForm,
    [{'-',_}, {atom,_,export}, {'(',_} | _ ] = ExportForm,
    [{'-',_}, {atom,_,file}, {'(',_} | _ ]   = FileForm2,
    [{'-',_}, {atom,_,file}, {'(',_} | _ ]   = FileForm3,
    [{atom,_,ok}, {'(',_} | _]               = FunctionForm,
    ok.

macs(Epp) ->
    Macros = epp:macro_defs(Epp), % not documented
    lists:sort([MName || {{atom,MName},_} <- Macros]).

macro(Epp, N) ->
    case lists:keyfind({atom,N}, 1, epp:macro_defs(Epp)) of
        false -> false;
        {{atom,N},{_,V}} -> V;
        {{atom,N},Defs} -> lists:append([V || {_,{_,V}} <- Defs])
    end.

ifdef(Config) ->
    Cs = [{ifdef_c1,
           <<"-ifdef(a).\n"
             "a bug.\n"
             "-else.\n"
             "-ifdef(A).\n"
             "a bug.\n"
             "-endif.\n"
             "-else.\n"
             "t() -> ok.\n"
             "-endif.">>,
           {errors,[{{7,2},epp,{illegal,"repeated",'else'}}],[]}},

          {ifdef_c2,
           <<"-define(a, true).\n"
             "-ifdef(a).\n"
             "a bug.\n"
             "-endif.">>,
           {errors,[{{3,3},erl_parse,["syntax error before: ","bug"]}],[]}},

          {ifdef_c3,
           <<"-define(a, true).\n"
             "-ifdef(a).\n"
             "-endif">>,

           {errors,[{{3,2},epp,{bad,endif}},
                    {{3,7},epp,{illegal,"unterminated",ifdef}}],
          []}},

          {ifdef_c4,
           <<"\n-ifdef a.\n"
             "-endif.\n">>,
           {errors,[{{2,8},epp,{bad,ifdef}}],[]}},

          {ifdef_c5,
           <<"-ifdef(a).\n"
             "-else.\n"
             "-endif.\n"
             "-endif.\n">>,
           {errors,[{{4,2},epp,{illegal,"unbalanced",endif}}],[]}},

          {ifdef_c6,
           <<"-ifdef(a).\n"
             "-else.\n"
             "-endif.\n"
             "-else.\n">>,
           {errors,[{{4,2},epp,{illegal,"unbalanced",'else'}}],[]}},

          {ifdef_c7,
           <<"-ifndef(a).\n"
             "-else\n"
             "foo bar\n"
             "-else.\n"
             "t() -> a.\n"
             "-endif.\n">>,
           {errors,[{{3,1},epp,{bad,'else'}}],[]}},

          {ifdef_c8,
           <<"-ifdef(a).\n"
              "-foo bar.">>,
           {errors,[{{2,10},epp,{illegal,"unterminated",ifdef}}],[]}},

          {ifdef_c9,
           <<"-ifdef(a).\n"
              "3.3e12000.\n"
              "-endif.\n">>,
           []},

          {ifdef_c10,
           <<"\nt() -> 3.3e12000.\n">>,
           {errors,[{{2,8},erl_scan,{illegal,float}},
                    {{2,17},erl_parse,["syntax error before: ","'.'"]}], % ...
            []}},

          {ifndef_c1,
           <<"-ifndef(a).\n"
             "-ifndef(A).\n"
             "t() -> ok.\n"
             "-endif.\n"
             "-else.\n"
             "a bug.\n"
             "-else.\n"
             "a bug.\n"
             "-endif.">>,
           {errors,[{{7,2},epp,{illegal,"repeated",'else'}}],[]}},

          {ifndef_c3,
           <<"-ifndef(a).\n"
             "-endif">>,

           {errors,[{{2,2},epp,{bad,endif}},
                    {{2,7},epp,{illegal,"unterminated",ifndef}}],
          []}},

          {ifndef_c4,
           <<"\n-ifndef a.\n"
             "-endif.\n">>,
           {errors,[{{2,9},epp,{bad,ifndef}}],[]}},

          {define_c5,
           <<"-\ndefine a.\n">>,
           {errors,[{{2,8},epp,{bad,define}}],[]}}
          ],
    [] = compile(Config, Cs),

    Ts =  [{ifdef_1,
            <<"-ifdef(a).\n"
              "a bug.\n"
              "-else.\n"
              "-ifdef(A).\n"
              "a bug.\n"
              "-endif.\n"
              "t() -> ok.\n"
              "-endif.">>,
           ok},

           {ifdef_2,
            <<"-define(a, true).\n"
              "-ifdef(a).\n"
              "-define(A, true).\n"
              "-ifdef(A).\n"
              "t() -> ok.\n"
              "-else.\n"
              "a bug.\n"
              "-endif.\n"
              "-else.\n"
              "a bug.\n"
              "-endif.">>,
           ok},

           {ifdef_3,
            <<"\n-define(a, true).\n"
              "-ifndef(a).\n"
              "a bug.\n"
              "-else.\n"
              "-define(A, true).\n"
              "-ifndef(A).\n"
              "a bug.\n"
              "-else.\n"
              "t() -> ok.\n"
              "-endif.\n"
              "-endif.">>,
           ok},

           {ifdef_4,
                       <<"-ifdef(a).\n"
              "a bug.\n"
              "-ifdef(a).\n"
               "a bug.\n"
              "-else.\n"
              "-endif.\n"
             "-ifdef(A).\n"
              "a bug.\n"
             "-endif.\n"
             "-else.\n"
             "t() -> ok.\n"
             "-endif.">>,
            ok},

           {ifdef_5,
           <<"-ifdef(a).\n"
              "-ifndef(A).\n"
              "a bug.\n"
              "-else.\n"
              "-endif.\n"
             "a bug.\n"
             "-else.\n"
              "t() -> ok.\n"
             "-endif.">>,
            ok},

           {ifdef_6,
           <<"-ifdef(a).\n"
              "-if(A).\n"
              "a bug.\n"
              "-else.\n"
              "-endif.\n"
             "a bug.\n"
             "-else.\n"
              "t() -> ok.\n"
             "-endif.">>,
            ok}

           ],
    [] = run(Config, Ts).

%% OTP-12847: Test the -error directive.
test_error(Config) ->
    Cs = [{error_c1,
           <<"-error(\"string and macro: \" ?MODULE_STRING).\n"
	     "-ifdef(NOT_DEFINED).\n"
	     " -error(\"this one will be skipped\").\n"
	     "-endif.\n">>,
           {errors,[{{1,21},epp,{error,"string and macro: epp_test"}}],[]}},

	  {error_c2,
	   <<"-ifdef(CONFIG_A).\n"
	     " t() -> a.\n"
	     "-else.\n"
	     "-ifdef(CONFIG_B).\n"
	     " t() -> b.\n"
	     "-else.\n"
	     "-error(\"Neither CONFIG_A nor CONFIG_B are available\").\n"
	     "-endif.\n"
	     "-endif.\n">>,
	   {errors,[{{7,2},epp,{error,"Neither CONFIG_A nor CONFIG_B are available"}}],[]}},

	  {error_c3,
	   <<"-error(a b c).\n">>,
	   {errors,[{{1,21},epp,{bad,error}}],[]}}

	 ],

    [] = compile(Config, Cs),
    ok.

%% OTP-12847: Test the -warning directive.
test_warning(Config) ->
    Cs = [{warn_c1,
           <<"-warning({a,term,?MODULE}).\n"
	     "-ifdef(NOT_DEFINED).\n"
	     "-warning(\"this one will be skipped\").\n"
	     "-endif.\n">>,
           {warnings,[{{1,21},epp,{warning,{a,term,epp_test}}}]}},

	  {warn_c2,
	   <<"-ifdef(CONFIG_A).\n"
	     " t() -> a.\n"
	     "-else.\n"
	     "-ifdef(CONFIG_B).\n"
	     " t() -> b.\n"
	     "-else.\n"
	     " t() -> c.\n"
	     "-warning(\"Using fallback\").\n"
	     "-endif.\n"
	     "-endif.\n">>,
	   {warnings,[{{8,2},epp,{warning,"Using fallback"}}]}},

	  {warn_c3,
	   <<"-warning(a b c).\n">>,
	   {errors,[{{1,21},epp,{bad,warning}}],[]}}
	 ],

    [] = compile(Config, Cs),
    ok.

%% OTP-12847: Test the -if and -elif directives and the built-in
%% function defined(Symbol).
test_if(Config) ->
    Cs = [{if_1c,
	   <<"-if.\n"
	     "-endif.\n"
	     "-if no_parentheses.\n"
	     "-endif.\n"
	     "-if(syntax error.\n"
	     "-endif.\n"
	     "-if(true).\n"
	     "-if(a+3).\n"
	     "syntax error not triggered here.\n"
	     "-endif.\n">>,
           {errors,[{{1,23},epp,{bad,'if'}},
		    {{3,5},epp,{bad,'if'}},
		    {{5,12},erl_parse,["syntax error before: ","error"]},
		    {{11,1},epp,{illegal,"unterminated",'if'}}],
	    []}},

	  {if_2c,			       	%Bad guard expressions.
	   <<"-if(is_list(integer_to_list(42))).\n" %Not guard BIF.
	     "-endif.\n"
	     "-if(begin true end).\n"
	     "-endif.\n">>,
	   {errors,[{{1,21},epp,{bad,'if'}},
		    {{3,2},epp,{bad,'if'}}],
	    []}},

	  {if_3c,			       	%Invalid use of defined/1.
	   <<"-if defined(42).\n"
	     "-endif.\n">>,
	   {errors,[{{1,24},epp,{bad,'if'}}],[]}},

	  {if_4c,
	   <<"-elif OTP_RELEASE > 18.\n">>,
	   {errors,[{{1,21},epp,{illegal,"unbalanced",'elif'}}],[]}},

	  {if_5c,
	   <<"-ifdef(not_defined_today).\n"
	     "-else.\n"
	     "-elif OTP_RELEASE > 18.\n"
	     "-endif.\n">>,
	   {errors,[{{3,2},epp,{illegal,"unbalanced",'elif'}}],[]}},

	  {if_6c,
	   <<"-if(defined(OTP_RELEASE)).\n"
	     "-else.\n"
	     "-elif(true).\n"
	     "-endif.\n">>,
	   {errors,[{{3,2},epp,elif_after_else}],[]}},

	  {if_7c,
	   <<"-if(begin true end).\n"		%Not a guard expression.
	     "-endif.\n">>,
	   {errors,[{{1,21},epp,{bad,'if'}}],[]}},

	  {if_8c,
	   <<"-if(?foo).\n"                     %Undefined symbol.
	     "-endif.\n">>,
	   {errors,[{{1,25},epp,{undefined,foo,none}}],[]}},

	  {if_9c,
	   <<"-if(not_builtin()).\n"
	     "a bug.\n"
	     "-else.\n"
	     "t() -> ok.\n"
	     "-endif.\n">>,
	   {errors,[{{1,21},epp,{bad,'if'}}],[]}}
	 ],
    [] = compile(Config, Cs),

    Ts = [{if_1,
	   <<"-if(?OTP_RELEASE > 18).\n"
	     "t() -> ok.\n"
	     "-else.\n"
	     "a bug.\n"
	     "-endif.\n">>,
           ok},

	  {if_2,
	   <<"-if(false).\n"
	     "a bug.\n"
	     "-elif(?OTP_RELEASE > 18).\n"
	     "t() -> ok.\n"
	     "-else.\n"
	     "a bug.\n"
	     "-endif.\n">>,
           ok},

	  {if_3,
	   <<"-if(true).\n"
	     "t() -> ok.\n"
	     "-elif(?OTP_RELEASE > 18).\n"
	     "a bug.\n"
	     "-else.\n"
	     "a bug.\n"
	     "-endif.\n">>,
           ok},

	  {if_4,
	   <<"-define(a, 1).\n"
	     "-if(defined(a) andalso defined(OTP_RELEASE)).\n"
	     "t() -> ok.\n"
	     "-else.\n"
	     "a bug.\n"
	     "-endif.\n">>,
           ok},

	  {if_5,
	   <<"-if(defined(a)).\n"
	     "a bug.\n"
	     "-else.\n"
	     "t() -> ok.\n"
	     "-endif.\n">>,
           ok},

	  {if_6,
	   <<"-if(defined(not_defined_today)).\n"
	     " -if(true).\n"
	     "  bug1.\n"
	     " -elif(true).\n"
	     "  bug2.\n"
	     " -elif(true).\n"
	     "  bug3.\n"
	     " -else.\n"
	     "  bug4.\n"
	     " -endif.\n"
	     "-else.\n"
	     "t() -> ok.\n"
	     "-endif.\n">>,
           ok},

	  {if_7,
	   <<"-if(42).\n"			%Not boolean.
	     "a bug.\n"
	     "-else.\n"
	     "t() -> ok.\n"
	     "-endif.\n">>,
	   ok}
	 ],
    [] = run(Config, Ts),

    ok.

%% Advanced test on overloading macros.
overload_mac(Config) when is_list(Config) ->
    Cs = [
          %% '-undef' removes all definitions of a macro
          {overload_mac_c1,
           <<"-define(A, a).\n"
            "-define(A(X), X).\n"
            "-undef(A).\n"
            "t1() -> ?A.\n",
            "t2() -> ?A(1).">>,
           {errors,[{{4,10},epp,{undefined,'A', none}},
                    {{5,10},epp,{undefined,'A', 1}}],[]}},

          %% cannot overload predefined macros
          {overload_mac_c2,
           <<"\n-define(MODULE(X), X).">>,
           {errors,[{{2,9},epp,{redefine_predef,'MODULE'}}],[]}},

          %% cannot overload macros with same arity
          {overload_mac_c3,
           <<"-define(A(X), X).\n"
            "-define(A(Y), Y).">>,
           {errors,[{{2,9},epp,{redefine,'A'}}],[]}},

          {overload_mac_c4,
           <<"-define(A, a).\n"
            "-define(A(X,Y), {X,Y}).\n"
            "a(X) -> X.\n"
            "t() -> ?A(1).">>,
           {errors,[{{4,9},epp,{mismatch,'A'}}],[]}}
         ],
    [] = compile(Config, Cs),

    Ts = [
          {overload_mac_r1,
           <<"-define(A, 1).\n"
            "-define(A(X), X).\n"
            "-define(A(X, Y), {X, Y}).\n"
            "t() -> {?A, ?A(2), ?A(3, 4)}.">>,
           {1, 2, {3, 4}}},

          {overload_mac_r2,
           <<"-define(A, 1).\n"
            "-define(A(X), X).\n"
            "t() -> ?A(?A).">>,
           1},

          {overload_mac_r3,
           <<"-define(A, ?B).\n"
            "-define(B, a).\n"
            "-define(B(X), {b,X}).\n"
            "a(X) -> X.\n"
            "t() -> ?A(1).">>,
           1}
          ],
    [] = run(Config, Ts).


%% OTP-8388. More tests on overloaded macros.
otp_8388(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, "otp_8388.erl"),
    ok = file:write_file(File, <<"-module(otp_8388)."
                                       "-define(LINE, a).">>),
    fun() ->
            PreDefMacros = [{'LINE', a}],
            {error,{redefine_predef,'LINE'}} =
                epp:open(File, [], PreDefMacros)
    end(),

    fun() ->
            PreDefMacros = ['LINE'],
            {error,{redefine_predef,'LINE'}} =
                epp:open(File, [], PreDefMacros)
    end(),

    Ts = [
          {macro_1,
           <<"-define(m(A), A).\n"
             "t() -> ?m(,).\n">>,
           {errors,[{{2,9},epp,{arg_error,m}}],[]}},
          {macro_2,
           <<"-define(m(A), A).\n"
             "t() -> ?m(a,).\n">>,
           {errors,[{{2,9},epp,{arg_error,m}}],[]}},
          {macro_3,
           <<"\n-define(LINE, a).\n">>,
           {errors,[{{2,9},epp,{redefine_predef,'LINE'}}],[]}},
          {macro_4,
           <<"-define(A(B, C, D), {B,C,D}).\n"
             "t() -> ?A(a,,3).\n">>,
           {errors,[{{2,9},epp,{mismatch,'A'}}],[]}},
          {macro_5,
           <<"-define(Q, {?F0(), ?F1(,,4)}).\n">>,
           {errors,[{{1,40},epp,{arg_error,'F1'}}],[]}},
          {macro_6,
           <<"-define(FOO(X), ?BAR(X)).\n"
             "-define(BAR(X), ?FOO(X)).\n"
             "-undef(FOO).\n"
             "test() -> ?BAR(1).\n">>,
           {errors,[{{4,12},epp,{undefined,'FOO',1}}],[]}}
         ],
    [] = compile(Config, Ts),
    ok.

%% OTP-8470. Bugfix (one request - two replies).
otp_8470(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    C = <<"-file(\"erl_parse.yrl\", 486).\n"
          "-file(\"erl_parse.yrl\", 488).\n">>,
    File = filename:join(Dir, "otp_8470.erl"),
    ok = file:write_file(File, C),
    {ok, _List} = epp:parse_file(File, [], []),
    file:delete(File),
    receive _ -> fail() after 0 -> ok end,
    ok.

%% OTP-8562. Record with no fields is considered typed.
otp_8562(Config) when is_list(Config) ->
    Cs = [{otp_8562,
           <<"\n-define(P(), {a,b}.\n"
             "-define(P3, .\n">>,
           {errors,[{{2,19},epp,missing_parenthesis},
                    {{3,13},epp,missing_parenthesis}], []}}
         ],
    [] = compile(Config, Cs),
    ok.

%% OTP-8911. -file and file inclusion bug.
otp_8911(Config) when is_list(Config) ->
    case test_server:is_cover() of
	true ->
	    {skip, "Testing cover, so cannot run when cover is already running"};
	false ->
	    do_otp_8911(Config)
    end.
do_otp_8911(Config) ->
    {ok, CWD} = file:get_cwd(),
    ok = file:set_cwd(proplists:get_value(priv_dir, Config)),

    File = "i.erl",
    Cont = <<"-module(i).
              -export([t/0]).
              -file(\"fil1\", 100).
              -include(\"i1.erl\").
              t() ->
                  a.
           ">>,
    ok = file:write_file(File, Cont),
    Incl = <<"-file(\"fil2\", 35).
              t1() ->
                  b.
           ">>,
    File1 = "i1.erl",
    ok = file:write_file(File1, Incl),

    {ok, i} = cover:compile(File),
    a = i:t(),
    {ok,[{{i,6},1}]} = cover:analyse(i, calls, line),
    cover:stop(),

    file:delete(File),
    file:delete(File1),
    file:set_cwd(CWD),
    ok.

%% OTP-8665. Bugfix premature end.
otp_8665(Config) when is_list(Config) ->
    Cs = [{otp_8665,
           <<"\n-define(A, a)\n">>,
           {errors,[{{2,13},epp,premature_end}],[]}}
         ],
    [] = compile(Config, Cs),
    ok.

%% OTP-10302. Unicode characters scanner/parser.
otp_10302(Config) when is_list(Config) ->
    %% Two messages (one too many). Keeps otp_4871 happy.
    Cs = [{otp_10302,
           <<"%% coding: utf-8\n \n \x{E4}">>,
           {errors,[{{3,1},epp,cannot_parse},
                    {{3,1},file_io_server,invalid_unicode}],[]}}
         ],
    [] = compile(Config, Cs),
    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, "otp_10302.erl"),
    utf8 = encoding("coding: utf-8", File),
    utf8 = encoding("coding: UTF-8", File),
    latin1 = encoding("coding: Latin-1", File),
    latin1 = encoding("coding: latin-1", File),
    none = encoding_com("coding: utf-8", File),
    none = encoding_com("\n\n%% coding: utf-8", File),
    none = encoding_nocom("\n\n coding: utf-8", File),
    utf8 = encoding_com("\n%% coding: utf-8", File),
    utf8 = encoding_nocom("\n coding: utf-8", File),
    none = encoding("coding: \nutf-8", File),
    latin1 = encoding("Encoding :  latin-1", File),
    utf8 = encoding("ccoding: UTF-8", File),
    utf8 = encoding("coding= utf-8", File),
    utf8 = encoding_com(" %% coding= utf-8", File),
    utf8 = encoding("coding  =  utf-8", File),
    none = encoding("coding: utf-16 coding: utf-8", File), %first is bad
    none = encoding("Coding: utf-8", File),    %capital c
    utf8 = encoding("-*- coding: utf-8 -*-", File),
    utf8 = encoding("-*-coding= utf-8-*-", File),
    utf8 = encoding("codingcoding= utf-8", File),
    ok = prefix("coding: utf-8", File, utf8),

    "coding: latin-1" = epp:encoding_to_string(latin1),
    "coding: utf-8" = epp:encoding_to_string(utf8),
    true = lists:member(epp:default_encoding(), [latin1, utf8]),

    ok.

prefix(S, File, Enc) ->
    prefix(0, S, File, Enc).

prefix(100, _S, _File, _) ->
    ok;
prefix(N, S, File, Enc) ->
    Enc = encoding(lists:duplicate(N, $\s) ++ S, File),
    prefix(N+1, S, File, Enc).

encoding(Enc, File) ->
    E = encoding_com("%% " ++ Enc, File),
    none = encoding_com(Enc, File),
    E = encoding_nocom(Enc, File).

encoding_com(Enc, File) ->
    B = list_to_binary(Enc),
    E = epp:read_encoding_from_binary(B),
    ok = file:write_file(File, Enc),
    {ok, Fd} = file:open(File, [read]),
    E = epp:set_encoding(Fd),
    ok = file:close(Fd),
    E = epp:read_encoding(File).

encoding_nocom(Enc, File) ->
    Options = [{in_comment_only, false}],
    B = list_to_binary(Enc),
    E = epp:read_encoding_from_binary(B, Options),
    ok = file:write_file(File, Enc),
    {ok, Fd} = file:open(File, [read]),
    ok = file:close(Fd),
    E = epp:read_encoding(File, Options).

%% OTP-10820. Unicode filenames.
otp_10820(Config) when is_list(Config) ->
    L = [915,953,959,973,957,953,954,959,957,964],
    Dir = proplists:get_value(priv_dir, Config),
    File = filename:join(Dir, L++".erl"),
    C1 = <<"%% coding: utf-8\n -module(any).">>,
    ok = do_otp_10820(File, C1, ["+pc", "latin1"]),
    ok = do_otp_10820(File, C1, ["+pc", "unicode"]),
    C2 = <<"\n-module(any).">>,
    ok = do_otp_10820(File, C2, ["+pc", "latin1"]),
    ok = do_otp_10820(File, C2, ["+pc", "unicode"]).

do_otp_10820(File, C, PC) ->
    {ok,Peer,Node} = ?CT_PEER(["+fnu"] ++ PC),
    ok = rpc:call(Node, file, write_file, [File, C]),
    {ok, Forms} = rpc:call(Node, epp, parse_file, [File, [],[]]),
    [{attribute,1,file,{File,1}},
     {attribute,2,module,any},
     {eof,2}] = unopaque_forms(Forms),
    peer:stop(Peer),
    ok.

%% OTP_14285: Unicode atoms.
otp_14285(Config) when is_list(Config) ->
    %% This is just a sample of errors.
    Cs = [{otp_14285,
           <<"-export([f/0]).
              -define('a\x{400}b', 'a\x{400}d').
              f() ->
                  ?'a\x{400}b'.
              g() ->
                  ?\"a\x{400}b\".
              h() ->
                  ?'a\x{400}no'().
              "/utf8>>,
           {errors,[{{6,20},epp,{call,[63,[91,["97",44,"1024",44,"98"],93]]}},
                    {{8,20},epp,{undefined,'a\x{400}no',0}}],
            []}}
         ],
    [] = compile(Config, Cs),
    ok.

%% OTP-11728. Bugfix circular macro.
otp_11728(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    H = <<"-define(MACRO,[[]++?MACRO]).">>,
    HrlFile = filename:join(Dir, "otp_11728.hrl"),
    ok = file:write_file(HrlFile, H),
    C = <<"-module(otp_11728).
           -export([function_name/0]).

           -include(\"otp_11728.hrl\").

           function_name()->
               A=?MACRO, % line 7
               ok">>,
    ErlFile = filename:join(Dir, "otp_11728.erl"),
    ok = file:write_file(ErlFile, C),
    {ok, L} = epp:parse_file(ErlFile, [Dir], []),
    true = lists:member({error,{7,epp,{circular,'MACRO',none}}}, L),
    _ = file:delete(HrlFile),
    _ = file:delete(ErlFile),
    ok.

%% Check the new API for setting the default encoding.
encoding(Config) when is_list(Config) ->
    Dir = proplists:get_value(priv_dir, Config),
    ErlFile = filename:join(Dir, "encoding.erl"),

    %% Try a latin-1 file with no encoding given.
    C1 = <<"-module(encoding).
           %% ",246,"
	  ">>,
    ok = file:write_file(ErlFile, C1),
    {ok,[{attribute,{1,1},file,_},
	 {attribute,{1,2},module,encoding},
	 {error,_},
	 {error,{{2,12},epp,cannot_parse}},
	 {eof,{2,12}}]} = epp_parse_file(ErlFile, [{location, {1,1}}]),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,3}]} =
	epp_parse_file(ErlFile, [{default_encoding,latin1}]),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,3}],Extra0} =
	epp_parse_file(ErlFile, [{default_encoding,latin1},extra]),
    none = proplists:get_value(encoding, Extra0),

    %% Try a latin-1 file with encoding given in a comment.
    C2 = <<"-module(encoding).
           %% encoding: latin-1
           %% ",246,"
	  ">>,
    ok = file:write_file(ErlFile, C2),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}]} =
	epp_parse_file(ErlFile, []),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}]} =
	epp_parse_file(ErlFile, [{default_encoding,latin1}]),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}]} =
	epp_parse_file(ErlFile, [{default_encoding,utf8}]),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}],Extra1} =
	epp_parse_file(ErlFile, [extra]),
    latin1 = proplists:get_value(encoding, Extra1),

    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}],Extra2} =
	epp_parse_file(ErlFile, [{default_encoding,latin1},extra]),
    latin1 = proplists:get_value(encoding, Extra2),
    {ok,[{attribute,1,file,_},
	 {attribute,1,module,encoding},
	 {eof,4}],Extra3} =
	epp_parse_file(ErlFile, [{default_encoding,utf8},extra]),
    latin1 = proplists:get_value(encoding, Extra3),
    ok.

extends(Config) ->
    Cs = [{extends_c1,
	   <<"-extends(some.other.module).\n">>,
	   {errors,[{{1,33},erl_parse,["syntax error before: ","'.'"]}],[]}}],
    [] = compile(Config, Cs),

    Ts = [{extends_1,
	   <<"-extends(some_other_module).\n"
	     "t() -> {?BASE_MODULE,?BASE_MODULE_STRING}.\n">>,
	   {some_other_module,"some_other_module"}}],

    [] = run(Config, Ts),
    ok.

function_macro(Config) ->
    Cs = [{f_c1,
	   <<"-define(FUNCTION_NAME, a).\n"
	     "-define(FUNCTION_ARITY, a).\n"
	     "-define(FS,\n"
	     " atom_to_list(?FUNCTION_NAME) ++ \"/\" ++\n"
	     " integer_to_list(?FUNCTION_ARITY)).\n"
	     "-attr({f,?FUNCTION_NAME}).\n"
	     "-attr2(?FS).\n"
	     "-file(?FUNCTION_ARITY, 1).\n"
	     "f1() ?FUNCTION_NAME/?FUNCTION_ARITY.\n"
	     "f2(?FUNCTION_NAME.\n">>,
	   {errors,[{{1,28},epp,{redefine_predef,'FUNCTION_NAME'}},
		    {{2,9},epp,{redefine_predef,'FUNCTION_ARITY'}},
		    {{6,11},epp,{illegal_function,'FUNCTION_NAME'}},
		    {{7,9},epp,{illegal_function,'FUNCTION_NAME'}},
		    {{8,8},epp,{illegal_function,'FUNCTION_ARITY'}},
		    {{9,7},erl_parse,["syntax error before: ","f1"]},
		    {{10,18},erl_parse,["syntax error before: ","'.'"]}],
	    []}},

	  {f_c2,
	   <<"a({a) -> ?FUNCTION_NAME.\n"
	     "b(}{) -> ?FUNCTION_ARITY.\n"
	     "c(?FUNCTION_NAME, ?not_defined) -> ok.\n">>,
	   {errors,[{{1,24},erl_parse,["syntax error before: ","')'"]},
		    {{2,3},erl_parse,["syntax error before: ","'}'"]},
		    {{3,20},epp,{undefined,not_defined,none}}],
	    []}},

	  {f_c3,
	   <<"?FUNCTION_NAME() -> ok.\n"
	     "?FUNCTION_ARITY() -> ok.\n">>,
	   {errors,[{{1,21},epp,{illegal_function_usage,'FUNCTION_NAME'}},
		    {{2,2},epp,{illegal_function_usage,'FUNCTION_ARITY'}}],
	    []}}
	 ],

    [] = compile(Config, Cs),

    Ts = [{f_1,
	   <<"t() -> {a,0} = a(), {b,1} = b(1), {c,2} = c(1, 2),\n"
	     "  {d,1} = d({d,1}), {foo,1} = foo(foo), ok.\n"
	     "a() -> {?FUNCTION_NAME,?FUNCTION_ARITY}.\n"
	     "b(_) -> {?FUNCTION_NAME,?FUNCTION_ARITY}.\n"
	     "c(_, (_)) -> {?FUNCTION_NAME,?FUNCTION_ARITY}.\n"
	     "d({?FUNCTION_NAME,?FUNCTION_ARITY}=F) -> F.\n"
	     "-define(FOO, foo).\n"
	     "?FOO(?FOO) -> {?FUNCTION_NAME,?FUNCTION_ARITY}.\n">>,
	   ok},

	  {f_2,
	   <<"t() ->\n"
             "  A = {a,[<<0:24>>,#{a=>1,b=>2}]},\n"
	     "  1 = a(A),\n"
	     "  ok.\n"
	     "a({a,[<<_,_,_>>,#{a:=1,b:=2}]}) -> ?FUNCTION_ARITY.\n">>,
	   ok},

	  {f_3,
	   <<"-define(FS,\n"
	     " atom_to_list(?FUNCTION_NAME) ++ \"/\" ++\n"
	     " integer_to_list(?FUNCTION_ARITY)).\n"
	     "t() ->\n"
	     "  {t,0} = {?FUNCTION_NAME,?FUNCTION_ARITY},\n"
	     "  \"t/0\" = ?FS,\n"
	     "  ok.\n">>,
	   ok},

	  {f_4,
	   <<"-define(__, _, _).\n"
	     "-define(FF, ?FUNCTION_NAME, ?FUNCTION_ARITY).\n"
	     "a(?__) -> 2 = ?FUNCTION_ARITY.\n"
	     "b(?FUNCTION_ARITY, ?__) -> ok.\n"
	     "c(?FF) -> ok.\n"
	     "t() -> a(1, 2), b(3, 1, 2), c(c, 2), ok.\n">>,
	   ok}
	 ],
    [] = run(Config, Ts),

    ok.

source_name(Config) when is_list(Config) ->
    DataDir = proplists:get_value(data_dir, Config),
    File = filename:join(DataDir, "source_name.erl"),

    source_name_1(File, "/test/gurka.erl"),
    source_name_1(File, "gaffel.erl"),

    ok.

source_name_1(File, Expected) ->
    Res = epp:parse_file(File, [{source_name, Expected}]),
    {ok, [{attribute,_,file,{Expected,_}} | _Forms]} = Res.

otp_16978(Config) when is_list(Config) ->
    %% A test of erl_parse:tokens().
    P = <<"t() -> ?a.">>,
    Vs = [#{},
          #{k => 1,[[a],[{}]] => "str"},
          #{#{} => [{#{x=>#{3=>$3}}},{3.14,#{}}]}],
    Ts = [{erl_parse_tokens,
           P,
           [{d,{a,V}}],
           V} || V <- Vs],
    [] = run(Config, Ts),

    ok.

otp_16824(Config) when is_list(Config) ->
    Cs = [{otp_16824_1,
           <<"\n-file(.">>,
           {errors,[{{2,7},epp,{bad,file}}],[]}},

          {otp_16824_2,
           <<"\n-file(foo, a).">>,
           {errors,[{{2,7},epp,{bad,file}}],[]}},

          {otp_16824_3,
           <<"\n-file(\"foo\" + a).">>,
           {errors,[{{2,13},epp,{bad,file}}],[]}},

          {otp_16824_4,
           <<"\n-file(\"foo\", a).">>,
           {errors,[{{2,14},epp,{bad,file}}],[]}},

          %% The location before "foo", not after, unfortunately.
          {otp_16824_5,
           <<"\n-file(\"foo\"">>,
           {errors,[{{2,7},epp,{bad,file}}],[]}},

          {otp_16824_6,
           <<"\n-endif()">>,
           {errors,[{{2,7},epp,{bad,endif}}],[]}},

          {otp_16824_7,
           <<"\n-if[.\n"
             "-endif.">>,
           {errors,[{{2,4},epp,{bad,'if'}}],
            []}},

          {otp_16824_8,
           <<"\n-else\n"
             "-endif.">>,
           {errors,[{{3,1},epp,{bad,'else'}}],[]}},

          {otp_16824_9,
           <<"\n-ifndef.\n"
             "-endif.">>,
           {errors,[{{2,8},epp,{bad,ifndef}}],[]}},

          {otp_16824_10,
           <<"\n-ifndef(.\n"
             "-endif.">>,
           {errors,[{{2,9},epp,{bad,ifndef}}],[]}},

          {otp_16824_11,
           <<"\n-ifndef(a.\n"
             "-endif.">>,
           {errors,[{{2,10},epp,{bad,ifndef}}],[]}},

          {otp_16824_12,
           <<"\n-ifndef(A.\n"
             "-endif.">>,
           {errors,[{{2,10},epp,{bad,ifndef}}],[]}},

          {otp_16824_13,
           <<"\n-ifndef(a,A).\n"
             "-endif.">>,
           {errors,[{{2,10},epp,{bad,ifndef}}],[]}},

          {otp_16824_14,
           <<"\n-ifndef(A,a).\n"
             "-endif.">>,
           {errors,[{{2,10},epp,{bad,ifndef}}],[]}},

          {otp_16824_15,
           <<"\n-ifdef.\n"
             "-endif.">>,
           {errors,[{{2,7},epp,{bad,ifdef}}],[]}},

          {otp_16824_16,
           <<"\n-ifdef(.\n"
             "-endif.">>,
           {errors,[{{2,8},epp,{bad,ifdef}}],[]}},

          {otp_16824_17,
           <<"\n-ifdef(a.\n"
             "-endif.">>,
           {errors,[{{2,9},epp,{bad,ifdef}}],[]}},

          {otp_16824_18,
           <<"\n-ifdef(A.\n"
             "-endif.">>,
           {errors,[{{2,9},epp,{bad,ifdef}}],[]}},

          {otp_16824_19,
           <<"\n-ifdef(a,A).\n"
             "-endif.">>,
           {errors,[{{2,9},epp,{bad,ifdef}}],[]}},

          {otp_16824_20,
           <<"\n-ifdef(A,a).\n"
             "-endif.">>,
           {errors,[{{2,9},epp,{bad,ifdef}}],[]}},

          {otp_16824_21,
           <<"\n-include_lib.\n">>,
           {errors,[{{2,13},epp,{bad,include_lib}}],[]}},

          {otp_16824_22,
           <<"\n-include_lib(.\n">>,
           {errors,[{{2,14},epp,{bad,include_lib}}],[]}},

          {otp_16824_23,
           <<"\n-include_lib(a.\n">>,
           {errors,[{{2,14},epp,{bad,include_lib}}],[]}},

          {otp_16824_24,
           <<"\n-include_lib(\"a\"].\n">>,
           {errors,[{{2,17},epp,{bad,include_lib}}],[]}},

          {otp_16824_25,
           <<"\n-include_lib(\"a\", 1).\n">>,
           {errors,[{{2,17},epp,{bad,include_lib}}],[]}},

          {otp_16824_26,
           <<"\n-include.\n">>,
           {errors,[{{2,9},epp,{bad,include}}],[]}},

          {otp_16824_27,
           <<"\n-include(.\n">>,
           {errors,[{{2,10},epp,{bad,include}}],[]}},

          {otp_16824_28,
           <<"\n-include(a.\n">>,
           {errors,[{{2,10},epp,{bad,include}}],[]}},

          {otp_16824_29,
           <<"\n-include(\"a\"].\n">>,
           {errors,[{{2,13},epp,{bad,include}}],[]}},

          {otp_16824_30,
           <<"\n-include(\"a\", 1).\n">>,
           {errors,[{{2,13},epp,{bad,include}}],[]}},

          {otp_16824_31,
           <<"\n-undef.\n">>,
           {errors,[{{2,7},epp,{bad,undef}}],[]}},

          {otp_16824_32,
           <<"\n-undef(.\n">>,
           {errors,[{{2,8},epp,{bad,undef}}],[]}},

          {otp_16824_33,
           <<"\n-undef(a.\n">>,
           {errors,[{{2,9},epp,{bad,undef}}],[]}},

          {otp_16824_34,
           <<"\n-undef(A.\n">>,
           {errors,[{{2,9},epp,{bad,undef}}],[]}},

          {otp_16824_35,
           <<"\n-undef(a,A).\n">>,
           {errors,[{{2,9},epp,{bad,undef}}],[]}},

          {otp_16824_36,
           <<"\n-undef(A,a).\n">>,
           {errors,[{{2,9},epp,{bad,undef}}],[]}},

          {otp_16824_37,
           <<"\n-define.\n">>,
           {errors,[{{2,8},epp,{bad,define}}],[]}},

          {otp_16824_38,
           <<"\n-define(.\n">>,
           {errors,[{{2,9},epp,{bad,define}}],[]}},

          {otp_16824_39,
           <<"\n-define(1.\n">>,
           {errors,[{{2,9},epp,{bad,define}}],[]}},

          {otp_16824_40,
           <<"\n-define(a b.\n">>,
           {errors,[{{2,11},epp,{bad,define}}],[]}},

          {otp_16824_41,
           <<"\n-define(A b.\n">>,
           {errors,[{{2,11},epp,{bad,define}}],[]}},

          {otp_16824_42,
           <<"\n-define(a(A, A), 1).\n">>,
           {errors,[{{2,14},epp,{duplicated_argument,'A'}}],[]}},

          {otp_16824_43,
           <<"\n-define(a(A, A, B), 1).\n">>,
           {errors,[{{2,14},epp,{duplicated_argument,'A'}}],[]}},

          {otp_16824_44,
           <<"\n-define(a(.">>,
           {errors,[{{2,11},epp,{bad,define}}],[]}},

          {otp_16824_45,
           <<"\n-define(a(1.">>,
           {errors,[{{2,11},epp,{bad,define}}],[]}},

          {otp_16824_46,
           <<"\n-define(a().">>,
           {errors,[{{2,12},epp,missing_comma}],[]}},

          {otp_16824_47,
           <<"\n-define(a())">>,
           {errors,[{{2,12},epp,missing_comma}],[]}},

          {otp_16824_48,
           <<"\n-define(A(A,), foo).\n">>,
           {errors,[{{2,12},epp,{bad,define}}],[]}},

          {otp_16824_49,
           <<"\n-warning.">>,
           {errors,[{{2,9},epp,{bad,warning}}],[]}},

          {otp_16824_50,
           <<"\n-warning">>,
           {errors,[{{2,2},epp,{bad,warning}}],[]}}

          ],
    [] = compile(Config, Cs),
    ok.

gh_8268(Config) ->
    Ts = [{circular_1,
           <<"-define(LOG(Tag, Code), io:format(\"~s\", [Tag]), Code).
             more_work() -> ok.
             some_work() -> ok.
             t() ->
                ?LOG(work,
                     begin
                        maybe
                           ok ?= some_work()
                        end,
                        more_work()
                     end).
             ">>,
           [{feature,maybe_expr,enable}],
           ok}],
    [] = run(Config, Ts),
    ok.

stringify(Config) ->
    Ts = [{stringify_1,
           ~"""
            -define(S(S), ??S).
            t() ->
                ~S('атом') = ?S('атом'),
                ~S("атом") = ?S("атом"),
                ok.
            """,
           [],
           ok}],
    [] = run(Config, Ts),
    ok.

%% Start location is 1.
check(Config, Tests) ->
    eval_tests(Config, fun check_test/3, Tests).

%% Start location is {1,1}.
compile(Config, Tests) ->
    eval_tests(Config, fun compile_test/3, Tests).

run(Config, Tests) ->
    eval_tests(Config, fun run_test/3, Tests).

eval_tests(Config, Fun, Tests) ->
    TestsWithOpts =
        [case Test of
             {N,P,E} ->
                 {N,P,[],E};
             {_,_,_,_} ->
                 Test
         end || Test <- Tests],
    F = fun({N,P,Opts,E}, BadL) ->
                %% io:format("Testing ~p~n", [P]),
                Return = Fun(Config, P, Opts),
                %% The result should be the same when enabling maybe ... end
                %% (making 'else' a keyword instead of an atom).
                Return = Fun(Config, P, [{feature,maybe_expr,enable}|Opts]),
                case message_compare(E, Return) of
                    true ->
                        case E of
                            {errors, Errors} ->
                                call_format_error(Errors);
                            _ ->
                                ok
                        end,
                        BadL;
                    false ->
                        io:format("~nTest ~p failed. Expected~n  ~p~n"
                                  "but got~n  ~p~n", [N, E, Return]),
			fail()
                end
        end,
    lists:foldl(F, [], TestsWithOpts).

check_test(Config, Test, Opts) ->
    Filename = "epp_test.erl",
    PrivDir = proplists:get_value(priv_dir, Config),
    File = filename:join(PrivDir, Filename),
    ok = file:write_file(File, Test),
    case epp:parse_file(File, [{includes, PrivDir}| Opts]) of
	{ok,Forms} ->
	    Errors = [E || E={error,_} <- Forms],
	    call_format_error([E || {error,E} <- Errors]),
	    Errors;
	{error,Error} ->
	    Error
    end.

compile_test(Config, Test0, Opts0) ->
    Test = [<<"-module(epp_test). ">>, Test0],
    Filename = "epp_test.erl",
    PrivDir = proplists:get_value(priv_dir, Config),
    File = filename:join(PrivDir, Filename),
    ok = file:write_file(File, Test),
    Opts = [export_all,nowarn_export_all,return,nowarn_unused_record,{outdir,PrivDir}] ++ Opts0,
    case compile_file(File, Opts) of
        {ok, Ws} -> warnings(File, Ws);
        {errors, Errors}=Else ->
            call_format_error(Errors),
            Else;
        Else -> Else
    end.

warnings(File, Ws) ->
    case lists:append([W || {F, W} <- Ws, F =:= File]) of
        [] ->
	    [];
        L ->
	    call_format_error(L),
	    {warnings, L}
    end.

compile_file(File, Opts) ->
    case compile:file(File, Opts) of
        {ok, _M, Ws} -> {ok, Ws};
        {error, FEs, []} -> {errors, errs(FEs, File), []};
        {error, FEs, [{File,Ws}]} -> {error, errs(FEs, File), Ws}
    end.

errs([{File,Es}|L], File) ->
    call_format_error(Es),
    Es ++ errs(L, File);
errs([_|L], File) ->
    errs(L, File);
errs([], _File) ->
    [].

%% Smoke test and coverage of format_error/1.
call_format_error([{_,M,E}|T]) ->
    _ = M:format_error(E),
    call_format_error(T);
call_format_error([]) ->
    ok.

epp_parse_file(File, Opts) ->
    case epp:parse_file(File, Opts) of
        {ok, Forms} ->
            {ok, unopaque_forms(Forms)};
        {ok, Forms, Other} ->
            {ok, unopaque_forms(Forms), Other}
    end.

unopaque_forms(Forms) ->
    [erl_parse:anno_to_term(Form) || Form <- Forms].

run_test(Config, Test0, Opts0) ->
    Test = [<<"-module(epp_test). -export([t/0]). ">>, Test0],
    Filename = "epp_test.erl",
    PrivDir = proplists:get_value(priv_dir, Config),
    File = filename:join(PrivDir, Filename),
    ok = file:write_file(File, Test),
    Opts = [return, {i,PrivDir},{outdir,PrivDir}] ++ Opts0,
    {ok, epp_test, []} = compile:file(File, Opts),
    AbsFile = filename:rootname(File, ".erl"),

    case lists:member({feature, maybe_expr, enable}, Opts0) of
        false ->
            %% Run in node
            {module, epp_test} = code:load_abs(AbsFile, epp_test),
            Reply = epp_test:t(),
            code:purge(epp_test),
            Reply;
        true ->
            %% Run in peer with maybe_expr enabled
            {ok, Peer, Node} =
                ?CT_PEER(#{args => ["-enable-feature","maybe_expr"],
                           connection => 0}),
            {module, epp_test} =
                rpc:call(Node, code, load_abs, [AbsFile, epp_test]),
            Reply = rpc:call(Node, epp_test, t, []),
            peer:stop(Peer),
            Reply
    end.

fail() ->
    ct:fail(failed).

message_compare(T, T) ->
    T =:= T.
