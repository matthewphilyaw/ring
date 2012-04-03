-module(ring).
-export([start/3, stop/0, send/2]).

start(M, N, Message) ->
	register(ring, spawn(fun() -> loop(self(), N) end)),
	send(M, Message).

stop() ->
	ring ! stop,
	ok.

send(0, _Message) -> 
	ok;
send(M, Message) ->
	ring ! {send, integer_to_list(M) ++ Message},
	send(M-1, Message).

%% spawn next node in ring
loop(First, N) ->
	case N > 0 of
		true ->
			Next = spawn(fun() -> loop(First, N-1) end),
			loop(Next);
		false ->
			loop(First)
	end.

%% main loop.
loop(Next) ->
	This = self(),
	receive
		stop ->
			io:format("~w Stopping.~n", [self()]),
			Next ! stop;
		{This, forward, Msg} ->
			io:format("'~s' made it around the ring.~n", [Msg]),
			loop(Next);
		{From, forward, Msg} ->
			Next ! {From, forward, Msg},
			io:format("~w received forward request.~nForwarding - '~s'~n", [self(),Msg]),
			loop(Next);
		{send, Msg} ->
			Next ! {self(), forward, Msg},
			loop(Next)
	end.