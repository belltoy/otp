%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2013-2025. All Rights Reserved.
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
%%
%%

%%
%% ct:run("../inets_test", httpd_SUITE).
%%
-compile({no_auto_import,[alias/1]}).
-module(httpd_SUITE).

-include_lib("kernel/include/file.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("public_key/include/public_key.hrl").
-include_lib("inets/include/httpd.hrl").
-include("inets_test_lib.hrl").
-include_lib("stdlib/include/assert.hrl").
%% Note: This directive should only be used in test suites.
-compile(export_all).

-record(httpd_user,  {user_name, password, user_data}).
-record(httpd_group, {group_name, userlist}).
-define(MAX_HEADER_SIZE, 256).
%% Minutes before failed auths timeout.
-define(FAIL_EXPIRE_TIME,1).
%% Seconds before successful auths timeout.
-define(AUTH_TIMEOUT,5).
-define(URL_START, "http://").

%%--------------------------------------------------------------------
%% Common Test interface functions -----------------------------------
%%--------------------------------------------------------------------
suite() ->
    [{ct_hooks,[ts_install_cth]},
     {timetrap,{seconds, 120}}
    ].

all() ->
    [
     {group, http_basic},
     {group, https_basic},
     {group, http_limit},
     {group, https_limit},
     {group, http_custom},
     {group, https_custom},
     {group, https_custom},
     {group, http_basic_auth},
     {group, https_basic_auth},
     {group, http_auth_api},
     {group, https_auth_api},
     {group, http_auth_api_dets},
     {group, https_auth_api_dets},
     {group, http_auth_api_mnesia},
     {group, https_auth_api_mnesia},
     {group, http_security},
     {group, https_security},
     {group, http_reload},
     {group, https_reload},
     {group, http_default_type},
     {group, http_mime_type},
     {group, http_mime_and_default_type},
     {group, http_mime_types},
     {group, http_logging},
     {group, http_post},
     {group, http_rel_path_script_alias},
     {group, http_not_sup},
     {group, https_alert},
     {group, https_not_sup},
     {group, esi},
     mime_types_format
    ].

groups() ->
    [
     {http_basic, [], basic_groups()},
     {https_basic, [], basic_groups()},
     {http_limit, [], [{group, limit}]},
     {https_limit, [], [{group, limit}]},
     {http_custom, [], [{group,  custom}]},
     {https_custom, [], [{group,  custom}]},
     {http_basic_auth, [], [{group, basic_auth}]},
     {https_basic_auth, [], [{group, basic_auth}]},
     {http_auth_api, [], [{group, auth_api}]},
     {https_auth_api, [], [{group, auth_api}]},
     {http_auth_api_dets, [], [{group, auth_api_dets}]},
     {https_auth_api_dets, [], [{group, auth_api_dets}]},
     {http_auth_api_mnesia, [], [{group, auth_api_mnesia}]},
     {https_auth_api_mnesia, [], [{group, auth_api_mnesia}]},
     {http_security, [], [{group, security}]},
     {https_security, [], [{group, security}]},
     {http_logging, [], [{group, logging}]},
     {http_reload, [], [{group, reload}]},
     {https_reload, [], [{group, reload}]},
     {http_post, [], [{group, post}]},
     {http_not_sup, [], [{group, not_sup}]},
     {https_not_sup, [], [{group, not_sup}]},
     {https_alert, [], [tls_alert]},
     {http_default_type, [], [default_type]},
     {http_mime_type, [], [mime_type]},
     {http_mime_and_default_type, [], [mime_and_default_type]},
     {http_mime_types, [parallel], [alias_1_1, alias_1_0]},
     {limit, [],  [content_length, max_clients_1_1]},
     {custom, [],  [customize, add_default]},
     {reload, [], [non_disturbing_reconfiger_dies,
		   disturbing_reconfiger_dies,
		   non_disturbing_1_1,
		   non_disturbing_1_0,
           disturbing_1_1,
           disturbing_1_0,
		   reload_config_file
		  ]},
     {post, [], [chunked_post, chunked_chunked_encoded_post, post_204]},
     {basic_auth, [], [basic_auth_1_1, basic_auth_1_0, verify_href_1_1]},
     {auth_api, [], [auth_api_1_1, auth_api_1_0]},
     {auth_api_dets, [], [auth_api_1_1, auth_api_1_0]},
     {auth_api_mnesia, [], [auth_api_1_1, auth_api_1_0]},
     {security, [], [security_1_1, security_1_0]},
     {logging, [], [disk_log_internal, disk_log_exists,
             disk_log_bad_size, disk_log_bad_file]},
     {http_1_1, [], [esi_propagate, esi_atom_leak, {group, http_1_1_parallel}] ++ load()},
     {http_1_1_parallel, [parallel],
      [host, chunked, expect, cgi, cgi_chunked_encoding_test,
       trace, range, if_modified_since, mod_esi_chunk_timeout,
       esi_put, esi_patch, esi_post, esi_headers]
      ++ http_head() ++ http_get()},
     {http_1_0, [], [{group, http_1_0_parallel} | load()]},
     {http_1_0_parallel, [parallel], [host, cgi, trace] ++ http_head() ++ http_get()},
     {http_rel_path_script_alias, [], [cgi]},
     {esi, [], [erl_script_timeout_default,
                erl_script_timeout_option,
                erl_script_timeout_proplist,
                erl_script_alias_all]},
     {not_sup, [], [put_not_sup]}
    ].

basic_groups ()->
    [{group, http_1_1},
     {group, http_1_0}
    ].

http_head() ->
    [head].
http_get() ->
    [alias,
     get,
     bad_dot_paths,
     %%actions, Add configuration so that this test mod_action
     esi,
     filename_too_long,
     bad_hex,
     missing_CR,
     max_header,
     max_content_length,
     ignore_invalid_header,
     ipv6,
     same_file_name_dir_name
    ].


load() ->
    [light, medium
     %%,heavy
    ].

init_per_suite(Config) ->
    PrivDir = proplists:get_value(priv_dir, Config),
    DataDir = proplists:get_value(data_dir, Config),
    inets_test_lib:stop_apps([inets]),
    ServerRoot = filename:join(PrivDir, "server_root"),
    inets_test_lib:del_dirs(ServerRoot),
    DocRoot = filename:join(ServerRoot, "htdocs"),
    setup_tmp_dir(PrivDir),
    setup_server_dirs(ServerRoot, DocRoot, DataDir),
    {ok, Hostname0} = inet:gethostname(),
    logger:add_handler_filter(default, inets_httpd, {fun logger_filters:domain/2,
                                                     {log, equal,[otp,inets, httpd, httpd_test, error]}}),
    %%logger:set_handler_config(default, formatter, {logger_formatter, #{}}),
    Inet =
	case (catch ct:get_config(ipv6_hosts)) of
	    undefined ->
		inet;
	    Hosts when is_list(Hosts) ->
		case lists:member(list_to_atom(Hostname0), Hosts) of
		    true ->
			inet6;
		    false ->
			inet
		end;
	    _ ->
		inet
	end,
    [{server_root, ServerRoot},
     {doc_root, DocRoot},
     {ipfamily, Inet},
     {node,             node()},
     {host,             inets_test_lib:hostname()},
     {address,          getaddr()} | Config].

end_per_suite(_Config) ->
    ok.

%%--------------------------------------------------------------------
init_per_group(Group, Config0) when Group == https_basic;
				    Group == https_limit;
				    Group == https_custom;
				    Group == https_basic_auth;
				    Group == https_auth_api;
				    Group == https_auth_api_dets;
				    Group == https_auth_api_mnesia;
				    Group == https_security;
				    Group == https_reload;
                                    Group == https_not_sup;
                                    Group == https_alert
				    ->
    catch application:stop(crypto),
    try application:start(crypto) of
        ok ->
            init_ssl(Group,  [{http_version, "HTTP/1.0"} | Config0])
    catch
        _:_ ->
            {skip, "Crypto did not start"}
    end;
init_per_group(Group, Config0)  when  Group == http_basic;
				      Group == http_limit;
				      Group == http_custom;
				      Group == http_basic_auth;
				      Group == http_auth_api;
				      Group == http_auth_api_dets;
				      Group == http_auth_api_mnesia;
				      Group == http_security;
				      Group == http_reload;
                                      Group == http_not_sup;
                                      Group == http_post;
                                      Group == http_default_type;
                                      Group == http_mime_type;
				      Group == http_mime_and_default_type;
                                      Group == http_mime_types
				      ->
    ok = start_apps(Group),
    init_httpd(Group, [{http_version, "HTTP/1.0"}, {type, ip_comm} | Config0]);
init_per_group(Group, Config) when Group == http_1_1_parallel;
                                   Group == http_1_1 ->
    [{http_version, "HTTP/1.1"} | Config];
init_per_group(Group, Config) when Group == http_1_0_parallel;
                                   Group == http_1_0 ->
    [{http_version, "HTTP/1.0"} | Config];
init_per_group(auth_api, Config) -> 
    [{auth_prefix, ""} | Config];
init_per_group(auth_api_dets, Config) -> 
    [{auth_prefix, "dets_"} | Config];
init_per_group(auth_api_mnesia, Config) ->
    start_mnesia(proplists:get_value(node, Config)),
    [{auth_prefix, "mnesia_"} | Config];
init_per_group(http_logging, Config) ->
    Config1 = [{http_version, "HTTP/1.1"} | Config],
    ServerRoot = proplists:get_value(server_root, Config1),
    Path = ServerRoot ++ "/httpd_log_transfer",
    [{transfer_log, Path} | Config1];
init_per_group(http_rel_path_script_alias = Group, Config) ->
    ok = start_apps(Group),
    init_httpd(Group, [{type, ip_comm},{http_version, "HTTP/1.1"}| Config]);
init_per_group(not_sup, Config) ->
    [{http_version, "HTTP/1.1"} | Config];
init_per_group(Group, Config) when Group == esi ->
    ok = start_apps(Group),
    Config;
init_per_group(_, Config) ->
    Config.

end_per_group(Group, _Config)  when  Group == http_basic;
				     Group == http_limit;
				     Group == http_basic_auth;
				     Group == http_auth_api;
				     Group == http_auth_api_dets;
				     Group == http_auth_api_mnesia;
				     Group == http_security;
				     Group == http_reload;
                                     Group == http_post;
                                     Group == http_default_type;
                                     Group == http_mime_type;
				     Group == http_mime_and_default_type;
                                     Group == http_mime_types;
                                     Group == esi
				     ->
    inets:stop();
end_per_group(Group, _Config) when  Group == https_basic;
				    Group == https_limit;
				    Group == https_basic_auth;
				    Group == https_auth_api;
				    Group == https_auth_api_dets;
				    Group == https_auth_api_mnesia;
				    Group == https_security;
				    Group == https_reload
				    ->
    ssl:stop(),
    inets:stop();

end_per_group(auth_api_mnesia, _) ->
    cleanup_mnesia();

end_per_group(_, _) ->
    ok.

%%--------------------------------------------------------------------
init_per_testcase(Case, Config) when Case == host; Case == trace ->
    ct:timetrap({seconds, 40}),
    Prop = proplists:get_value(tc_group_properties, Config),
    Name = proplists:get_value(name, Prop),
    Cb = case Name of
	     http_1_0 ->
		 httpd_1_0;
	     http_1_0_parallel ->
		 httpd_1_0;
	     http_1_1 ->
		 httpd_1_1;
	     http_1_1_parallel ->
		 httpd_1_1
	 end,
    dbg(
      Case,
      [{version_cb, Cb} | proplists:delete(version_cb, Config)],
      init);

init_per_testcase(range, Config) ->
    ct:timetrap({seconds, 20}),
    DocRoot = proplists:get_value(doc_root, Config),
    create_range_data(DocRoot),
    dbg(range, Config, init);

init_per_testcase(disk_log_internal, Config0) ->
    ok = start_apps(http_logging),
    Config1 = init_httpd(http_logging, [{type, ip_comm} | Config0]),
    ct:timetrap({seconds, 20}),
    dbg(disk_log_internal, Config1, init);

init_per_testcase(disk_log_exists, Config0) ->
    ServerRoot = proplists:get_value(server_root, Config0),
    Filename = ServerRoot ++ "/httpd_log_transfer",
    {ok, Log} = disk_log:open([{name, Filename}, {file, Filename},
            {repair, truncate}, {format, internal},
            {type, wrap}, {size, {1048576, 5}}]),
    ok = disk_log:log(Log, {bogus, node(), self()}),
    ok = disk_log:close(Log),
    ok = start_apps(http_logging),
    Config1 = init_httpd(http_logging, [{type, ip_comm} | Config0]),
    ct:timetrap({seconds, 20}),
    dbg(disk_log_internal, Config1, init);

init_per_testcase(disk_log_bad_size, Config0) ->
    ServerRoot = proplists:get_value(server_root, Config0),
    Filename = ServerRoot ++ "/httpd_log_transfer",
    {ok, Log} = disk_log:open([{name, Filename}, {file, Filename},
            {repair, truncate}, {format, internal},
            {type, wrap}, {size, {1048576, 5}}]),
    ok = disk_log:log(Log, {bogus, node(), self()}),
    ok = disk_log:close(Log),
    ok = file:delete(Filename ++ ".siz"),
    ok = start_apps(http_logging),
    Config1 = init_httpd(http_logging, [{type, ip_comm} | Config0]),
    ct:timetrap({seconds, 20}),
    dbg(disk_log_internal, Config1, init);

init_per_testcase(disk_log_bad_file, Config0) ->
    ServerRoot = proplists:get_value(server_root, Config0),
    Filename = ServerRoot ++ "/httpd_log_transfer",
    ok = file:write_file(Filename ++ ".1", <<>>),
    ok = start_apps(http_logging),
    Config1 = init_httpd(http_logging, [{type, ip_comm} | Config0]),
    ct:timetrap({seconds, 20}),
    dbg(disk_log_internal, Config1, init);

init_per_testcase(erl_script_timeout_default, Config) ->
    ct:timetrap({seconds, 60}),
    dbg(erl_script_timeout_default, Config, init);
init_per_testcase(medium = Case, Config) ->
    ct:timetrap({seconds, 150}),
    dbg(Case, Config, init);
init_per_testcase(Case, Config) ->
    ct:timetrap({seconds, 20}),
    dbg(Case, Config, init).

end_per_testcase(Case, Config) when
        Case == disk_log_internal;
        Case == disk_log_exists;
        Case == disk_log_bad_size;
        Case == disk_log_bad_file ->
    inets:stop(),
    dbg(Case, Config, 'end');

end_per_testcase(Case, Config) ->
    dbg(Case, Config, 'end').


dbg(Case, Config, Status) ->
    Cases = [],
    case lists:member(Case, Cases) of
	true ->
	    case Status of
		init ->
		    dbg:tracer(),
		    dbg:p(all, c),
		    dbg:tpl(httpd_example, cx),
		    dbg:tpl(mod_esi, generate_webpage, cx),
		    io:format("dbg: started~n"),
		    Config;
		'end' ->
		    io:format("dbg: stopped~n"),
		    dbg:stop(),
		    ok
	    end;
	false ->
	    case Status of
		init ->
		    Config;
		'end' ->
		    ok
	    end
    end.

%%-------------------------------------------------------------------------
%% Test cases starts here.
%%-------------------------------------------------------------------------

head() ->
    [{doc, "HTTP HEAD request for static page"}].

head(Config) when is_list(Config) -> 
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
                                       proplists:get_value(node, Config),
				       http_request("HEAD /index.html ", Version, Host),
				       [{statuscode, head_status(Version, 200)},
					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       proplists:get_value(node, Config),
				       http_request("HEAD /open/ ", Version, Host),
				       [{statuscode, head_status(Version, 403)},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]).

get() ->
    [{doc, "HTTP GET request for static page"}].

get(Config) when is_list(Config) -> 
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET /index.html ", Version, Host),
				       [{statuscode, 200},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET /open/ ", Version, Host),
				       [{statuscode, 403},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]),

    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config),
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET /.%252e/.%252e/.%252e/.%252e/.%252e/home/ ", Version, Host),
				       [{statuscode, 404},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]).

bad_dot_paths() ->
    [{doc, "Do not allow ..-paths to acesse files outside of doc root"}].
bad_dot_paths(Config) when is_list(Config) -> 
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    
    BadDotPath0 = "/..%2f..%2f...%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc/passwd ",
    BadDotPath1 = "/..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2f..%2fetc/passwd ",
    BadDotPath2 = "/%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd ",
    
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET " ++ BadDotPath0 , Version, Host),
				       [{statuscode, 404},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET " ++ BadDotPath1, Version, Host),
				       [{statuscode, 404},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config),
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET " ++ BadDotPath2, Version, Host),
				       [{statuscode, 404},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{header, "Server"},
					{version, Version}]).
    
basic_auth_1_1(Config) when is_list(Config) -> 
    basic_auth([{http_version, "HTTP/1.1"} | Config]).

basic_auth_1_0(Config) when is_list(Config) -> 
    basic_auth([{http_version, "HTTP/1.0"} | Config]).

basic_auth() ->
    [{doc, "Test Basic authentication with WWW-Authenticate header"}].

basic_auth(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    basic_auth_requiered(Config),
    %% Authentication OK! ["one:OnePassword" user first in user list]
    ok = auth_status(auth_request("/open/dummy.html", "one", "onePassword", Version, Host), Config, 
		     [{statuscode, 200}]),
    %% Authentication OK and a directory listing is supplied!
    %% ["Aladdin:open sesame" user second in user list]
    ok = auth_status(auth_request("/open/", "Aladdin", "AladdinPassword", Version, Host), Config, 
		     [{statuscode, 200}]),
     %% User correct but wrong password! ["one:one" user first in user list]
    ok = auth_status(auth_request("/open/dummy.html", "one", "one", Version, Host), Config, 
		     [{statuscode, 401},
		      {header, "WWW-Authenticate"}]),
    %% Make sure Authenticate header is received even the second time
    %% we try a incorrect password! Otherwise a browser client will hang!
    ok = auth_status(auth_request("/open/dummy.html", "one", "one", Version, Host), Config, 
		     [{statuscode, 401},
		      {header, "WWW-Authenticate"}]),
    %% Neither user or password correct! ["dummy:dummy"]
    ok = auth_status(auth_request("/open/dummy.html", "dummy", "dummy", Version, Host), Config, 
		     [{statuscode, 401}]),
    %% Nested secret/top_secret OK! ["Aladdin:open sesame"]
    ok = http_status(auth_request("/secret/top_secret/", "Aladdin", "AladdinPassword", Version, Host), 
		     Config, [{statuscode, 200}]),
    %% Authentication still required!
    basic_auth_requiered(Config).

verify_href_1_1(Config) when is_list(Config) ->
    verify_href([{http_version, "HTTP/1.1"} | Config]).

verify_href() ->
    [{doc, "Test generated hrefs (related to GH-4677), check that hrefs for dir listing work"}].

verify_href(Config) when is_list(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Go = fun(Path, User, Password, Opts) ->
                 ct:log("Navigating to ~p", [Path]),
                 auth_status(auth_request(Path, User, Password, Version, Host),
                             Config, Opts)
         end,
    {ok, Hrefs} = Go("/open/", "Aladdin", "AladdinPassword", [{statuscode, 200}, {fetch_hrefs, true}]),
    [ok = Go(H, "one", "onePassword", [{statuscode, 200}]) || H <- Hrefs],
    ok.

auth_api_1_1(Config) when is_list(Config) -> 
    auth_api([{http_version, "HTTP/1.1"} | Config]).

auth_api_1_0(Config) when is_list(Config) -> 
    auth_api([{http_version, "HTTP/1.0"} | Config]).

auth_api() ->
    [{doc, "Test mod_auth API"}].

auth_api(Config) when is_list(Config) -> 
    Prefix = proplists:get_value(auth_prefix, Config),
    do_auth_api(Prefix, Config).

do_auth_api(AuthPrefix, Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Port =  proplists:get_value(port, Config),
    Node = proplists:get_value(node, Config),
    ServerRoot = proplists:get_value(server_root, Config),
    ok = http_status("GET / ", Config,
 		     [{statuscode, 200}]),
    ok = auth_status(auth_request("/", "one", "WrongPassword", Version, Host), Config,
 		     [{statuscode, 200}]),

    %% Make sure Authenticate header is received even the second time
    %% we try a incorrect password! Otherwise a browser client will hang!
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/",
 				  "dummy", "WrongPassword", Version, Host), Config, 
 		     [{statuscode, 401},
 		      {header, "WWW-Authenticate"}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/", "dummy", "WrongPassword", 
 				  Version, Host), Config, [{statuscode, 401},	
 						  {header, "WWW-Authenticate"}]),
    
    %% Change the password to DummyPassword then try to add a user 
    %% Get an error and set it to NoPassword
    ok = update_password(Node, ServerRoot, Host, Port, AuthPrefix, 
			     "open", "NoPassword", "DummyPassword"),
    {error,bad_password} = 
 	add_user(Node, ServerRoot, Port, AuthPrefix, "open", "one", 
 		 "onePassword", []),
     ok = update_password(Node, ServerRoot, Host, Port, AuthPrefix, "open",
			  "DummyPassword", "NoPassword"),
  
    %% Test /*open, require user one Aladdin
    remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "open"),
    
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/",
     				  "one", "onePassword", Version, Host), Config,
		     [{statuscode, 401}]),
    
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/",
				  "two", "twoPassword", Version, Host), Config, 
		     [{statuscode, 401}]),
 
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/", 
				  "Aladdin", "onePassword", Version, Host),
		     Config, [{statuscode, 401}]),
    
    true = add_user(Node, ServerRoot, Port, AuthPrefix, "open", "one", 
		    "onePassword", []),
    true = add_user(Node, ServerRoot, Port, AuthPrefix, "open", "two", 
     		    "twoPassword", []),
    true = add_user(Node, ServerRoot, Port, AuthPrefix, "open", "Aladdin", 
		    "AladdinPassword", []),
    {ok, [_|_]} = list_users(Node, ServerRoot, Host, Port, 
      			     AuthPrefix, "open"),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/",
      				  "one", "WrongPassword", Version, Host), 
      		     Config, [{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/", 
      				  "one", "onePassword", Version, Host), 
      		     Config, [{statuscode, 200}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/", 
      				  "two", "twoPassword",  Version, Host), 
      		     Config,[{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/", 
      				  "Aladdin", "WrongPassword",  Version, Host), 
      		     Config,[{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "open/",  
				  "Aladdin", "AladdinPassword", Version, Host), 
		     Config, [{statuscode, 200}]),
    
    remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "open"),
    {ok, []} = list_users(Node, ServerRoot, Host, Port, 
			  AuthPrefix, "open"),
    
    %% Phase 2
      remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "secret"),
    {ok, []} = list_users(Node, ServerRoot, Host, Port, AuthPrefix,
			  "secret"),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/",
       				  "one", "onePassword", Version, Host), 
       		     Config, [{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/", 
				    "two", "twoPassword", Version, Host), 
		       Config, [{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/", 
      				  "three", "threePassword", Version, Host),
       		     Config, [{statuscode, 401}]),
    add_user(Node, ServerRoot, Port, AuthPrefix, "secret", "one",
      	     "onePassword", 
      	     []),
    add_user(Node, ServerRoot, Port, AuthPrefix, "secret", 
      	     "two", "twoPassword", []),
    add_user(Node, ServerRoot, Port, AuthPrefix, "secret", "Aladdin", 
	     "AladdinPassword",[]),
    add_group_member(Node, ServerRoot, Port, AuthPrefix, "secret", 
      		     "one", "group1"),
    add_group_member(Node, ServerRoot, Port, AuthPrefix, "secret", 
      		     "two", "group1"),
    add_group_member(Node, ServerRoot, Port, AuthPrefix,  
      			 "secret", "Aladdin", "group2"),
    {ok, Members} = list_group_members(Node, ServerRoot, Port, AuthPrefix, "secret", "group1"),
    true = lists:member("one", Members),
    true = lists:member("two", Members),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/",
      				  "one", "onePassword", Version, Host),
      		     Config, [{statuscode, 200}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/", 
				  "two", "twoPassword", Version, Host),
		       Config,[{statuscode, 200}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/",
       				  "Aladdin", "AladdinPassword", Version, Host),
       		     Config, [{statuscode, 200}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ "secret/",
       				  "three", "threePassword", Version, Host), 
       		     Config, [{statuscode, 401}]),
    remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "secret"),
    {ok, []} = list_users(Node, ServerRoot, Host, Port, 
       			  AuthPrefix, "secret"),
    remove_groups(Node, ServerRoot, Host, Port, AuthPrefix, "secret"),
    
    {ok, []} = list_groups(Node, ServerRoot, Host, Port, AuthPrefix, "secret"),
    
    %% Phase 3
    remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "secret/top_secret"),
    remove_groups(Node, ServerRoot, Host, Port, AuthPrefix, "secret/top_secret"),
    
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
      				      "secret/top_secret/",
      				  "three", "threePassword", Version, Host),
      		     Config, [{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
      				      "secret/top_secret/", "two", "twoPassword", Version, Host),
      		     Config, [{statuscode, 401}]),
     add_user(Node, ServerRoot, Port, AuthPrefix,
	      "secret/top_secret","three",
	      "threePassword",[]),
    add_user(Node, ServerRoot, Port, AuthPrefix, "secret/top_secret",
      	     "two","twoPassword", []),
    add_group_member(Node, ServerRoot, Port, AuthPrefix, "secret/top_secret", "three", "group3"),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
     				      "secret/top_secret/", "three", "threePassword",
     				  Version, Host), 
		     Config, [{statuscode, 200}]),
     ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
				       "secret/top_secret/", "two", "twoPassword", Version, Host),
		      Config, [{statuscode, 401}]),
    add_group_member(Node, ServerRoot, Port, AuthPrefix, "secret/top_secret", "two", "group3"),
     ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
				       "secret/top_secret/",
				   "two", "twoPassword", Version, Host),
		      Config, [{statuscode, 200}]),
     remove_users(Node, ServerRoot, Host, Port, AuthPrefix, "secret/top_secret"),
    {ok, []} = list_users(Node, ServerRoot, Host, Port, 
     			  AuthPrefix, "secret/top_secret"),
    remove_groups(Node, ServerRoot, Host, Port, AuthPrefix, "secret/top_secret"),
     {ok, []} = list_groups(Node, ServerRoot, Host, Port, AuthPrefix,  "secret/top_secret"),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
       				      "secret/top_secret/", "two", "twoPassword", Version, Host), 
		     Config, [{statuscode, 401}]),
    ok = auth_status(auth_request("/" ++ AuthPrefix ++ 
       				      "secret/top_secret/","three", "threePassword", Version, Host),
       		     Config, [{statuscde, 401}]).
%%-------------------------------------------------------------------------
ipv6() ->
    [{require, ipv6_hosts},
     {doc,"Test ipv6."}].
ipv6(Config) when is_list(Config) ->
    {ok, Hostname0} = inet:gethostname(),
     case lists:member(list_to_atom(Hostname0), ct:get_config(ipv6_hosts)) of
	 true ->
	     Version = proplists:get_value(http_version, Config),
	     Host = proplists:get_value(host, Config),
	     URI = http_request("GET / ", Version, Host),
	     httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
 					  proplists:get_value(port, Config), [inet6], 
					   proplists:get_value(code, Config), 
					   URI, 
					   [{statuscode, 200}, {version, Version}]);
	 false ->
	     {skip, "Host does not support IPv6"}
     end.

%%-------------------------------------------------------------------------
same_file_name_dir_name() ->
    [{doc,"Test that URI path that has a filename in it is not interpreted as the file"}].
same_file_name_dir_name(Config) when is_list(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    ok = httpd_test_lib:verify_request(Type, Host,
                                       proplists:get_value(port, Config),
                                       transport_opts(Type, Config),
                                       proplists:get_value(node, Config),
                                       http_request("GET /index.html/foo.html ", Version, Host),
                                       [{statuscode, 404},
                                        {version, Version}]).

%%-------------------------------------------------------------------------
chunked_post() ->
    [{doc,"Test option max_client_body_chunk"}].
chunked_post(Config) when is_list(Config) ->
    ok = http_status("POST /cgi-bin/erl/httpd_example:post_chunked ",  
                       {"Content-Length:833 \r\n",
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
                        "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"},
                     [{http_version, "HTTP/1.1"} |Config], 
                     [{statuscode, 200}]),
    ok = http_status("POST /cgi-bin/erl/httpd_example:post_chunked ",  
                     {"Content-Length:2 \r\n",
                        "ZZ"
                     },
                     [{http_version, "HTTP/1.1"} |Config], 
                     [{statuscode, 200}]).

chunked_chunked_encoded_post() ->
    [{doc,"Test option max_client_body_chunk with chunked client encoding"}].
chunked_chunked_encoded_post(Config) when is_list(Config) ->
    Chunk = http_chunk:encode("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"),
    LastChunk = http_chunk:encode_last(),
    Chunks = lists:duplicate(10000, Chunk),
    ok = http_status("POST /cgi-bin/erl/httpd_example:post_chunked ",  
                     {"Transfer-Encoding:chunked \r\n",
                      [Chunks | LastChunk]},
                     [{http_version, "HTTP/1.1"} | Config], 
                     [{statuscode, 200}]).

%%-------------------------------------------------------------------------
post_204() ->
    [{doc,"Test that 204 responses are not chunk encoded"}].
post_204(Config) ->
    Host = proplists:get_value(host, Config),
    Port =  proplists:get_value(port, Config),
    SockType = proplists:get_value(type, Config),
    TranspOpts = transport_opts(SockType, Config),
    Request = "POST /cgi-bin/erl/httpd_example:post_204 ",

    try inets_test_lib:connect_bin(SockType, Host, Port, TranspOpts) of
	{ok, Socket} ->
            RequestStr = http_request(Request, "HTTP/1.1", Host),
	    ok = inets_test_lib:send(SockType, Socket, RequestStr),
            receive
                {tcp, Socket, Data} ->
                    case binary:match(Data, <<"chunked">>,[]) of
                        nomatch ->
                            ok;
                        {_, _} ->
                            ct:fail("Chunked encoding detected.")
                    end
            after 2000 ->
                    ct:fail(connection_timed_out)
            end;
	ConnectError ->
	    ct:fail({connect_error, ConnectError,
		     [SockType, Host, Port, TranspOpts]})
    catch
	T:E:Stk ->
	    ct:fail({connect_failure,
		     [{type,       T},
		      {error,      E},
		      {stacktrace, Stk},
		      {args,       [SockType, Host, Port, TranspOpts]}]})
    end.

%%-------------------------------------------------------------------------
host() ->
    [{doc, "Test host header"}].

host(Config) when is_list(Config) -> 
    Cb = proplists:get_value(version_cb, Config),
    Cb:host(proplists:get_value(type, Config), proplists:get_value(port, Config), 
	    proplists:get_value(host, Config), proplists:get_value(node, Config)).
%%-------------------------------------------------------------------------
chunked() ->
    [{doc, "Check that the server accepts chunked requests."}].

chunked(Config) when is_list(Config) ->
    httpd_1_1:chunked(proplists:get_value(type, Config), proplists:get_value(port, Config), 
		      proplists:get_value(host, Config), proplists:get_value(node, Config)).
%%-------------------------------------------------------------------------
expect() ->   
    [{doc, "Check that the server handles request with the expect header "
      "field appropriate"}].
expect(Config) when is_list(Config) ->
    httpd_1_1:expect(proplists:get_value(type, Config), proplists:get_value(port, Config), 
		     proplists:get_value(host, Config), proplists:get_value(node, Config)).
%%-------------------------------------------------------------------------
max_clients_1_1() ->
    [{doc, "Test max clients limit"}].

max_clients_1_1(Config) when is_list(Config) -> 
    do_max_clients([{http_version, "HTTP/1.1"} | Config]).

%%-------------------------------------------------------------------------
put_not_sup() ->
    [{doc, "Test unhandled request"}].

put_not_sup(Config) when is_list(Config) ->
    ok = http_status("PUT /index.html ",
                     {"Content-Length:100 \r\n",
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"},
		     Config, [{statuscode, 501}]).
%%-------------------------------------------------------------------------
esi() ->
    [{doc, "Test mod_esi"}].

esi(Config) when is_list(Config) -> 
    ok = http_status("GET /cgi-bin/erl/httpd_example ", 
		     Config, [{statuscode, 400}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:get ",
		     Config, [{statuscode, 200}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:"
		     "get?input=4711 ", Config,
		     [{statuscode, 200}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:post ",
		     Config, [{statuscode, 200}]),
    ok = http_status("GET /cgi-bin/erl/not_allowed:post ",
		     Config, [{statuscode, 403}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:undef ",
		     Config, [{statuscode, 404}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example/yahoo ",
		     Config, [{statuscode, 302}]),
    %% Check "ErlScriptNoCache" directive (default: false)
    ok = http_status("GET /cgi-bin/erl/httpd_example:get ",
		     Config, [{statuscode, 200},
		      {no_header, "cache-control"}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:peer ",
	  	     Config, [{statuscode, 200},
                              {header, "peer-cert-exist", peer(Config)}]),
    ok = http_status("GET /cgi-bin/erl/httpd_example:new_status_and_location ",
                     Config, [{statuscode, 201},
                              {header, "location"}]).
    
%%-------------------------------------------------------------------------
esi_put() ->
    [{doc, "Test mod_esi PUT"}].

esi_put(Config) when is_list(Config) ->
    ok = http_status("PUT /cgi-bin/erl/httpd_example/put/123342234123 ",
		     Config, [{statuscode, 200}]).

%%-------------------------------------------------------------------------
esi_patch() ->
    [{doc, "Test mod_esi PATCH"}].

esi_patch(Config) when is_list(Config) ->
    ok = http_status("PATCH /cgi-bin/erl/httpd_example/patch/1234567890 ",
		     Config, [{statuscode, 200}]).

%%-------------------------------------------------------------------------
esi_post() ->
    [{doc, "Test mod_esi POST"}].

esi_post(Config) when is_list(Config) ->
    Chunk = "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ",
    Data = lists:duplicate(10000, Chunk),
    Length = lists:flatlength(Data),
    ok = http_status("POST /cgi-bin/erl/httpd_example/post ",
                     {"Content-Length:" ++ integer_to_list(Length) ++ "\r\n",
                      Data},
                     [{http_version, "HTTP/1.1"} |Config], 
                     [{statuscode, 200}]).

%%-------------------------------------------------------------------------
mod_esi_chunk_timeout(Config) when is_list(Config) -> 
    ok = httpd_1_1:mod_esi_chunk_timeout(proplists:get_value(type, Config), 
					 proplists:get_value(port, Config),
					 proplists:get_value(host, Config),
					 proplists:get_value(node, Config)).
%%-------------------------------------------------------------------------
esi_propagate(Config) when is_list(Config) ->
    register(propagate_test, self()),
    ok = http_status("GET /cgi-bin/erl/httpd_example:new_status_and_location ",
                  Config, [{statuscode, 201}]),
    receive
        {status, 201} ->
            ok;
        Err ->
            ct:fail(Err)
    end.        
%%-------------------------------------------------------------------------
esi_atom_leak() ->
    [{doc, "Test mod_esi for atom leakage - verify module, function names and HTTP headers"}].

esi_atom_leak(Config) when is_list(Config) ->
    NumberStrings = [integer_to_list(N) || N <- lists:seq(1, 10)],

    NotExistingModule =
        ["GET /cgi-bin/erl/not_existing_" ++ S ++":get " || S <- NumberStrings],
    %% check atom count after first HTTP call, to ignore count increase upon initial module loading
    GetFun = fun(Url, HeadersAndBody, Expected) ->
                     ok = http_status(Url, HeadersAndBody, Config, Expected),
                     erlang:system_info(atom_count)
             end,
    AtomCount1 = [GetFun(U, {"", ""}, [{statuscode, 404}]) || U <- NotExistingModule],
    IsStable = fun(L) -> lists:max(L) == lists:min(L) end,
    true = IsStable(AtomCount1),

    NotExistingFunction =
        ["GET /cgi-bin/erl/httpd_example:not_existing" ++ S ++ " "
         || S <- NumberStrings],
    AtomCount2 = [GetFun(U, {"", ""}, [{statuscode, 404}]) || U <- NotExistingFunction],
    true = IsStable(AtomCount2),

    NotExistingHdr =
        [{"NotExistingHeader_" ++ S ++ ":100 \r\n", ""} || S <- NumberStrings],
    AtomCount3 = [GetFun("GET /cgi-bin/erl/httpd_example:get ", H, [{statuscode, 200}])
                  || H <- NotExistingHdr],
    true = IsStable(AtomCount3).

%%-------------------------------------------------------------------------
esi_headers() ->
    [{doc, "Test mod_esi HTTP headers support"}].

esi_headers(Config) when is_list(Config) ->
    ok = http_status("GET /cgi-bin/erl/httpd_example:get_reply_headers ",
                     {"Accept-Encoding: gzip \r\nNotExistingHeader_1: 100 \r\n", ""},
                     Config, [{statuscode, 200}, {header, "notexistingheader_1", "100"},
                              {header, "accept-encoding", "gzip"}]).

%%-------------------------------------------------------------------------
cgi() ->
    [{doc, "Test mod_cgi"}].

cgi(Config) when is_list(Config) -> 
    {Script, Script2, Script3} =
	case os:type() of
	    {win32, _} ->
		{"printenv.bat", "printenv.sh", "cgi_echo.exe"};
	    _ ->
		{"printenv.sh", "printenv.bat", "cgi_echo"}
	end,

     %%The length (> 100) is intentional
     ok = http_status("POST /cgi-bin/" ++ Script3 ++ " ", 
     		     {"Content-Length:100 \r\n",
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
     		      "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"}, 
		      Config,
     		     [{statuscode, 200},
     		      {header, "content-type", "text/plain"}]),
    
    ok = http_status("GET /cgi-bin/"++ Script ++ " ", Config, [{statuscode, 200}]),

    ok = http_status("GET /cgi-bin/not_there ", Config, 
		     [{statuscode, 404}, {statuscode, 500}]),
    
    ok = http_status("GET /cgi-bin/"++ Script ++ "?Nisse:kkk?sss/lll ", 
     		     Config,
     		     [{statuscode, 200}]),
    
    ok = http_status("POST /cgi-bin/"++ Script  ++ " ", Config,
		     [{statuscode, 200}]),
    
    ok = http_status("GET /htbin/"++ Script ++ " ",  Config,
		     [{statuscode, 200}]),
    
    ok = http_status("GET /htbin/not_there ", Config,
		     [{statuscode, 404},{statuscode, 500}]),
    
    ok = http_status("GET /htbin/"++ Script ++ "?Nisse:kkk?sss/lll ", Config, 
     		     [{statuscode, 200}]),
    
    ok = http_status("POST /htbin/"++ Script ++ " ",   Config,
		     [{statuscode, 200}]),
    
    ok = http_status("POST /htbin/"++ Script ++ " ",  Config,
		     [{statuscode, 200}]),
    
    %% Execute an existing, but bad CGI script..
    ok = http_status("POST /htbin/"++ Script2 ++ " ",  Config, 
		     [{statuscode, 404}]),
    
    ok = http_status("POST /cgi-bin/"++ Script2 ++ " ", Config,
		     [{statuscode, 404}]),
    
    %% Check "ScriptNoCache" directive (default: false)
    ok = http_status("GET /cgi-bin/" ++ Script ++ " ", Config,
		     [{statuscode, 200},
		      {no_header, "cache-control"}]).
%%-------------------------------------------------------------------------
cgi_chunked_encoding_test() ->  
    [{doc, "Test chunked encoding together with mod_cgi "}].
cgi_chunked_encoding_test(Config) when is_list(Config) ->
    Host = proplists:get_value(host, Config),
    Script =
	case os:type() of
	    {win32, _} ->
		"/cgi-bin/printenv.bat";
	    _ ->
		"/cgi-bin/printenv.sh"
	end,
    Requests = 
	["GET " ++ Script ++ " HTTP/1.1\r\nHost:"++ Host ++"\r\n\r\n",
	 "GET /cgi-bin/erl/httpd_example/newformat  HTTP/1.1\r\nHost:"
	 ++ Host ++"\r\n\r\n"],
    httpd_1_1:mod_cgi_chunked_encoding_test(proplists:get_value(type, Config), proplists:get_value(port, Config),
					    Host,
					    proplists:get_value(node, Config),
					    Requests).
%%-------------------------------------------------------------------------
default_type() ->
    [{doc, "Test default_type"}].

default_type(Config) when is_list(Config) ->
    TestURIs200 = [
                   {"GET /file_without_extension ", 200, "text/html"},
                   {"GET /file.with_nonstandard_extension ", 200, "text/html"}
                  ],
    Test200 =
        fun({Request, ResultCode, ContentType}) ->
                ct:log("Request: ~s Expecting: ~p ~s",
                     [Request, ResultCode, ContentType]),
                ok = http_status(Request, Config,
                                 [{statuscode, ResultCode},
                                  {header, "Content-Type", ContentType},
                                  {header, "Server"},
                                  {header, "Date"}])
        end,
    [Test200(T) || T <- TestURIs200],
    ok.

%%-------------------------------------------------------------------------
mime_type() ->
    [{doc, "Test mime_type"}].

mime_type(Config) when is_list(Config) ->
    TestURIs200 = [
                   {"GET /file_without_extension ", 200, "text/html"},
                   {"GET /file.with_nonstandard_extension ", 200, "text/html"}
                  ],
    Test200 =
        fun({Request, ResultCode, ContentType}) ->
                ct:log("Request: ~s Expecting: ~p ~s",
                     [Request, ResultCode, ContentType]),
                ok = http_status(Request, Config,
                                 [{statuscode, ResultCode},
                                  {header, "Content-Type", ContentType},
                                  {header, "Server"},
                                  {header, "Date"}])
        end,
    [Test200(T) || T <- TestURIs200],
    ok.

%%-------------------------------------------------------------------------
mime_and_default_type() ->
    [{doc, "Test that mime_type takes precedence over default_type"}].

mime_and_default_type(Config) when is_list(Config) ->
    TestURIs200 = [
                   {"GET /file_without_extension ", 200, "text/html"},
                   {"GET /file.with_nonstandard_extension ", 200, "text/html"}
                  ],
    Test200 =
        fun({Request, ResultCode, ContentType}) ->
                ct:log("Request: ~s Expecting: ~p ~s",
                     [Request, ResultCode, ContentType]),
                ok = http_status(Request, Config,
                                 [{statuscode, ResultCode},
                                  {header, "Content-Type", ContentType},
                                  {header, "Server"},
                                  {header, "Date"}])
        end,
    [Test200(T) || T <- TestURIs200],
    ok.

%%-------------------------------------------------------------------------
alias_1_1() ->
    [{doc, "Test mod_alias"}].

alias_1_1(Config) when is_list(Config) ->
    alias([{http_version, "HTTP/1.1"} | Config]).

alias_1_0() ->
    [{doc, "Test mod_alias"}].
  
alias_1_0(Config) when is_list(Config) ->
    alias([{http_version, "HTTP/1.0"} | Config]).

alias() ->
    [{doc, "Test mod_alias"}].

alias(Config) when is_list(Config) ->
    Cgi = case os:type() of
        {win32, _} ->
            "printenv.bat";
        _ ->
            "printenv.sh"
    end,
    TestURIs200 = [
                   {"GET /pics/icon.sheet.gif ", 200, "image/gif"},
                   {"GET /pictures/icon.sheet.gif ", 200, "image/gif"},
                   {"GET / ", 200, "text/html"},
                   {"GET /misc/ ", 200, "text/html"},
                   {"GET /cgi-bin/" ++ Cgi ++ " ", 200, "text/html"},
                   {"GET /cgi-UNWANTED-bin/" ++ Cgi ++ " ", 200, "text/html"}
                  ],
    Test200 =
        fun({Request, ResultCode, ContentType}) ->
                ct:log("Request: ~s Expecting: ~p ~s",
                     [Request, ResultCode, ContentType]),
                ok = http_status(Request, Config,
                                 [{statuscode, ResultCode},
                                  {header, "Content-Type", ContentType},
                                  {header, "Server"},
                                  {header, "Date"}])
        end,
    [Test200(T) || T <- TestURIs200],
    TestURIs301 =
        [
         %% Check redirection if trailing slash is missing.
         {"GET /misc ", 301, "text/html", "&#47;misc&#47;$"},
         %% slash character expected after path(misc) not query component
         {"GET /misc?test=test ", 301, "text/html", "&#47;misc&#47;\\?test=test$"}
        ],
    Test301 =
        fun({Request, ResultCode, ContentType, TargetLinkRegexp}) ->
                ct:log("Request: ~s Expecting: ~p ~s RE: ~s",
                     [Request, ResultCode, ContentType, TargetLinkRegexp]),
                {ok, [RedirectLink]} =
                    http_status(Request, Config,
                                [{statuscode, ResultCode},
                                 {header, "Content-Type", ContentType},
                                 {header, "Server"},
                                 {header, "Date"},
                                 {fetch_hrefs, true}]),
                ReResult = re:run(RedirectLink, TargetLinkRegexp),
                ct:log("RedirectLink = ~p", [RedirectLink]),
                ?assertMatch({match, _}, ReResult)
              end,
    [Test301(T) || T <- TestURIs301],
    ok.

%%-------------------------------------------------------------------------
actions() ->
    [{doc, "Test mod_actions"}].

actions(Config) when is_list(Config) -> 
    ok = http_status("GET /", Config, [{statuscode, 200}]).

%%-------------------------------------------------------------------------
range() ->
    [{doc, "Test Range header"}].

range(Config) when is_list(Config) -> 
    httpd_1_1:range(proplists:get_value(type, Config), proplists:get_value(port, Config), 
		    proplists:get_value(host, Config), proplists:get_value(node, Config)).

%%-------------------------------------------------------------------------
if_modified_since() ->
    [{doc, "Test If-Modified-Since header"}].

if_modified_since(Config) when is_list(Config) -> 
    httpd_1_1:if_test(proplists:get_value(type, Config), proplists:get_value(port, Config), 
		      proplists:get_value(host, Config), proplists:get_value(node, Config),
		      proplists:get_value(doc_root, Config)).
%%-------------------------------------------------------------------------
trace() ->
    [{doc, "Test TRACE method"}].

trace(Config) when is_list(Config) ->
    Cb = proplists:get_value(version_cb, Config),
    Cb:trace(proplists:get_value(type, Config), proplists:get_value(port, Config), 
	     proplists:get_value(host, Config), proplists:get_value(node, Config)).
%%-------------------------------------------------------------------------
light() ->
    [{doc, "Test light load"}].
light(Config) when is_list(Config) ->
    httpd_load:load_test(proplists:get_value(type, Config), proplists:get_value(port, Config), proplists:get_value(host, Config), 
			 proplists:get_value(node, Config), 10).
%%-------------------------------------------------------------------------
medium() ->
    [{doc, "Test  medium load"}].
medium(Config) when is_list(Config) ->
    httpd_load:load_test(proplists:get_value(type, Config), proplists:get_value(port, Config), proplists:get_value(host, Config), 
			 proplists:get_value(node, Config), 100).
%%-------------------------------------------------------------------------
heavy() ->
    [{doc, "Test heavy load"}].
heavy(Config) when is_list(Config) ->
    httpd_load:load_test(proplists:get_value(type, Config), proplists:get_value(port, Config), proplists:get_value(host, Config), 
			 proplists:get_value(node, Config),
			 1000).
%%-------------------------------------------------------------------------
content_length() ->
    ["Tests that content-length is correct OTP-5775"].
content_length(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config), proplists:get_value(node, Config),
				       http_request("GET /cgi-bin/erl/httpd_example:get_bin ", 
						    Version, Host), 
				       [{statuscode, 200},
					{content_length, 274},
					{version, Version}]).

%-------------------------------------------------------------------------
filename_too_long() ->
    [{doc, "Tests what happens if supplied filename exceeds os-limit of filename characters."}].
filename_too_long(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    TooLongFileName = lists:duplicate(257, $F),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config), proplists:get_value(node, Config),
				       http_request("GET /" ++ TooLongFileName ++ " ", Version, Host),
				       [{statuscode, 404},
					{version, Version}]).

%%-------------------------------------------------------------------------
bad_hex() ->
    [{doc, "Tests that a URI with a bad hexadecimal code is handled OTP-6003"}].
bad_hex(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config), proplists:get_value(node, Config),
				       http_request("GET http://www.erlang.org/%skalle ",
						    Version, Host),
				       [{statuscode, 400},
					{version, Version}]).
%%-------------------------------------------------------------------------
missing_CR() ->
     [{doc, "Tests missing CR in delimiter OTP-7304"}].
missing_CR(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host =  proplists:get_value(host, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host,
				       proplists:get_value(port, Config), proplists:get_value(node, Config),
				       http_request_missing_CR("GET /index.html ", Version, Host),
				       [{statuscode, 200},
					{version, Version}]).

%%-------------------------------------------------------------------------
customize() ->
    [{doc, "Test filtering of headers with custom callback"}].

customize(Config) when is_list(Config) -> 
    Version = "HTTP/1.1",
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET /index.html ", Version, Host),
				       [{statuscode, 200},
					{header, "Content-Type", "text/html"},
					{header, "Date"},
					{no_header, "Server"},
					{version, Version}]).

%%-------------------------------------------------------------------------
add_default() ->
    [{doc, "Test adding default header with custom callback"}].

add_default(Config) when is_list(Config) -> 
    Version = "HTTP/1.1",
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    ok = httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				       proplists:get_value(port, Config),  
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       http_request("GET /index.html ", Version, Host),
				       [{statuscode, 200},
					{header, "Content-Type", "text/html"},
					{header, "Date", "Override-date"},
					{header, "X-Frame-Options"},
					{version, Version}]).

%%-------------------------------------------------------------------------
max_header() ->
    [{doc, "Denial Of Service (DOS) attack, prevented by max_header"}].
max_header(Config) when is_list(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host =  proplists:get_value(host, Config),
    case Version of
 	"HTTP/0.9" ->
 	    {skip, not_implemented};
 	_ ->
 	    dos_hostname(proplists:get_value(type, Config), proplists:get_value(port, Config), Host, 
 			 proplists:get_value(node, Config), Version, ?MAX_HEADER_SIZE)
    end.

%%-------------------------------------------------------------------------
max_content_length() ->
    [{doc, "Denial Of Service (DOS) attack, prevented by max_content_length"}].
max_content_length(Config) when is_list(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host =  proplists:get_value(host, Config),
    garbage_content_length(proplists:get_value(type, Config), proplists:get_value(port, Config), Host, 
			   proplists:get_value(node, Config), Version).

%%-------------------------------------------------------------------------
ignore_invalid_header() ->
    [{doc, "RFC 7230 - 3.2.4 ... No whitespace is allowed between the header field-name and colon"}].
ignore_invalid_header(Config) when is_list(Config) ->
     Host =  proplists:get_value(host, Config),
     Port =  proplists:get_value(port, Config),
    {Url, Header, Opts} =
        case proplists:get_value(type, Config) of
            ip_comm ->
                {"http://"  ++ Host ++  ":" ++ integer_to_list(Port) ++ "/cgi-bin/erl/httpd_example:ignore_invalid_header",
                 [{"Host", "localhost"},{"Te", ""}, {"Content-Length ", "0"}], []};
            ssl ->
                Conf = proplists:get_value(client_config, proplists:get_value(ssl_conf, Config)),
                {"https://"  ++ Host ++  ":" ++ integer_to_list(Port) ++ "/cgi-bin/erl/httpd_example:ignore_invalid_header",
                 [{"Host", "localhost"},{"Te", ""}, {"Content-Length ", "0"}], [{ssl, [{verify, verify_none} | Conf]}]}
        end,
    {ok,{{_,204,_}, _, _}}
        = httpc:request(get, {Url, Header}, [{timeout, 45000} | Opts], [{headers_as_is, true}]).

%%-------------------------------------------------------------------------
security_1_1(Config) when is_list(Config) -> 
    security([{http_version, "HTTP/1.1"} | Config]).

security_1_0(Config) when is_list(Config) -> 
    security([{http_version, "HTTP/1.0"} | Config]).

security() ->
    ["Test mod_security"].
security(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Port =  proplists:get_value(port, Config),
    Node = proplists:get_value(node, Config),
    ServerRoot = proplists:get_value(server_root, Config),

    yes = global:register_name(mod_security_test, self()),   % Receive events

    OpenDir = filename:join([ServerRoot, "htdocs", "open"]),

    %% Test blocking / unblocking of users.

    %% /open, require user one Aladdin
    remove_users(Node, ServerRoot, Host, Port, "", "open"),

    ok = auth_status(auth_request("/open/",
     				  "one", "onePassword", Version, Host), Config,
		     [{statuscode, 401}]),
    
    receive_security_event({event, auth_fail, Port, OpenDir,
			    [{user, "one"}, {password, "onePassword"}]},
			   Node, Port),
    
     ok = auth_status(auth_request("/open/",
				  "two", "twoPassword", Version, Host), Config, 
		     [{statuscode, 401}]),
 
    receive_security_event({event, auth_fail, Port, OpenDir,
			    [{user, "two"}, {password, "twoPassword"}]},
			   Node, Port),

    ok = auth_status(auth_request("/open/", 
				  "Aladdin", "AladdinPassword", Version, Host),
		     Config, [{statuscode, 401}]),
    
    receive_security_event({event, auth_fail, Port, OpenDir,
			    [{user, "Aladdin"},
			     {password, "AladdinPassword"}]},
			   Node, Port),

    add_user(Node, ServerRoot, Port, "", "open", "one", "onePassword", []),
    add_user(Node, ServerRoot, Port, "", "open", "two", "twoPassword", []),

    ok = auth_status(auth_request("/open/", "one", "WrongPassword",  Version, Host), Config, 
		     [{statuscode, 401}]),
    
    receive_security_event({event, auth_fail, Port, OpenDir,
			    [{user, "one"}, {password, "WrongPassword"}]},
			   Node, Port),

    ok = auth_status(auth_request("/open/", "one", "WrongPassword",  Version, Host), Config, 
				  [{statuscode, 401}]),
    
    receive_security_event({event, auth_fail, Port, OpenDir,
			    [{user, "one"}, {password, "WrongPassword"}]},
			   Node, Port),
    receive_security_event({event, user_block, Port, OpenDir,
			    [{user, "one"}]}, Node, Port),
    
    global:unregister_name(mod_security_test),   % No more events.
    
    ok = auth_status(auth_request("/open/", "one", "WrongPassword",  Version, Host), Config, 
				  [{statuscode, 401}]),
    
    %% User "one" should be blocked now..    
    case list_blocked_users(Node, Port) of
	[{"one",_, Port, OpenDir,_}] ->
	    ok;
	Blocked ->
	    ct:fail({unexpected_blocked, Blocked})
    end,

    [{"one",_, Port, OpenDir,_}] = list_blocked_users(Node, Port, OpenDir),

    true = unblock_user(Node, "one", Port, OpenDir),
    %% User "one" should not be blocked any more.

    [] = list_blocked_users(Node, Port),

    ok = auth_status(auth_request("/open/", "one", "onePassword", Version, Host), Config, 
		     [{statuscode, 200}]),

    %% Test list_auth_users & auth_timeout

    ["one"] = list_auth_users(Node, Port),

    ok = auth_status(auth_request("/open/", "two", "onePassword", Version, Host), Config, 
		     [{statuscode, 401}]),

    ["one"] = list_auth_users(Node, Port),

   
    ["one"] = list_auth_users(Node, Port, OpenDir),

   
    ok = auth_status(auth_request("/open/", "two", "twoPassword",  Version, Host), Config, 
				  [{statuscode, 401}]),

    ["one"] = list_auth_users(Node, Port),

  
    ["one"] = list_auth_users(Node, Port, OpenDir),

    %% Wait for successful auth to timeout.
    ct:sleep(?AUTH_TIMEOUT*1001),  

    [] = list_auth_users(Node, Port),

    [] = list_auth_users(Node, Port, OpenDir),

    %% "two" is blocked.

    true = unblock_user(Node, "two", Port, OpenDir),


    %% Test explicit blocking. Block user 'two'.

    [] = list_blocked_users(Node,Port,OpenDir),

    true = block_user(Node, "two", Port, OpenDir, 10),

    ok = auth_status(auth_request("/open/", "two", "twoPassword",  Version, Host), Config, 
		     [{statuscode, 401}]),
    
    true = unblock_user(Node, "two", Port, OpenDir).

%%-------------------------------------------------------------------------

disk_log_internal() ->
    ["Test mod_disk_log"].

disk_log_internal(Config) ->
    Version = proplists:get_value(http_version, Config),
    Request = "GET /" ++ integer_to_list(rand:uniform(1000000)) ++ " ",
    ok = http_status(Request, Config, [{statuscode, 404}]),
    Log = proplists:get_value(transfer_log, Config),
    Match = list_to_binary(Request ++ Version),
    disk_log_internal1(Log, Match, disk_log:chunk(Log, start)).
disk_log_internal1(_, _, eof) ->
    ct:fail(eof);
disk_log_internal1(Log, Match, {Cont, [H | T]}) ->
    case binary:match(H, Match) of
        nomatch ->
            disk_log_internal1(Log, Match, {Cont, T});
        _ ->
            ok
    end;
disk_log_internal1(Log, Match, {Cont, []}) ->
    disk_log_internal1(Log, Match, disk_log:chunk(Log, Cont)).

disk_log_exists() ->
    ["Test mod_disk_log with existing logs"].

disk_log_exists(Config) ->
    Log = proplists:get_value(transfer_log, Config),
    Self = self(),
    Node = node(),
    Log = proplists:get_value(transfer_log, Config),
    {_, [{bogus, Node, Self} | _]} = disk_log:chunk(Log, start).

disk_log_bad_size() ->
    ["Test mod_disk_log with existing log, missing .siz"].

disk_log_bad_size(Config) ->
    Log = proplists:get_value(transfer_log, Config),
    Self = self(),
    Node = node(),
    Log = proplists:get_value(transfer_log, Config),
    {_, [{bogus, Node, Self} | _]} = disk_log:chunk(Log, start).

disk_log_bad_file() ->
    ["Test mod_disk_log with bad file"].

disk_log_bad_file(Config) ->
    Log = proplists:get_value(transfer_log, Config),
    Version = proplists:get_value(http_version, Config),
    Request = "GET /" ++ integer_to_list(rand:uniform(1000000)) ++ " ",
    ok = http_status(Request, Config, [{statuscode, 404}]),
    Log = proplists:get_value(transfer_log, Config),
    Match = list_to_binary(Request ++ Version),
    {_, [H | _]} = disk_log:chunk(Log, start),
    {_, _} = binary:match(H, Match).

%%-------------------------------------------------------------------------
non_disturbing_reconfiger_dies(Config) when is_list(Config) -> 
    do_reconfiger_dies([{http_version, "HTTP/1.1"} | Config], non_disturbing).
disturbing_reconfiger_dies(Config) when is_list(Config) -> 
    do_reconfiger_dies([{http_version, "HTTP/1.1"} | Config], disturbing).

do_reconfiger_dies(Config, DisturbingType) ->
    Server =  proplists:get_value(server_pid, Config),
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    Type = proplists:get_value(type, Config),

    HttpdConfig = httpd:info(Server), 
    BlockRequest = http_request("GET /cgi-bin/erl/httpd_example:delay ", Version, Host),
    {ok, Socket} = inets_test_lib:connect_bin(Type, Host, Port, transport_opts(Type, Config)),
    inets_test_lib:send(Type, Socket, BlockRequest),
    ct:sleep(100), %% Avoid possible timing issues
    Pid = spawn(fun() -> httpd:reload_config([{server_name, "httpd_kill_" ++ Version}, 
                                              {port, Port}|
                                              proplists:delete(server_name, HttpdConfig)], DisturbingType) 
                end),
    
    monitor(process, Pid),
    exit(Pid, kill),
    receive 
        {'DOWN', _, _, _, _} ->
            ok
    end,
    inets_test_lib:close(Type, Socket),
    [{server_name, "httpd_test"}] =  httpd:info(Server, [server_name]).
%%-------------------------------------------------------------------------
disturbing_1_1(Config) when is_list(Config) -> 
    disturbing([{http_version, "HTTP/1.1"} | Config]).

disturbing_1_0(Config) when is_list(Config) -> 
    disturbing([{http_version, "HTTP/1.0"} | Config]).

disturbing(Config) when is_list(Config)->
    LogWatcher = start_log_watcher(),
    Server =  proplists:get_value(server_pid, Config),
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    Type = proplists:get_value(type, Config),
    HttpdConfig = httpd:info(Server), 

    BlockRequest = http_request("GET /cgi-bin/erl/httpd_example:delay ", Version,  Host),
    {ok, Socket} = inets_test_lib:connect_bin(Type, Host, Port, transport_opts(Type, Config)),
    inets_test_lib:send(Type, Socket, BlockRequest),
    ct:sleep(100), %% Avoid possible timing issues
    ok = httpd:reload_config([{server_name, "httpd_disturbing_" ++ Version}, {port, Port}|
			      proplists:delete(server_name, HttpdConfig)], disturbing),
    Close = list_to_atom((typestr(Type)) ++ "_closed"),
    receive 
	{Close, Socket} ->
            inets_test_lib:close(Type, Socket),
            [{server_name, "httpd_disturbing_" ++ Version}] =
                httpd:info(Server, [server_name]),
            [] = stop_log_watcher(LogWatcher),
            [] = inets_test_lib:flush(),
	    ok
    end.
%%-------------------------------------------------------------------------
non_disturbing_1_1(Config) when is_list(Config) -> 
    non_disturbing([{http_version, "HTTP/1.1"} | Config]).

non_disturbing_1_0(Config) when is_list(Config) -> 
    non_disturbing([{http_version, "HTTP/1.0"} | Config]).

non_disturbing(Config) when is_list(Config)->
    Server =  proplists:get_value(server_pid, Config),
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Port = proplists:get_value(port, Config),
    Type = proplists:get_value(type, Config),

    HttpdConfig = httpd:info(Server), 
    BlockRequest = http_request("GET /cgi-bin/erl/httpd_example:delay ", Version, Host),
    {ok, Socket} = inets_test_lib:connect_bin(Type, Host, Port, transport_opts(Type, Config)),
    inets_test_lib:send(Type, Socket, BlockRequest),
    ct:sleep(100), %% Avoid possible timing issues
    ok = httpd:reload_config([{server_name, "httpd_non_disturbing_" ++ Version}, {port, Port}|
			      proplists:delete(server_name, HttpdConfig)], non_disturbing),
    Transport = type(Type),
    receive 
	{Transport, Socket, Msg} ->
	    ct:log("Received message ~p~n", [Msg]),
	    ok
    after 2000 ->
	  ct:fail(timeout)  
    end,
    inets_test_lib:close(Type, Socket),
    [{server_name, "httpd_non_disturbing_" ++ Version}] =  httpd:info(Server, [server_name]).
%%-------------------------------------------------------------------------
reload_config_file(Config) when is_list(Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    HttpdConf = filename:join(get_tmp_dir(Config), "inets_httpd_server.conf"),
    ServerConfig =
        "[\n" ++
        "{bind_address, \"localhost\"}," ++
        "{port,0}," ++
        "{server_name,\"httpd_test\"}," ++
        "{server_root,\"" ++ ServerRoot ++  "\"}," ++
        "{document_root,\"" ++ proplists:get_value(doc_root, Config) ++ "\"}" ++
        "].",
    ok = file:write_file(HttpdConf, ServerConfig),
    {ok, Server} = inets:start(httpd, [{proplist_file, HttpdConf}]),
    Port = proplists:get_value(port, httpd:info(Server)),
    NewConfig =
        "[\n" ++
        "{bind_address, \"localhost\"}," ++
        "{port," ++ integer_to_list(Port) ++ "}," ++
        "{server_name,\"httpd_test_new\"}," ++
        "{server_root,\"" ++ ServerRoot ++  "\"}," ++
        "{document_root,\"" ++ proplists:get_value(doc_root, Config) ++ "\"}" ++
        "].",
    
    %% Test Erlang term format
    ok = file:write_file(HttpdConf, NewConfig),
    ok = httpd:reload_config(HttpdConf, non_disturbing),
    "httpd_test_new" = proplists:get_value(server_name, httpd:info(Server)).
%%-------------------------------------------------------------------------
mime_types_format(Config) when is_list(Config) -> 
    DataDir = proplists:get_value(data_dir, Config),
    MimeTypes = filename:join(DataDir, "mime_types.txt"),
    {ok,[{"wrl","x-world/x-vrml"},
     {"vrml","x-world/x-vrml"},
     {"ice","x-conference/x-cooltalk"},
     {"movie","video/x-sgi-movie"},
     {"avi","video/x-msvideo"},
     {"qt","video/quicktime"},
     {"mov","video/quicktime"},
     {"mpeg","video/mpeg"},
     {"mpg","video/mpeg"},
     {"mpe","video/mpeg"},
     {"sgml","text/x-sgml"},
     {"sgm","text/x-sgml"},
     {"etx","text/x-setext"},
     {"tsv","text/tab-separated-values"},
     {"rtx","text/richtext"},
     {"txt","text/plain"},
     {"html","text/html"},
     {"htm","text/html"},
     {"css","text/css"},
     {"xwd","image/x-xwindowdump"},
     {"xpm","image/x-xpixmap"},
     {"xbm","image/x-xbitmap"},
     {"rgb","image/x-rgb"},
     {"ppm","image/x-portable-pixmap"},
     {"pgm","image/x-portable-graymap"},
     {"pbm","image/x-portable-bitmap"},
     {"pnm","image/x-portable-anymap"},
     {"ras","image/x-cmu-raster"},
     {"tiff","image/tiff"},
     {"tif","image/tiff"},
     {"png","image/png"},
     {"jpeg","image/jpeg"},
     {"jpg","image/jpeg"},
     {"jpe","image/jpeg"},
     {"ief","image/ief"},
     {"gif","image/gif"},
     {"pdb","chemical/x-pdb"},
     {"xyz","chemical/x-pdb"},
     {"wav","audio/x-wav"},
     {"ra","audio/x-realaudio"},
     {"rpm","audio/x-pn-realaudio-plugin"},
     {"ram","audio/x-pn-realaudio"},
     {"aif","audio/x-aiff"},
     {"aiff","audio/x-aiff"},
     {"aifc","audio/x-aiff"},
     {"mpga","audio/mpeg"},
     {"mp2","audio/mpeg"},
     {"au","audio/basic"},
     {"snd","audio/basic"},
     {"zip","application/zip"},
     {"src","application/x-wais-source"},
     {"ustar","application/x-ustar"},
     {"ms","application/x-troff-ms"},
     {"me","application/x-troff-me"},
     {"man","application/x-troff-man"},
     {"t","application/x-troff"},
     {"tr","application/x-troff"},
     {"roff","application/x-troff"},
     {"texinfo","application/x-texinfo"},
     {"texi","application/x-texinfo"},
     {"tex","application/x-tex"},
     {"tcl","application/x-tcl"},
     {"tar","application/x-tar"},
     {"sv4crc","application/x-sv4crc"},
     {"sv4cpio","application/x-sv4cpio"},
     {"sit","application/x-stuffit"},
     {"shar","application/x-shar"},
     {"sh","application/x-sh"},
     {"nc","application/x-netcdf"},
     {"cdf","application/x-netcdf"},
     {"mif","application/x-mif"},
     {"latex","application/x-latex"},
     {"skp","application/x-koan"},
     {"skd","application/x-koan"},
     {"skt","application/x-koan"},
     {"skm","application/x-koan"},
     {"cgi","application/x-httpd-cgi"},
     {"hdf","application/x-hdf"},
     {"gz","application/x-gzip"},
     {"gtar","application/x-gtar"},
     {"dvi","application/x-dvi"},
     {"dcr","application/x-director"},
     {"dir","application/x-director"},
     {"dxr","application/x-director"},
     {"csh","application/x-csh"},
     {"cpio","application/x-cpio"},
     {"Z","application/x-compress"},
     {"vcd","application/x-cdlink"},
     {"bcpio","application/x-bcpio"},
     {"rtf","application/rtf"},
     {"ppt","application/powerpoint"},
     {"ai","application/postscript"},
     {"eps","application/postscript"},
     {"ps","application/postscript"},
     {"pdf","application/pdf"},
     {"oda","application/oda"},
     {"bin","application/octet-stream"},
     {"dms","application/octet-stream"},
     {"lha","application/octet-stream"},
     {"lzh","application/octet-stream"},
     {"exe","application/octet-stream"},
     {"class","application/octet-stream"},
     {"doc","application/msword"},
     {"cpt","application/mac-compactpro"},
     {"hqx","application/mac-binhex40"}]} = httpd_conf:load_mime_types(MimeTypes).

erl_script_timeout_default(Config) when is_list(Config) ->
    ServerConfig = [
        {modules, [mod_esi]},
        {erl_script_alias, {"/erl", [httpd_example]}}
        | Config
    ],
    Httpd = init_httpd(esi, ServerConfig),

    Port = proplists:get_value(port, Httpd),

    %% Default erl_script_timeout is 15.
    %% Verify:  13 =< erl_script_timeout =< 17
    Url = http_get_url(Port, 500, 13000, 4000),

    {ok, {_, _, Body}} = httpc:request(get, {Url, []}, [{timeout, 45000}], []),
    ct:log("Response: ~p~n", [Body]),
    verify_body(Body, 13000).

erl_script_timeout_option(Config) when is_list(Config) ->
    ServerConfig = [
        {modules, [mod_esi]},
        {erl_script_timeout, 2},
        {erl_script_alias, {"/erl", [httpd_example]}}
        | Config
    ],
    ServerInfo = init_httpd(esi, ServerConfig),
    Pid = proplists:get_value(server_pid, ServerInfo),
    Info = httpd:info(Pid),
    verify_timeout(Info, 2),

    Port = proplists:get_value(port, Info),

    %% Verify:  1 =< erl_script_timeout =< 3
    Url = http_get_url(Port, 500, 1000, 2000),

    {ok, {_, _, Body}} = httpc:request(Url),
    ct:log("Response: ~p~n", [Body]),
    verify_body(Body, 1000).

erl_script_timeout_proplist(Config) when is_list(Config) ->
    HttpdConf = filename:join(get_tmp_dir(Config),
                              "httpd_erl_script_timeout_proplist.conf"),
    ServerConfig =
        "[{port, 0},\n" ++
        " {server_name,\"localhost\"},\n" ++
        " {server_root,\"./\"},\n" ++
        " {document_root,\"./\"},\n" ++
        " {bind_address, any},\n" ++
        " {mimetypes, [{\"html\", \"text/html\"}]},\n" ++
        " {modules,[mod_esi]},\n" ++
        " {erl_script_timeout, 5},\n" ++
        " {erl_script_alias, {\"/erl\", [httpd_example]}}\n" ++
        "].",
    ok = file:write_file(HttpdConf, ServerConfig),

    {ok, Pid} =	inets:start(httpd,
                            [{proplist_file, HttpdConf}]),
    Info = httpd:info(Pid),
    verify_timeout(Info, 5),

    Port = proplists:get_value(port, Info),

    %% Verify:  3 =< erl_script_timeout =< 7
    Url = http_get_url(Port, 500, 3000, 4000),

    {ok, {_, _, Body}} = httpc:request(Url),
    ct:log("Response: ~p~n", [Body]),
    verify_body(Body, 3000).

erl_script_alias_all(Config0) when is_list(Config0) ->
    ok = start_apps(http_basic),
    Config1 = [{http_version, "HTTP/1.0"},
               {type, ip_comm} |
               Config0],
    Config2 = init_httpd(http_basic_erl_script_alias_all, Config1),
    ok = http_status("GET /cgi-bin/erl/httpd_example:get ",
        	     Config2, [{statuscode, 200}]).

tls_alert(Config) when is_list(Config) ->
    SSLOpts = proplists:get_value(client_alert_conf, Config),    
    Port = proplists:get_value(port, Config),    
    {error, {tls_alert, _}} = ssl:connect("localhost", Port, [{verify, verify_peer} | SSLOpts]).

%%--------------------------------------------------------------------
%% Internal functions -----------------------------------
%%--------------------------------------------------------------------
url(http, End, Config) ->
    Port = proplists:get_value(port, Config),
    {ok,Host} = inet:gethostname(),
    ?URL_START ++ Host ++ ":" ++ integer_to_list(Port) ++ End.

http_get_url(Port0, HeaderDelay, ChunkDelay, BadChunkDelay) ->
    {ok, Host} = inet:gethostname(),
    Port = integer_to_list(Port0),
    HD = integer_to_list(HeaderDelay),
    CD = integer_to_list(ChunkDelay),
    BD = integer_to_list(BadChunkDelay),
    "http://" ++ Host ++ ":" ++ Port ++
        "/erl/httpd_example/get_chunks?header_delay=" ++ HD ++
        "&chunk_delay=" ++ CD ++
        "&bad_chunk_delay=" ++ BD.

verify_body(Body, Timeout0) ->
    Timeout = integer_to_list(Timeout0),
    Res = string:find(Body, Timeout),
    ct:log("Result: ~p~n", [Res]),
    %% Fail if BAD chunk is found.
    case Res =:= Timeout ++ " ms\r\n" of
        true ->
            ok;
        false ->
            ct:fail("Unexpected chunk received!")
    end.

verify_timeout(Info, Expected) ->
    Timeout = proplists:get_value(erl_script_timeout, Info),
    case Timeout =:= Expected of
        true ->
            ok;
        false ->
            ct:fail("Bad Timeout - Expected: ~p Got: ~p", [Expected, Timeout])
    end.

do_max_clients(Config) ->
    Version = proplists:get_value(http_version, Config),
    Host    = proplists:get_value(host, Config),
    Port    = proplists:get_value(port, Config), 
    Type    = proplists:get_value(type, Config),
    
    Request = http_request("GET /index.html ", Version, Host),
    BlockRequest = http_request("GET /cgi_bin/erl/httpd_example:delay ", Version, Host),
    {ok, Socket} = inets_test_lib:connect_bin(Type, Host, Port, transport_opts(Type, Config)),
    inets_test_lib:send(Type, Socket, BlockRequest),
    ok = httpd_test_lib:verify_request(Type, Host, 
				       Port,
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       Request,
				       [{statuscode, 503},
					{version, Version}]),
    receive 
	{_, Socket, _Msg} ->
	    ok
    end,
    inets_test_lib:close(Type, Socket),
    ct:sleep(5000), %% Avoid possible timing issues
    ok = httpd_test_lib:verify_request(Type, Host, 
				       Port,
				       transport_opts(Type, Config),
				       proplists:get_value(node, Config),
				       Request,
				       [{statuscode, 200},
					{version, Version}]).

setup_server_dirs(ServerRoot, DocRoot, DataDir) ->
    CgiDir =  filename:join(ServerRoot, "cgi-bin"),
    AuthDir =  filename:join(ServerRoot, "auth"),
    PicsDir =  filename:join(ServerRoot, "icons"),
    ConfigDir =  filename:join(ServerRoot, "config"),

    ok = file:make_dir(ServerRoot),
    ok = file:make_dir(DocRoot),
    ok = file:make_dir(CgiDir),
    ok = file:make_dir(AuthDir),
    ok = file:make_dir(PicsDir),
    ok = file:make_dir(ConfigDir),

    DocSrc = filename:join(DataDir, "server_root/htdocs"),
    AuthSrc = filename:join(DataDir, "server_root/auth"),
    CgiSrc =  filename:join(DataDir, "server_root/cgi-bin"),
    PicsSrc =  filename:join(DataDir, "server_root/icons"),
    ConfigSrc = filename:join(DataDir, "server_root/config"),

    inets_test_lib:copy_dirs(DocSrc, DocRoot),
    inets_test_lib:copy_dirs(AuthSrc, AuthDir),
    inets_test_lib:copy_dirs(CgiSrc, CgiDir),
    inets_test_lib:copy_dirs(PicsSrc, PicsDir),
    inets_test_lib:copy_dirs(ConfigSrc, ConfigDir),

    Cgi = case os:type() of
	      {win32, _} ->
		  "cgi_echo.exe";
	      _ ->
		  "cgi_echo"
	  end,

    inets_test_lib:copy_file(Cgi, DataDir, CgiDir),
    AbsCgi = filename:join([CgiDir, Cgi]),
    {ok, FileInfo} = file:read_file_info(AbsCgi),
    ok = file:write_file_info(AbsCgi, FileInfo#file_info{mode = 8#00755}),

    EnvCGI =  filename:join([ServerRoot, "cgi-bin", "printenv.sh"]),
    {ok, FileInfo1} = file:read_file_info(EnvCGI),
    ok = file:write_file_info(EnvCGI,
			      FileInfo1#file_info{mode = 8#00755}).

setup_tmp_dir(PrivDir) ->
    TmpDir =  filename:join(PrivDir, "tmp"),
    ok = file:make_dir(TmpDir).

get_tmp_dir(Config) ->
    PrivDir = proplists:get_value(priv_dir, Config),
    filename:join(PrivDir, "tmp").

start_apps(Group) when  Group == https_basic;
			Group == https_limit;
			Group == https_custom;
			Group == https_basic_auth;
			Group == https_auth_api;
			Group == https_auth_api_dets;
			Group == https_auth_api_mnesia;
			Group == https_security;
			Group == https_reload;
                        Group == https_not_sup;
                        Group == https_alert
			->
    inets_test_lib:start_apps([inets, asn1, crypto, public_key, ssl]);
start_apps(Group) when  Group == http_basic;
			Group == http_limit;
			Group == http_custom;
			Group == http_basic_auth;
			Group == http_auth_api;
			Group == http_auth_api_dets;
			Group == http_auth_api_mnesia;
			Group == http_security;
			Group == http_logging;
			Group == http_reload;
                        Group == http_post;
                        Group == http_default_type;
                        Group == http_mime_type;
                        Group == http_mime_and_default_type;
                        Group == http_mime_types;
                        Group == http_rel_path_script_alias;
                        Group == http_not_sup;
                        Group == http_mime_types;
                        Group == esi ->
    inets_test_lib:start_apps([inets]).

server_start(_, HttpdConfig) ->
    {ok, Pid} = inets:start(httpd, HttpdConfig),
    Serv = inets:services_info(),
    {value, {_, _, Info}} = lists:keysearch(Pid, 2, Serv),
    {Pid, proplists:get_value(port, Info)}.

init_ssl(Group, Config) ->
    ClientFileBase = filename:join([proplists:get_value(priv_dir, Config), "client"]),
    ServerFileBase = filename:join([proplists:get_value(priv_dir, Config), "server"]),
    GenCertData = #{client_config := CConf} =
        public_key:pkix_test_data(#{server_chain =>
                                        #{root => [{key, inets_test_lib:hardcode_rsa_key(1)}, {digest, sha256}],
                                          intermediates => [[{key, inets_test_lib:hardcode_rsa_key(2)}, {digest, sha256}]],
                                          peer => [{key, inets_test_lib:hardcode_rsa_key(3)}, {digest, sha256}]},
                                    client_chain =>
                                        #{root => [{key, inets_test_lib:hardcode_rsa_key(4)}, {digest, sha256}],
                                          intermediates => [[{key, inets_test_lib:hardcode_rsa_key(5)}, {digest, sha256}]],
                                    peer => [{key, inets_test_lib:hardcode_rsa_key(6)}, {digest, sha256}]}}),
    [_ | CAs] = proplists:get_value(cacerts, CConf),
    AlertConf = [{cacerts, CAs} |  proplists:delete(cacerts, CConf)],
    Conf = inets_test_lib:gen_pem_config_files(GenCertData, ClientFileBase, ServerFileBase),
    case start_apps(Group) of
	ok ->
	    init_httpd(Group, [{client_alert_conf, AlertConf}, {type, ssl}, {ssl_conf, Conf} | Config]);
	_ ->
	    {skip, "Could not start https apps"}
    end.

server_config(http_basic, Config) ->
    basic_conf() ++ server_config(http, Config);
server_config(http_basic_erl_script_alias_all, Config) ->
    basic_conf() ++ server_config(http_erl_script_alias_all, Config);
server_config(https_basic, Config) ->
    basic_conf() ++ server_config(https, Config);
server_config(http_not_sup, Config) ->
    not_sup_conf() ++ server_config(http, Config);
server_config(https_not_sup, Config) ->
    not_sup_conf() ++ server_config(https, Config);
server_config(http_reload, Config) ->
    [{keep_alive_timeout, 2}]  ++ server_config(http, Config);
server_config(http_post, Config) ->
    [{max_client_body_chunk, 10}]  ++ server_config(http, Config);
server_config(https_reload, Config) ->
    [{keep_alive_timeout, 2}]  ++ server_config(https, Config);
server_config(http_limit, Config) ->
    Conf = [{max_clients, 1},
            {disable_chunked_transfer_encoding_send, true},
	    %% Make sure option checking code is run
	    {max_content_length, 100000002}]  ++ server_config(http, Config),
    ct:log("Received message ~p~n", [Conf]),
    Conf;
server_config(http_custom, Config) ->
    [{customize, ?MODULE}]  ++ server_config(http, Config);
server_config(https_custom, Config) ->
    [{customize, ?MODULE}]  ++ server_config(https, Config);
server_config(https_limit, Config) ->
    [{max_clients, 1},
     {disable_chunked_transfer_encoding_send, true}
    ]  ++ server_config(https, Config);
server_config(http_basic_auth, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_conf(ServerRoot)  ++  server_config(http, Config);
server_config(https_basic_auth, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_conf(ServerRoot)  ++  server_config(https, Config);
server_config(http_auth_api, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, plain)  ++  server_config(http, Config);
server_config(https_auth_api, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, plain)  ++  server_config(https, Config);
server_config(http_auth_api_dets, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, dets)  ++  server_config(http, Config);
server_config(https_auth_api_dets, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, dets)  ++  server_config(https, Config);
server_config(http_auth_api_mnesia, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, mnesia)  ++  server_config(http, Config);
server_config(https_auth_api_mnesia, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    auth_api_conf(ServerRoot, mnesia)  ++  server_config(https, Config);
server_config(http_security, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    tl(auth_conf(ServerRoot)) ++ security_conf(ServerRoot) ++ server_config(http, Config);
server_config(https_security, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    tl(auth_conf(ServerRoot)) ++ security_conf(ServerRoot) ++ server_config(https, Config);
server_config(http_logging, Config) ->
    log_conf() ++ server_config(http, Config);
server_config(http_default_type, Config) ->
    [{default_type, "text/html"}] ++ basic_conf() ++ server_config(http, Config);
server_config(http_mime_type, Config) ->
    [{mime_type, "text/html"}] ++ basic_conf() ++ server_config(http, Config);
server_config(http_mime_and_default_type, Config) ->
    [{default_type, "text/richtext"}, {mime_type, "text/html"}] ++ basic_conf() ++ server_config(http, Config);
server_config(http_mime_types, Config0) ->
    Config1 = basic_conf() ++  server_config(http, Config0),
    ServerRoot = proplists:get_value(server_root, Config0),
    MimeTypesFile = filename:join([ServerRoot,"config", "mime.types"]),
    [{mime_types, MimeTypesFile} | proplists:delete(mime_types, Config1)];
server_config(https_alert, Config) ->
    basic_conf() ++ server_config(https, Config);
server_config(http, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    config_template(Config, ServerRoot,
                    filename:join(ServerRoot, "cgi-bin") ++ "/", [httpd_example, io]);
server_config(http_erl_script_alias_all, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    config_template(Config, ServerRoot, "./cgi-bin/", [all]);
server_config(http_rel_path_script_alias, Config) ->
    ServerRoot = proplists:get_value(server_root, Config),
    config_template(Config, ServerRoot, "./cgi-bin/", [httpd_example, io]);
server_config(https, Config) ->
    SSLConf = proplists:get_value(ssl_conf, Config),
    ServerConf = proplists:get_value(server_config, SSLConf),
    [{socket_type, {ssl,
		    [{nodelay, true} | ServerConf]}}]
        ++ proplists:delete(socket_type, server_config(http, Config));
server_config(esi, Config) ->
    basic_conf() ++ server_config(http, Config).

config_template(Config, ServerRoot, ScriptPath, Modules) ->
    [{port, 0},
     {socket_type, {ip_comm, [{nodelay, true}]}},
     {server_name,"httpd_test"},
     {server_root, ServerRoot},
     {document_root, proplists:get_value(doc_root, Config)},
     {bind_address, any},
     {ipfamily, proplists:get_value(ipfamily, Config)},
     {max_header_size, 256},
     {max_header_action, close},
     {directory_index, ["index.html", "welcome.html"]},
     {mime_types, [{"html","text/html"},{"htm","text/html"}, {"shtml","text/html"},
		   {"gif", "image/gif"}]},
     {alias, {"/icons/", filename:join(ServerRoot,"icons") ++ "/"}},
     {re_write, {"/pic(ture)?s/",  filename:join(ServerRoot,"icons") ++ "/"}},
     {script_alias, {"/htbin/", ScriptPath}},
     {script_alias, {"/cgi-bin/", ScriptPath}},
     {script_re_write, {"/cgi-([a-zA-Z-]*)bin/", ScriptPath}},
     {erl_script_alias, {"/cgi-bin/erl", Modules}}
    ] ++ custom_config_options(Config).

custom_config_options([{Name, _} = Option | Rest]) when Name == erl_script_alias;
                                                        Name == erl_script_timeout ->
    [Option | custom_config_options(Rest)];
custom_config_options([_ | Rest]) ->
    custom_config_options(Rest);
custom_config_options([]) ->
    [].

init_httpd(Group, Config0) ->
    Config1 = proplists:delete(port, Config0),
    Config = proplists:delete(server_pid, Config1),
    {Pid, Port} = server_start(Group, server_config(Group, Config)),
    [{server_pid, Pid}, {port, Port} | Config].

http_request(Request, "HTTP/1.1" = Version, Host, {Headers, Body}) ->
    Request ++ Version ++ "\r\nhost:" ++ Host ++ "\r\n" ++ Headers ++ "\r\n" ++ Body;
http_request(Request, Version, _, {Headers, Body}) ->
    Request ++ Version ++ "\r\n" ++ Headers  ++ "\r\n" ++ Body.

http_request(Request, "HTTP/1.1" = Version, Host) ->
    Request ++ Version ++ "\r\nhost:" ++ Host  ++ "\r\n\r\n";
http_request(Request, Version, _) ->
    Request ++ Version ++ "\r\n\r\n".

auth_request(Path, User, Passwd, "HTTP/1.1" = Version, Host) ->
    "GET " ++ Path ++ " " ++ Version ++  "\r\nhost:" ++ Host  ++
	"\r\nAuthorization: Basic " ++  
	base64:encode_to_string(User++":"++Passwd) ++
	"\r\n\r\n";
auth_request(Path, User, Passwd, Version, _Host) ->
    "GET " ++ Path ++ " " ++ Version ++  
	"\r\nAuthorization: Basic " ++  
	base64:encode_to_string(User++":"++Passwd) ++
	"\r\n\r\n".

http_request_missing_CR(Request, "HTTP/1.1" = Version, Host) ->
    Request ++ Version ++ "\r\nhost:" ++ Host  ++ "\r\n\r\n\n";
http_request_missing_CR(Request, Version, _) ->
    Request ++ Version ++ "\r\n\n".

head_status("HTTP/0.9", _) ->
    501; %% Not implemented in HTTP/0.9
head_status(_, Expected) ->
    Expected.


basic_conf() ->
    [{modules, [mod_alias, mod_range, mod_responsecontrol,
		mod_trace, mod_esi, ?MODULE, mod_cgi, mod_get, mod_head]},
     {logger, [{error, httpd_test}]}].

do(ModData) ->
    case whereis(propagate_test) of
        undefined ->
            ok;
        _ ->
            {already_sent, Status, _Size} = proplists:get_value(response, ModData#mod.data),
            propagate_test ! {status, Status}              
    end,
    {proceed, ModData#mod.data}.

not_sup_conf() ->
    [{modules, [mod_get]}].

auth_access_conf() ->
    [{modules, [mod_alias, mod_dir, mod_get, mod_head]}].

auth_conf(Root) ->
    [{modules, [mod_alias, mod_auth, mod_dir, mod_get, mod_head]},
     {directory, {filename:join(Root, "htdocs/open"), 
		  [{auth_type, plain},
		   {auth_name, "Open Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_user, ["one", "Aladdin"]}]}},
     {directory, {filename:join(Root, "htdocs/secret"), 
		  [{auth_type, plain},
		   {auth_name, "Secret Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_group, ["group1", "group2"]}]}},
     {directory, {filename:join(Root, "htdocs/secret/top_secret"), 
		  [{auth_type, plain},
		   {auth_name, "Top Secret Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_group, ["group3"]}]}}].     

auth_api_conf(Root, plain) ->
    [{modules, [mod_alias, mod_auth, mod_dir, mod_get, mod_head]},
     {directory, {filename:join(Root, "htdocs/open"), 
		  [{auth_type, plain},
		   {auth_name, "Open Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_user, ["one", "Aladdin"]}]}},
     {directory, {filename:join(Root, "htdocs/secret"), 
		  [{auth_type, plain},
		   {auth_name, "Secret Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_group, ["group1", "group2"]}]}},
     {directory, {filename:join(Root, "htdocs/secret/top_secret"), 
		  [{auth_type, plain},
		   {auth_name, "Top Secret Area"},
		   {auth_user_file, filename:join(Root, "auth/passwd")},
		   {auth_group_file, filename:join(Root, "auth/group")},
		   {require_group, ["group3"]}]}}];

auth_api_conf(Root, dets) ->
    [
     {modules, [mod_alias, mod_auth, mod_dir, mod_get, mod_head]},
     {directory, {filename:join(Root, "htdocs/dets_open"), 
		  [{auth_type, dets},
		   {auth_name, "Dets Open Area"},
		   {auth_user_file, filename:join(Root, "passwd")},
		   {auth_group_file, filename:join(Root, "group")},
		   {require_user, ["one", "Aladdin"]}]}},
     {directory, {filename:join(Root, "htdocs/dets_secret"), 
		  [{auth_type, dets},
		   {auth_name, "Dests Secret Area"},
		   {auth_user_file, filename:join(Root, "passwd")},
		   {auth_group_file, filename:join(Root, "group")},
		  {require_group, ["group1", "group2"]}]}},
     {directory, {filename:join(Root, "htdocs/dets_secret/top_secret"), 
		  [{auth_type, dets},
		   {auth_name, "Dets Top Secret Area"},
		   {auth_user_file, filename:join(Root, "passwd")},
		   {auth_group_file, filename:join(Root, "group")},
		   {require_group, ["group3"]}]}} 
    ];

auth_api_conf(Root, mnesia) ->
    [{modules, [mod_alias, mod_auth, mod_dir, mod_get, mod_head]},
     {directory, {filename:join(Root, "htdocs/mnesia_open"), 
		  [{auth_type, mnesia},
		   {auth_name, "Mnesia Open Area"},
		   {require_user, ["one", "Aladdin"]}]}},
     {directory, {filename:join(Root, "htdocs/mnesia_secret"), 
		  [{auth_type, mnesia},
		   {auth_name, "Mnesia Secret Area"},
		   {require_group, ["group1", "group2"]}]}},
     {directory, {filename:join(Root, "htdocs/mnesia_secret/top_secret"), 
		  [{auth_type, mnesia},
		   {auth_name, "Mnesia Top Secret Area"},
		   {require_group, ["group3"]}]}}].

security_conf(Root) ->
    SecFile = filename:join(Root, "security_data"),
    Open = filename:join(Root, "htdocs/open"),
    Secret = filename:join(Root, "htdocs/secret"),
    TopSecret = filename:join(Root, "htdocs/secret/top_secret"), 
	
    [{modules, [mod_alias, mod_auth, mod_security, mod_dir, mod_get, mod_head]},
     {security_directory, {Open, 
			   [{auth_name, "Open Area"},
			    {auth_user_file, filename:join(Root, "auth/passwd")},
			    {auth_group_file, filename:join(Root, "auth/group")},
			    {require_user, ["one", "Aladdin"]} | 
			    mod_security_conf(SecFile, Open)]}},
     {security_directory, {Secret, 
			   [{auth_name, "Secret Area"},
			    {auth_user_file, filename:join(Root, "auth/passwd")},
			    {auth_group_file, filename:join(Root, "auth/group")},
			    {require_group, ["group1", "group2"]} |
			    mod_security_conf(SecFile, Secret)]}},
     {security_directory, {TopSecret,
			   [{auth_name, "Top Secret Area"},
			    {auth_user_file, filename:join(Root, "auth/passwd")},
			    {auth_group_file, filename:join(Root, "auth/group")},
			    {require_group, ["group3"]} |
			    mod_security_conf(SecFile, TopSecret)]}}].     

mod_security_conf(SecFile, Dir) ->
    [{data_file, SecFile},
     {max_retries, 3},
     {fail_expire_time, ?FAIL_EXPIRE_TIME},
     {block_time, 1},
     {auth_timeout, ?AUTH_TIMEOUT},
     {callback_module, ?MODULE},
     {path, Dir} %% This is should not be needed, but is atm, awful design! 
    ].
    
log_conf() ->
    [{modules, [mod_alias, mod_dir, mod_get, mod_head, mod_disk_log]},
     {transfer_disk_log, "httpd_log_transfer"},
     {security_disk_log, "httpd_log_security"},
     {error_disk_log, "httpd_log_error"},
     {transfer_disk_log_size, {1048576, 5}},
     {error_disk_log_size, {1048576, 5}},
     {error_disk_log_size, {1048576, 5}},
     {security_disk_log_size, {1048576, 5}},
     {disk_log_format, internal}].

http_status(Request, Config, Expected) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),    
    Type = proplists:get_value(type, Config),
    httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				  proplists:get_value(port, Config),  
				  transport_opts(Type, Config),
				  proplists:get_value(node, Config),
				  http_request(Request, Version, Host),
				  Expected ++ [{version, Version}]).

http_status(Request, HeadersAndBody, Config, Expected) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),
    Type = proplists:get_value(type, Config),
    httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				  proplists:get_value(port, Config),  
				  transport_opts(Type, Config),
				  proplists:get_value(node, Config),
				  http_request(Request, Version, Host, HeadersAndBody),
				  Expected ++ [{version, Version}]).

auth_status(AuthRequest, Config, Expected) ->
    Version = proplists:get_value(http_version, Config),
    Host = proplists:get_value(host, Config),    
    Type = proplists:get_value(type, Config),
    httpd_test_lib:verify_request(proplists:get_value(type, Config), Host, 
				  proplists:get_value(port, Config),  
				  transport_opts(Type, Config),
				  proplists:get_value(node, Config),
				  AuthRequest,
				  Expected ++ [{version, Version}]).

basic_auth_requiered(Config) -> 
    ok = http_status("GET /open/ ", Config,  [{statuscode, 401},
					      {header, "WWW-Authenticate"}]),
    ok = http_status("GET /secret/ ", Config,  [{statuscode, 401},
						{header, "WWW-Authenticate"}]),
    ok = http_status("GET /secret/top_secret/ ", Config,  [{statuscode, 401},
						      {header, "WWW-Authenticate"}]).  

start_mnesia(Node) ->
    case rpc:call(Node, ?MODULE, cleanup_mnesia, []) of
	ok ->
	    ok;
	Other ->
	    ct:fail({failed_to_cleanup_mnesia, Other})
    end,
    case rpc:call(Node, ?MODULE, setup_mnesia, []) of
	{atomic, ok} ->
	    ok;
	Other2 ->
	    ct:fail({failed_to_setup_mnesia, Other2})
    end,
    ok.

setup_mnesia() ->
    setup_mnesia([node()]).

setup_mnesia(Nodes) ->
    ok = mnesia:create_schema(Nodes),
    ok = mnesia:start(),
    {atomic, ok} = mnesia:create_table(httpd_user,
				       [{attributes, 
					 record_info(fields, httpd_user)}, 
					{disc_copies,Nodes}, {type, set}]),
    {atomic, ok} = mnesia:create_table(httpd_group,
				       [{attributes, 
					 record_info(fields,
						     httpd_group)}, 
					{disc_copies,Nodes}, {type,bag}]).

cleanup_mnesia() ->
    mnesia:start(),
    mnesia:delete_table(httpd_user),
    mnesia:delete_table(httpd_group),
    stopped = mnesia:stop(),
    mnesia:delete_schema([node()]),
    ok.

transport_opts(ssl, Config) ->
    SSLConf = proplists:get_value(ssl_conf, Config),
    ClientConf = proplists:get_value(client_config, SSLConf),
    [proplists:get_value(ipfamily, Config) | ClientConf];
transport_opts(_, Config) ->
    [proplists:get_value(ipfamily, Config)].


%%% mod_range
create_range_data(Path) ->
    PathAndFileName=filename:join([Path,"range.txt"]),
    case file:read_file(PathAndFileName) of
	{error, enoent} ->
	    file:write_file(PathAndFileName,list_to_binary(["12345678901234567890",
							    "12345678901234567890",
							    "12345678901234567890",
							    "12345678901234567890",
							    "12345678901234567890"]));
	_ ->
	    ok
    end.

dos_hostname(Type, Port, Host, Node, Version, Max) ->    
    TooLongHeader = lists:append(lists:duplicate(Max + 1, "a")),
    
    ok = httpd_test_lib:verify_request(Type, Host, Port, Node, 
 				       dos_hostname_request("", Version),
 				       [{statuscode, 200},
 					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(Type, Host, Port, Node, 
 				       dos_hostname_request("dummy-host.ericsson.se", Version),
 				       [{statuscode, 200},
 					{version, Version}]),
    
    ok = httpd_test_lib:verify_request(Type, Host, Port, Node, 
 				       dos_hostname_request(TooLongHeader, Version),
 				       [{statuscode, request_entity_too_large_code(Version)},
 					{version, Version}]).
dos_hostname_request(Host, Version) ->
    dos_http_request("GET / ", Version, Host).

dos_http_request(Request,  "HTTP/1.1" = Version, Host) ->
    http_request(Request, Version, Host);
dos_http_request(Request, Version, Host) ->
    Request ++ Version ++ "\r\nhost:" ++ Host  ++ "\r\n\r\n".

request_entity_too_large_code("HTTP/1.0") ->
    403; %% 413 not defined in HTTP/1.0
request_entity_too_large_code(_) ->
    413.

length_required_code("HTTP/1.0") ->
    403; %% 411 not defined in HTTP/1.0
length_required_code(_) ->
    411.

garbage_content_length(Type, Port, Host, Node, Version) ->    
    ok = httpd_test_lib:verify_request(Type, Host, Port, Node, 
     				       garbage_content_length_request("GET / ", Version, Host, "aaaa"),	
     				       [{statuscode, length_required_code(Version)},
      					{version, Version}]),
    ok = httpd_test_lib:verify_request(Type, Host, Port, Node, 
				       garbage_content_length_request("GET / ", Version, Host, 
								      lists:duplicate($a, 100)),	
 				       [{statuscode, request_entity_too_large_code(Version)},
 					{version, Version}]).
 
garbage_content_length_request(Request, Version, Host, Garbage) ->	
    http_request(Request, Version, Host,
		 {"content-length:" ++ Garbage, "Body with garbage content length indicator"}).


update_password(Node, ServerRoot, _Address, Port, AuthPrefix, Dir, Old, New)->
    Directory = filename:join([ServerRoot, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, update_password, 
	     [undefined, Port, Directory, Old, New, New]).

add_user(Node, Root, Port, AuthPrefix, Dir, User, Password, UserData) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, add_user, 
	     [User, Password, UserData, Addr, Port, Directory]).


delete_user(Node, Root, _Host, Port, AuthPrefix, Dir, User) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, delete_user, [User, Addr, Port, Directory]).
remove_users(Node, ServerRoot, Host, Port, AuthPrefix, Dir) ->
    %% List users, delete them, and make sure they are gone.
    case list_users(Node, ServerRoot, Host, Port, AuthPrefix, Dir) of
	{ok, Users} ->
	    lists:foreach(fun(User) -> 
				  delete_user(Node, ServerRoot, Host, 
					      Port, AuthPrefix, Dir, User)
			  end,
			  Users),
		  {ok, []} = list_users(Node, ServerRoot, Host, Port, AuthPrefix, Dir);
	_ ->
	    ok
    end.

list_users(Node, Root, _Host, Port, AuthPrefix, Dir) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, list_users, [Addr, Port, Directory]).

remove_groups(Node, ServerRoot, Host, Port,  AuthPrefix, Dir) ->
    {ok, Groups} = list_groups(Node, ServerRoot, Host, Port, AuthPrefix, Dir),
    lists:foreach(fun(Group) ->
			  delete_group(Node, Group, Port, ServerRoot, AuthPrefix, Dir)
		  end,
		  Groups),
    {ok, []} = list_groups(Node, ServerRoot, Host, Port, AuthPrefix, Dir).

delete_group(Node, Group, Port, Root, AuthPrefix, Dir) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, delete_group, [Group, Addr, Port, Directory]).

list_groups(Node, Root, _, Port, AuthPrefix, Dir) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, list_groups, [Addr, Port, Directory]).

add_group_member(Node, Root, Port, AuthPrefix, Dir, User, Group) ->
    Addr = undefined, 
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, add_group_member, [Group, User, Addr, Port, 
					  Directory]).
list_group_members(Node, Root, Port, AuthPrefix, Dir, Group) ->
    Directory = filename:join([Root, "htdocs", AuthPrefix ++ Dir]),
    rpc:call(Node, mod_auth, list_group_members, [Group, [{port, Port}, {dir, Directory}]]).

getaddr() ->
    {ok,HostName} = inet:gethostname(),
    {ok,{A1,A2,A3,A4}} = inet:getaddr(HostName,inet),
    lists:flatten(io_lib:format("~p.~p.~p.~p",[A1,A2,A3,A4])).

receive_security_event(Event, Node, Port) ->
    receive 
	Event ->
	    ok;
	{'EXIT', _, _} ->
	    receive_security_event(Event, Node, Port)
    after 5000 ->
	    %% Flush the message queue, to see if we got something...
	    inets_test_lib:flush()
    end.

list_blocked_users(Node,Port) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, list_blocked_users, [Addr,Port]).

list_blocked_users(Node,Port,Dir) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, list_blocked_users, [Addr,Port,Dir]).

block_user(Node,User,Port,Dir,Sec) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, block_user, [User, Addr, Port, Dir, Sec]).

unblock_user(Node,User,Port,Dir) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, unblock_user, [User, Addr, Port, Dir]).

list_auth_users(Node,Port) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, list_auth_users, [Addr,Port]).

list_auth_users(Node,Port,Dir) ->
    Addr = undefined, % Assumed to be on the same host
    rpc:call(Node, mod_security, list_auth_users, [Addr,Port,Dir]).

event(What, Port, Dir, Data) ->
    Msg = {event, What, Port, Dir, Data},
    case global:whereis_name(mod_security_test) of
	undefined ->
	    ok;
	_Pid ->
	    global:send(mod_security_test, Msg)
    end.

type(ip_comm) ->
    tcp;
type(_) ->
    ssl.

typestr(ip_comm) ->
    "tcp";
typestr(_) ->
    "ssl".

response_header({"server", _}) ->
    false;
response_header(Header) ->
    {true, Header}.

response_default_headers() ->
    [%% Add new header
     {"X-Frame-Options", "SAMEORIGIN"},
     %% Override built-in default
     {"Date", "Override-date"}].

peer(Config) ->
   case proplists:get_value(type, Config) of
      ssl ->
        "true";
      _ ->
        "false"
   end.   

start_log_watcher() ->
    Spawner = self(),
    EventDest = erlang:alias(),
    HandlerId = ?MODULE,
    _ =
        spawn(
          fun () ->
                  MonAlias =
                      monitor(process, Spawner, [{alias,reply_demonitor}]),
                  EventDest ! {started,EventDest,MonAlias},
                  receive
                      {stop,MonAlias} ->
                          _ = logger:remove_handler(HandlerId),
                          EventDest ! {stopped,EventDest},
                          ok;
                      {'DOWN',MonAlias,_,_,_} ->
                          _ = logger:remove_handler(HandlerId),
                          ok
                  end
          end),
    receive
        {started,EventDest,Watcher} ->
            Config = #{ config => EventDest },
            ok = logger:add_handler(HandlerId, ?MODULE, Config),
            {EventDest,Watcher}
    end.

stop_log_watcher({EventDest,Watcher}) ->
    Watcher ! {stop,Watcher},
    receive
        {stopped,EventDest} ->
            true = unalias(EventDest),
            stop_log_watcher_collect(EventDest)
    end.
%%
stop_log_watcher_collect(EventDest) ->
    receive
        {event,EventDest,Event} ->
            [Event | stop_log_watcher_collect(EventDest)]
    after 0 ->
            []
    end.

log(#{level := Level} = Event, #{ config := EventDest }) ->
    %% Pass on events of level 'error' or worse
    case logger:compare_levels(Level, error) of
        lt ->
            ok;
        _ ->
            EventDest ! {event,EventDest,Event},
            ok
    end.
