%%%-------------------------------------------------------------------
%%% @author Michal Ptaszek <michal.ptaszek@erlang-solutions.com>
%%% @copyright (C) 2011, Erlang Solutions Ltd.
%%% @doc Test verifying that simple job works
%%%
%%% @end
%%% Created : 13 Apr 2011 by Michal Ptaszek <michal.ptaszek@erlang-solutions.com>
%%%-------------------------------------------------------------------
-module(ce_simple_job_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").

all() ->
    [{group, success}].

groups() ->
    [{success, [sequence], [adder,
                            word_counter]}].

init_per_group(_GroupName, _Config) ->
    application:start(mnesia),
    application:start(sasl),
    application:start(computerl).

end_per_group(_GroupName, _Config) ->
    application:stop(computerl),
    application:stop(sasl),
    application:stop(mnesia).

adder(_Config) ->
    ok.

word_counter(Config0) ->
    Config = proplists:get_value(simple_job, Config0),

    JobCfg = proplists:get_value(config, Config),
    Input = proplists:get_value(input, Config),

    {ok, Terms} = file:consult(JobCfg),
    {value, {_, simple_job, Opts}} = lists:keysearch(computation_type, 1, Terms),
    Output = proplists:get_value(output_file, Opts),

    file:delete(Output),

    {ok, Ref} = ce_input:compute(JobCfg, Input),
    {ok, OutputPath} = wait_for_job_to_finish(
                         Ref, proplists:get_value(job_timeout, Config, 10000)),

    true = filelib:is_file(OutputPath).

wait_for_job_to_finish(Ref, Timeout) ->
    receive
        {job_finished, Ref, OutputPath} ->
            {ok, OutputPath}
    after Timeout ->
            {error, timeout}
    end.
