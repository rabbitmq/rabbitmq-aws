-module(httpc_aws_config_tests).

-include_lib("eunit/include/eunit.hrl").

%% Return the parsed configuration file data
config_file_data_test() ->
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  Expectation = [
    {"default",
      [{aws_access_key_id, "default-key"},
       {aws_secret_access_key, "default-access-key"},
       {region, "us-east-1"}]},
    {"profile testing",
      [{aws_access_key_id, "foo1"},
       {aws_secret_access_key, "bar2"},
       {s3, [{max_concurrent_requests, 10},
             {max_queue_size, 1000}]},
       {region, "us-west-2"}]},
    {"profile no-region",
      [{aws_access_key_id, "foo2"},
       {aws_secret_access_key, "bar3"}]}
  ],
  ?assertEqual(Expectation,
               httpc_aws_config:config_file_data()).

%% Return the default configuration when the environment variable is set
config_file_test() ->
  os:putenv("AWS_CONFIG_FILE", "/etc/aws/config"),
  ?assertEqual("/etc/aws/config",
               httpc_aws_config:config_file()).

%% Return the default configuration path based upon the user's home directory
config_file_no_env_var_test() ->
  os:unsetenv("AWS_CONFIG_FILE"),
  os:putenv("HOME", "/home/gavinr"),
  ?assertEqual("/home/gavinr/.aws/config",
               httpc_aws_config:config_file()).


%% Return the parsed configuration file data
credentials_file_data_test() ->
  os:putenv("AWS_SHARED_CREDENTIALS_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_credentials.ini"])),
  Expectation = [
    {"default",
      [{aws_access_key_id, "foo1"},
       {aws_secret_access_key, "bar1"}]},
    {"development",
      [{aws_access_key_id, "foo2"},
       {aws_secret_access_key, "bar2"}]}
  ],
  ?assertEqual(Expectation,
               httpc_aws_config:credentials_file_data()).

%% Return the default configuration when the environment variable is set
credentials_file_test() ->
  os:putenv("AWS_SHARED_CREDENTIALS_FILE", "/etc/aws/credentials"),
  ?assertEqual("/etc/aws/credentials",
               httpc_aws_config:credentials_file()).

%% Return the default configuration path based upon the user's home directory
credentials_no_env_var_test() ->
  os:unsetenv("AWS_SHARED_CREDENTIALS_FILE"),
  os:putenv("HOME", "/home/gavinr"),
  ?assertEqual("/home/gavinr/.aws/credentials",
               httpc_aws_config:credentials_file()).


%% Return the home directory path based upon the HOME shell environment variable
home_path_test() ->
  os:putenv("HOME", "/home/gavinr"),
  ?assertEqual("/home/gavinr",
               httpc_aws_config:home_path()).

%% Test that the cwd is returned if HOME is not set in the shell environment
home_path_no_env_var_test() ->
  os:unsetenv("HOME"),
  ?assertEqual(filename:absname("."),
               httpc_aws_config:home_path()).


%% Test that an atom is returned when passing in an atom
ini_format_key_when_atom_test() ->
  ?assertEqual(test_key, httpc_aws_config:ini_format_key(test_key)).

%% Test that an atom is returned when passing in a list
ini_format_key_when_list_test() ->
  ?assertEqual(test_key, httpc_aws_config:ini_format_key("test_key")).

%% Test that an error is returned when passing in a binary
ini_format_key_when_binary_test() ->
  ?assertEqual({error, type}, httpc_aws_config:ini_format_key(<<"test_key">>)).


%% Test that a null value returns 0
maybe_convert_number_null_is_0_test() ->
  ?assertEqual(0, httpc_aws_config:maybe_convert_number(null)).

%% Test that an empty list value returns 0
maybe_convert_number_empty_list_is_0_test() ->
  ?assertEqual(0, httpc_aws_config:maybe_convert_number([])).

%% Test that a binary value with an integer returns the proper value
maybe_convert_number_empty_binary_test() ->
  ?assertEqual(123, httpc_aws_config:maybe_convert_number(<<"123">>)).

%% Test that a binary value with an float returns the proper value
maybe_convert_number_float_test() ->
  ?assertEqual(123.456, httpc_aws_config:maybe_convert_number(<<"123.456">>)).


%% Test that the appropriate error is raised when the specified path does not exist and the file is not found
ini_file_data_file_doesnt_exist_test() ->
  ?assertEqual({error, enoent}, httpc_aws_config:ini_file_data(filename:join([filename:absname("."), "bad_path"]), false)).

%% Test that the appropriate error is raised when the specified path does not exist and the file is found
ini_file_data_bad_path_test() ->
  ?assertEqual({error, enoent}, httpc_aws_config:ini_file_data(filename:join([filename:absname("."), "bad_path"]), true)).

%% Test that the appropriate error is raised when trying to read a file that doesn't exist
read_file_bad_path_test() ->
  ?assertEqual({error, enoent}, httpc_aws_config:read_file(filename:join([filename:absname("."), "bad_path"]))).

%% Test that the appropriate error is raised when trying to read a file that errors out when reading the line
read_file_bad_handle_test() ->
  {MegaSecs, Secs, MicroSecs} = now(),
  Name = lists:flatten(io_lib:format("~p-~p-~p.tmp", [MegaSecs, Secs, MicroSecs])),
  {ok, Handle} = file:open(Name, [write]),
  file:close(Handle),
  ?assertEqual({error,terminated}, httpc_aws_config:read_file(Handle, [])),
  file:delete(Name).

%% Test the profile value set in an environment variable is returned
profile_from_env_var_test() ->
  os:putenv("AWS_DEFAULT_PROFILE", "httpc-aws test"),
  ?assertEqual("httpc-aws test",
               httpc_aws_config:profile()).

%% Test the default profile value is returned when no environment variable is set
profile_no_env_var_test() ->
  os:unsetenv("AWS_DEFAULT_PROFILE"),
  ?assertEqual("default",
               httpc_aws_config:profile()).

%% Test that the proper config section is returned for the default profile
config_data_with_default_profile_test() ->
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  Expectation = [{aws_access_key_id, "default-key"},
                 {aws_secret_access_key, "default-access-key"},
                 {region, "us-east-1"}],
  ?assertEqual(Expectation, httpc_aws_config:config_data("default")).


%% Test that the proper config section is returned for the unprefixed testing profile
config_data_with_unprefixed_testing_profile_test() ->
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  Expectation = [{aws_access_key_id, "foo1"},
                 {aws_secret_access_key, "bar2"},
                 {s3, [{max_concurrent_requests, 10},
                       {max_queue_size, 1000}]},
                 {region, "us-west-2"}],
  ?assertEqual(Expectation, httpc_aws_config:config_data("testing")).

%% Test that an error is returned
config_data_with_no_config_file_test() ->
  os:unsetenv("AWS_CONFIG_FILE"),
  ?assertEqual({error, enoent}, httpc_aws_config:config_data("testing")).

%% Test that the correct region is returned from an environment variable
region_with_env_var_test() ->
  os:putenv("AWS_DEFAULT_REGION", "us-west-1"),
  ?assertEqual({ok, "us-west-1"}, httpc_aws_config:region()).

%% Test that the correct region is returned from the config file for the default profile
region_with_config_file_and_default_profile_test() ->
  os:unsetenv("AWS_DEFAULT_REGION"),
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  ?assertEqual({ok, "us-east-1"}, httpc_aws_config:region()).

%% Test that the correct region is returned from the config file for the specified profile
region_with_config_file_test() ->
  os:unsetenv("AWS_DEFAULT_REGION"),
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  ?assertEqual({ok, "us-west-2"}, httpc_aws_config:region("testing")).

%% Test that an error is returned when there is no config file, region, or EC2 instance metadata service
region_without_config_file_test() ->
  os:unsetenv("AWS_DEFAULT_REGION"),
  os:unsetenv("AWS_CONFIG_FILE"),
  ?assertEqual({error, undefined}, httpc_aws_config:region()).

%% Test that an error is returned when the config for the specified profile doesnt have a region
region_with_profile_without_region_test() ->
  os:unsetenv("AWS_DEFAULT_REGION"),
  os:putenv("AWS_CONFIG_FILE",
            filename:join([filename:absname("."), "test",
                           "test_aws_config.ini"])),
  ?assertEqual({error, undefined}, httpc_aws_config:region("no-region")).

%% Test stripping the az designation from the region
region_from_availability_zone_test() ->
  ?assertEqual("us-east-1", httpc_aws_config:region_from_availability_zone("us-east-1a")).

%% Test that the availability-zone URL is constructed correctly
instance_availability_zone_url_test() ->
  ?assertEqual("http://169.254.169.254/latest/meta-data/placement/availability-zone",
               httpc_aws_config:instance_availability_zone_url()).
