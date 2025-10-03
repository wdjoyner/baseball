Baseball sabermetric functions, in python/sagemath (sagemath.org)

This file is intended to mine data from Retrosheet event files.


#########################################################################
## To create the log file for a report of the form (for example)
## "Game states via Retrosheet: Errors in DET 2019 home games"
## perform the following steps:
## 1) add subdirectory "DET-home_2019" to events
## 2) run
##    sage: frequency_transitions_team_season(season = 2019, team="DET", post_season = False, save_game_files = True)
##    sage: Errors_DET_2019 = errors_in_homegames(season = 2019, team = "DET", verbose=True) 
## 3) Save screen output to "errors-in-DET-2019-homegames_sage-log.txt"
## 4) edit to a latex file.
##########################################################################

##########################################################################
## To structure the for loop over the EVA/EVN event files,
## Mike Emeigh <mwe55inncgmail.com> suggests:
##
## import glob
## import os
##
## os.chdir(os.path.expanduser(‘eventfile/directory’))
## for f in glob.iglob(‘*.E[D|V][A|N]’):
##########################################################################



* baseball_states()
* baseball_state_graph()
* game_id_list(season = 2022, team="BAL")
* visiting_team_list(season = 2022, team="BAL")
* game_states_list(season = 2022, team="BAL")
* list_of_homegame_filenames(season = 2023, team = "BAL")
* homegame_list(season = 2022, team="BAL", post_season = False)
* list_last_inning_team_season(season = 2022, team="BAL", post_season = False)
* convert_to_state_FC(current_game_state, play_record, season = 2022)
* convert_to_state_S(current_game_state, play_record, season = 2022)
* convert_to_state_D(current_game_state, play_record, season = 2022)
* convert_to_state_T(current_game_state, play_record, season = 2022)
* convert_to_state_E(current_game_state, play_record, season = 2023)
* convert_to_state(current_game_state, play_record, season = 2022)
* reset_state(cgs, season = 2022)
* separate_field_into_parts(field0)
* event_file_to_game_states(game_file)
* inning_ender(play_event, game_file)
* frequency_game_states(game_file, verbose=False)
* frequency_game_states_HT(game_file, verbose=False)
* frequency_game_states_VT(game_file, verbose=False)
* frequency_games_states(game_files, verbose=False)
* frequency_states_team_season(season = 2022, team="BAL", post_season = False) ##  WIP!!
* frequency_transition_states(game_file, verbose=False)
* inning_ender0(game_state, game_file) ## similar to inning_ender but different form of input
* frequency_transitions_states(game_files, verbose=False)
* frequency_transitions_team_season(season = 2022, team="BAL", post_season = False)
* save_game_event_log(game_outfile, master_file = "2023BAL.EVA", play_date = "202304080", post_season = False)
* how_many_calls_with_playerID_atbat(plyrid, games_file, play_call = "E", verbose=False)
* batter_during_call_list(games_file, play_call = "E")
* number_of_calls_per_batter(games_file, play_call = "E")
* retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl2023.csv")
* scores_in_gamefiles(gamefiles)
* scores_match(data, L)
* innings_pitched_in_game(game_file, ptchr, verbose=False)
* starting_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9,10], verbose=False)
* team_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9], verbose=False)
* errors_in_homegames(season = 2023, team = "BAL", verbose = False)
* runs_per_play_ht_all(season = 2023, team = "BAL", verbose = False)
* count_states_in_game_file(game_file, team = "home", verbose=False)
* count_states_in_error_log(log_file, team = "home", verbose=False)

   ** Utilities **
* retrosheet_scoring_diagram_unrotated()
* print_ascii_baseball_diamond()
* print_baseball_diamond(current_game_state = [0,0,0,0,1,0,0,0])
* plot_baseball_diamond(current_game_state = [0,0,0,0,1,0,0,0], print_title=True, game_state = False)
* csv_lines_with_match(input_csv_file, search_txt)
* retrosheet_playerID(player_id)
* strip_list_last_char(word_with_quotes)
* extract_date(s)  
* sorted_filenames(dir)
* list_indices(x, L)
* is_p_num_p_in_string(s)
* game_with_play(games_file, play)
* matrix_team_ranking(M, confidence="False")
* runs_rank_homegames(team = "BAL", season = 2022)
* remove_all_zero_rows_and_columns(A)
* wins_rank_homegames(team = "BAL", season = 2022, verbose = False)

last modified 2024-11-20 by wdj

copyright David Joyner, 2024
modified BSD license, meaning:
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of 
   conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of 
   conditions and the following disclaimer in the documentation and/or other materials 
   provided with the distribution.
 * Neither the name of the copyright holder nor the names of its contributors may be used to 
   endorse or promote products derived from this software without specific prior written permission.
source: https://en.wikipedia.org/wiki/BSD_licenses
