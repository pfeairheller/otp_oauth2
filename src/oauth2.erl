%% Copyright
-module(oauth2).
-author("pfeairheller").
-behaviour(gen_server).

%% API
-export([token_from_refresh/4]).

%%Management
-export([start_link/0, stop/0]).

%%gen server callbacks
-export([init/1, terminate/2, handle_call/3]).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
  gen_server:cast(?MODULE, stop).

token_from_refresh(ClientId, Sercret, Url, RefreshToken) ->
  gen_server:call(?MODULE, {token_from_refresh, ClientId, Sercret, Url, RefreshToken}).


%%gen server callbacks
init(_StartArgs) ->
  {ok, null}.

terminate(_Reason, _LoopData) ->
  ok.

handle_call({token_from_refresh, ClientId, Secret, Site, RefreshToken}, _From, LoopData) ->
  ParamString = param_to_string([{client_id, ClientId}, {client_secret, Secret}, {grant_type, "refresh_token"}, {refresh_token, RefreshToken}]),
  Url = string:join([string:concat(Site, "/services/oauth2/token"), ParamString], "?"),
  io:format(Url),

  {ParamList} = case httpc:request(Url) of
    {ok, {_Status, _Headers, Body}} -> ejson:decode(Body);
    {error, _Reason} -> {[]}
  end,

  Reply = case lists:keyfind(<<"access_token">>, 1, ParamList) of
    false -> "";
    {_, Token} -> binary:bin_to_list(Token)
  end,
  {reply, Reply, LoopData}.


param_to_string([]) ->
  "";
param_to_string([{Name, Value } | Rest]) ->
  param_to_string([{Name, Value } | Rest], "").

param_to_string([{Name, Value } | Rest], "") ->
  Pair = string:join([atom_to_list(Name), Value], "="),
  param_to_string(Rest, Pair);
param_to_string([{Name, Value } | Rest], ParamString) ->
  Pair = string:join([atom_to_list(Name), Value], "="),
  P2 = string:join([ParamString, Pair], "&"),
  param_to_string(Rest, P2);
param_to_string([], ParamString) ->
  ParamString.


