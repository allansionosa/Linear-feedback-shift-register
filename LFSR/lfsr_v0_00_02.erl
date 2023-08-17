-module(lfsr_v0_00_02).
-behaviour(gen_statem).

-export([stop/0, start_link/0]).
-export([init/1, callback_mode/0, handle_event/4, terminate/3, code_change/4]).
-export([data_input/0, sixteen_bit_partitioning/0, head_binary_to_integer_storing/0,tail_binary_to_integer_seize/0]).
-export([register_tapping/0,alpha_register_shifting/0, bravo_register_shifting/0,stream_generate/0,head_integer_to_binary_storing/0, tail_integer_to_binary_seize/0]).

stop() ->
    gen_statem:stop(?MODULE).

start_link() ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [], []).

data_input() -> 
    gen_statem:call(?MODULE, data_input).

sixteen_bit_partitioning() ->
    gen_statem:cast(?MODULE,sixteen_bit_partitioning).

head_binary_to_integer_storing()->
    gen_statem:cast(?MODULE, head_binary_to_integer_storing).

tail_binary_to_integer_seize() ->
    gen_statem:cast(?MODULE, tail_binary_to_integer_seize).

register_tapping() -> 
    gen_statem:cast(?MODULE, register_tapping).

alpha_register_shifting() -> 
    gen_statem:cast(?MODULE, alpha_register_shifting).

bravo_register_shifting() -> 
    gen_statem:cast(?MODULE, bravo_register_shifting).

stream_generate() ->
    gen_statem:cast(?MODULE, stream_generate).

head_integer_to_binary_storing() ->
    gen_statem:cast(?MODULE,head_integer_to_binary_storing).

tail_integer_to_binary_seize() ->
    gen_statem:cast(?MODULE, tail_integer_to_binary_seize).


init(_Args) ->
    {ok, wait, []}.


callback_mode() ->
    handle_event_function.

handle_event({call, From}, data_input, wait, _Data) ->
    Message = string:strip(io:get_line("Input Hexadecimal Message: "), right, $\n),
    Number_of_Iteration = list_to_integer(string:strip(io:get_line("Number of Iteration: "), right, $\n)),
    lfsr_v0_00_02:sixteen_bit_partitioning(),
    {
    next_state, {sixteen_bit_partitioning, Message,Number_of_Iteration}, _Data, [{reply, From, ok}]
    };

handle_event(cast,sixteen_bit_partitioning, {sixteen_bit_partitioning,Message,Number_of_Iteration}, _Data ) -> 
    Message_Partitioned_Alpha = lists:nth(1,tuple_to_list(lists:split(16,Message))),
    Message_Partitioned_Bravo = lists:nth(2,tuple_to_list(lists:split(16,Message))),
    io:format("Input by 16 Bits:~p~n",[tuple_to_list(lists:split(16,Message))]),
   
     lfsr_v0_00_02:head_binary_to_integer_storing(),
    {
    next_state, {head_binary_to_integer_storing, Message_Partitioned_Alpha,[],Message_Partitioned_Bravo,[],Number_of_Iteration},_Data
    };

handle_event(cast,head_binary_to_integer_storing, {head_binary_to_integer_storing,[Message_Partitioned_Alpha_Head_Alter|Message_Partitioned_Alpha_Tail_Alter],Message_Partitioned_Alpha_Storage,
       [Message_Partitioned_Bravo_Head_Alter|Message_Partitioned_Bravo_Tail_Alter], Message_Partitioned_Bravo_Storage,Number_of_Iteration}, _Data) -> 

     Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded= Message_Partitioned_Alpha_Storage ++ [binary_to_integer(<<Message_Partitioned_Alpha_Head_Alter>>, 16)],
     Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded= Message_Partitioned_Bravo_Storage ++ [binary_to_integer(<<Message_Partitioned_Bravo_Head_Alter>>, 16)],
        lfsr_v0_00_02:tail_binary_to_integer_seize(),
    {
    next_state, {tail_binary_to_integer_seize,Message_Partitioned_Alpha_Tail_Alter, Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,
    Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data
    };

handle_event(cast, tail_binary_to_integer_seize, {tail_binary_to_integer_seize,Message_Partitioned_Alpha_Tail_Alter, Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,
Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data) -> 
    case[Message_Partitioned_Alpha_Tail_Alter,Message_Partitioned_Bravo_Tail_Alter ] of 
    [[],[]] ->
        lfsr_v0_00_02:register_tapping(),
        {
            next_state, {register_tapping,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data
        };
    _else -> 
        lfsr_v0_00_02:head_binary_to_integer_storing(),   
        {
        next_state, {head_binary_to_integer_storing,Message_Partitioned_Alpha_Tail_Alter, Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded, 
        Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration}, _Data
        }
    end;

handle_event(cast,register_tapping,{register_tapping,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,
Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data )->

    Second_Tapped= [lists:nth(2, X) bxor lists:nth(16, X)|| X <- [Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded]],
    Third_Tapped=  [lists:nth(3, X) bxor lists:nth(16, X)|| X <- [Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded]],
    Fifth_Tapped=  [lists:nth(5, X) bxor lists:nth(16, X)|| X <- [Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded]],
       
   lfsr_v0_00_02:alpha_register_shifting(),
    {
    next_state, {alpha_register_shifting,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,
    Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Second_Tapped,Third_Tapped,Fifth_Tapped,Number_of_Iteration},_Data
    }; 

handle_event(cast, alpha_register_shifting,{alpha_register_shifting,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,
Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Second_Tapped,Third_Tapped,Fifth_Tapped,Number_of_Iteration},_Data) ->

    First_Shift  = lists:sublist(Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,1) ++ [lists:nth(1,Second_Tapped)]++[lists:nth(1,Third_Tapped)] ++ lists:nthtail(3,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded),
    Second_Shift  = lists:sublist(First_Shift,4) ++ [lists:nth(1,Fifth_Tapped)] ++ lists:nthtail(5, First_Shift),
    Alpha_Shift = lists:nthtail(15,Second_Shift) ++ lists:sublist(Second_Shift,15),

    lfsr_v0_00_02:bravo_register_shifting(),
    {
    next_state, {bravo_register_shifting, Alpha_Shift,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,
    Second_Tapped,Third_Tapped,Fifth_Tapped, Number_of_Iteration},_Data
    }; 

handle_event(cast, bravo_register_shifting,{bravo_register_shifting, Alpha_Shift,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,
Second_Tapped,Third_Tapped,Fifth_Tapped,Number_of_Iteration},_Data )->
    First_Shift  = lists:sublist(Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,1) ++ [lists:nth(2,Second_Tapped)] ++ [lists:nth(2,Third_Tapped)] ++ lists:nthtail(3,Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded),
    Second_Shift  = lists:sublist(First_Shift,4) ++ [lists:nth(2,Fifth_Tapped)] ++ lists:nthtail(5, First_Shift),
    Bravo_Shift = lists:nthtail(15,Second_Shift) ++ lists:sublist(Second_Shift,15),

    lfsr_v0_00_02:stream_generate(),
    {
    next_state, {stream_generate, Alpha_Shift,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded, Bravo_Shift, Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data
    }; 

handle_event(cast,stream_generate,{stream_generate, Alpha_Shift,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded, Bravo_Shift, Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,Number_of_Iteration},_Data) ->
    case Number_of_Iteration of 
        0 -> 
            lfsr_v0_00_02:head_integer_to_binary_storing(),
            {
         next_state, {head_integer_to_binary_storing,Message_Partitioned_Alpha_Binary_to_Integer_Storage_Padded,[],
            Message_Partitioned_Bravo_Binary_to_Integer_Storage_Padded,[]}, _Data
            };

        _else ->
            Loops_Remaining =(Number_of_Iteration-1),
            io:format("Remaining Process Number: ~p~n",[Loops_Remaining]),
            io:format("Process:~p ~n", [Alpha_Shift++Bravo_Shift]),    
  
            lfsr_v0_00_02:register_tapping(),
        {
        next_state, {register_tapping, Alpha_Shift, Bravo_Shift, Loops_Remaining},_Data
        }
end;

handle_event(cast, head_integer_to_binary_storing,{head_integer_to_binary_storing,[Message_Partitioned_Alpha_Head_Alter|Message_Partitioned_Alpha_Tail_Alter],Message_Partitioned_Alpha_Storage,
[Message_Partitioned_Bravo_Head_Alter|Message_Partitioned_Bravo_Tail_Alter], Message_Partitioned_Bravo_Storage}, _Data) ->

    Message_Partitioned_Alpha_Integer_to_Binary_Storage_Padded= Message_Partitioned_Alpha_Storage ++ [integer_to_binary(Message_Partitioned_Alpha_Head_Alter, 16)],
    Message_Partitioned_Bravo_Integer_to_Binary_Storage_Padded= Message_Partitioned_Bravo_Storage ++ [integer_to_binary(Message_Partitioned_Bravo_Head_Alter, 16)],
    
    lfsr_v0_00_02:tail_integer_to_binary_seize(),
    {
    next_state, {tail_integer_to_binary_seize, Message_Partitioned_Alpha_Tail_Alter,Message_Partitioned_Alpha_Integer_to_Binary_Storage_Padded,
    Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Integer_to_Binary_Storage_Padded},_Data
    };


handle_event(cast, tail_integer_to_binary_seize,{tail_integer_to_binary_seize, Message_Partitioned_Alpha_Tail_Alter,Message_Partitioned_Alpha_Integer_to_Binary_Storage_Padded,
Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Integer_to_Binary_Storage_Padded},_Data) ->
    case [Message_Partitioned_Alpha_Tail_Alter,Message_Partitioned_Bravo_Tail_Alter] of 
        [[],[]] -> 
            io:format("*******Hexadecimal Output LFSR: ~p~n",[iolist_to_binary([Message_Partitioned_Alpha_Integer_to_Binary_Storage_Padded, Message_Partitioned_Bravo_Integer_to_Binary_Storage_Padded])]),

            {
        next_state,wait,_Data
            };
        _else ->
            lfsr_v0_00_02:head_integer_to_binary_storing(),
            {
        next_state, {head_integer_to_binary_storing,Message_Partitioned_Alpha_Tail_Alter,Message_Partitioned_Alpha_Integer_to_Binary_Storage_Padded,
        Message_Partitioned_Bravo_Tail_Alter,Message_Partitioned_Bravo_Integer_to_Binary_Storage_Padded},_Data
        }
end.


terminate(_Reason, _State, _Data) ->
    ok.

code_change(_OldVsn, State, Data, _Extra) ->
    {ok, State, Data}.
