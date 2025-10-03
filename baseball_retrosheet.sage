"""
Baseball sabermetric functions, in python/sagemath

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

"""
####################### global imports:

from sage.misc.verbose import verbose

####################### global constants:

import platform
if platform.system()=="Linux":
    retrosheet_directory = "/home/wdj/baseball/retrosheet-databases/events/"
else:
    retrosheet_directory = "/Users/davidjoyner/baseball/retrosheet-data/events/"

info_inning_parameter = 9   ## typical length of game (in innings),
                            ## but for double header games, it could be different
                            ## check last digit/numeral in the id record.

#### below list from https://www.retrosheet.org/TEAMABR.TXT

NL_teams = [("ARI","NL","Arizona","Diamondbacks"), ("ATL","NL","Atlanta","Braves"),
            ("CHN","NL","Chicago","Cubs"), ("CIN","NL","Cincinnati","Reds"),
            ("COL","NL","Colorado","Rockies"), ("LAN","NL","Los Angeles","Dodgers"),
            ("SDN","NL","San Diego","Padres"), ("MIA","NL","Miami","Marlins"),
            ("MIL","NL","Milwaukee","Brewers"), ("NYN","NL","New York","Mets"),
            ("PHI","NL","Philadelphia","Phillies"), ("PIT","NL","Pittsburgh","Pirates"),
            ("SFN","NL","San Francisco","Giants"), ("SLN","NL","St. Louis","Cardinals"),
            ("WAS","NL","Washington","Nationals")
	   ]

NL_team_names = [x[0] for x in NL_teams]

AL_teams = [("ANA","AL","Anaheim","Angels"), ("BAL","AL","Baltimore","Orioles"),
            ("BOS","AL","Boston","Red Sox"), ("CHA","AL","Chicago","White Sox"),
            ("CLE","AL","Cleveland","Indians"), ("DET","AL","Detroit","Tigers"),
            ("HOU","AL","Houston","Astros"), ("KCA","AL","Kansas City","Royals"),
            ("MIN","AL","Minnesota","Twins"), ("NYA","AL","New York","Yankees"),
            ("OAK","AL","Oakland","Athletics"), ("SEA","AL","Seattle","Mariners"),
            ("TBA","AL","Tampa Bay","Devil Rays"), ("TEX","AL","Texas","Rangers"),
            ("TOR","AL","Toronto","Blue Jays")
	   ]

AL_team_names = [x[0] for x in AL_teams]

MLB_teams = NL_teams + AL_teams

MLB_team_names = NL_team_names + AL_team_names

RR10 = RealField(prec=12)

	
###################### state functions

def baseball_states():
    """
    Returns the (lexicographically sorted) list of 24 states.

    EXAMPLES:
        sage: L = baseball_states()
        sage: len(L)
        24
        sage: L[0]
         (0, 0, 0, 0)
        sage: L[23]
         (2, 1, 1, 1)

    """
    BB_states = [(0,0,0,0),(1,0,0,0),(2,0,0,0),(0,1,0,0),(1,1,0,0),(2,1,0,0),(0,0,1,0),(1,0,1,0),(2,0,1,0),(0,0,0,1),(1,0,0,1),(2,0,0,1),(0,1,1,0),(1,1,1,0),(2,1,1,0),(0,1,0,1),(1,1,0,1),(2,1,0,1),(0,0,1,1),(1,0,1,1),(2,0,1,1),(0,1,1,1),(1,1,1,1),(2,1,1,1)]
    return BB_states
    
def baseball_state_graph():
    """
    Returns the baseball state graph with 24 vertices and no loops.

    EXAMPLES:
        sage: Gamma = baseball_state_graph()
        sage: len(Gamma.vertices())
        24
        sage: len(Gamma.edges())
        182
        sage: Gamma.is_connected()
        True
        sage: Gamma.is_regular()
        False
        sage: print(Gamma.adjacency_matrix())
        [0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
        [1 0 1 1 1 1 1 1 0 1 1 0 1 0 0 0 1 0 0 0 0 0 0 0]
        [1 1 0 1 1 1 1 1 0 1 1 0 1 0 0 0 1 0 0 0 0 0 0 0]
        [1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 0 1 0 0 0]
        [1 1 1 1 0 1 1 1 0 1 1 0 1 0 0 0 1 0 0 0 0 0 0 0]
        [1 1 1 1 1 0 1 1 0 1 1 1 1 1 1 0 1 1 1 0 1 0 0 0]
        [1 1 1 1 1 1 0 1 0 1 1 1 1 1 1 0 1 1 1 0 1 0 0 0]
        [1 1 1 1 1 1 1 0 0 1 1 1 1 1 1 0 1 1 1 1 1 1 1 0]
        [1 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0]
        [0 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 0 1 0 0 0]
        [0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 0 1 0 0 0]
        [0 0 0 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 0]
        [0 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 0 0 0]
        [0 0 0 1 0 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 1 0]
        [0 0 0 1 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1 0]
        [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1 1]
        [0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 1]
        [0 0 0 1 0 1 1 1 0 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1]
        [0 0 0 1 0 1 1 1 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1]
        [0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 1 1 1 1 0 1 1 1 1]
        [0 0 0 1 0 1 1 1 0 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1]
        [0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 1 1 1 1 1 1 0 1 1]
        [0 0 0 0 0 0 0 1 0 0 0 1 0 1 1 1 1 1 1 1 1 1 0 1]
        [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0]
        sage: print(Gamma.degree_sequence())
        [22, 20, 18, 18, 18, 18, 18, 18, 18, 18, 18, 17, 17, 17, 15, 12, 12, 12, 11, 11, 11, 9, 8, 8]

    """
    BB_states = baseball_states()
    # 0 outs
    L = [(0,1,0,0), (0,0,1,0), (0,0,0,1), (1,0,0,0)]
    N0000 = [[(0,0,0,0), x] for x in L]
    L = [(0,0,0,0), (0,0,1,0), (0,0,0,1), (0,1,1,0),  (0,1,0,1),  (0,0,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (2,0,0,0)]
    N0100 = [[(0,1,0,0), x] for x in L]
    L = [ (0,0,0,0), (0,1,0,0), (0,0,0,1), (0,1,1,0),  (0,1,0,1),  (0,0,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (2,0,0,0)]
    N0010 = [[(0,0,1,0), x] for x in L]
    L = [(0,0,0,0), (0,1,0,0), (0,0,1,0), (0,1,0,1),  (0,0,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (2,0,0,0)]
    N0001 = [[(0,0,0,1), x] for x in L]
    L = [(0,0,0,0), (0,1,0,0), (0,0,1,0), (0,0,0,1), (0,1,0,1), (0,0,1,1), (0,1,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N0110 = [[(0,1,1,0), x] for x in L]
    L = [(0,0,0,0), (0,1,0,0), (0,0,1,0), (0,0,0,1), (0,1,1,0), (0,0,1,1), (0,1,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N0101 = [[(0,1,0,1), x] for x in L]
    L = [(0,0,0,0), (0,1,0,0), (0,0,1,0), (0,0,0,1), (0,1,1,0), (0,1,0,1), (0,1,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N0011 = [[(0,0,1,1), x] for x in L]
    L = [(0,0,0,0), (0,1,0,0), (0,0,1,0), (0,0,0,1),  (0,1,1,0), (0,1,0,1), (0,0,1,1), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N0111 = [[(0,1,1,1), x] for x in L]
    L = [(1,1,0,0), (1,0,1,0), (1,0,0,1), (2,0,0,0)]
    N1000 = [[(1,0,0,0), x] for x in L]
    L = [(1,0,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1),  (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N1100 = [[(1,1,0,0), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,0,1), (1,1,1,0), (1,1,0,1),  (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N1010 = [[(1,0,1,0), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N1001 = [[(1,0,0,1), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,0,1), (1,0,1,1), (1,1,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N1110 = [[(1,1,1,0), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,0,1,1), (1,1,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N1101 = [[(1,1,0,1), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,0,1), (1,1,0,1), (1,1,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N1011 = [[(1,0,1,1), x] for x in L]
    L = [(1,0,0,0), (1,1,0,0), (1,0,1,0), (1,0,0,1), (1,1,1,0), (1,1,0,1), (1,0,1,1), (2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1), (2,1,1,1)]
    N1111 = [[(1,1,1,1), x] for x in L]
    L = [(2,1,0,0), (2,0,1,0), (2,0,0,1)]
    N2000 = [[(2,0,0,0), x] for x in L]
    L = [(2,0,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N2100 = [[(2,1,0,0), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N2010 = [[(2,0,1,0), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,1,0), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N2001 = [[(2,0,0,1), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,0,1), (2,0,1,1), (2,1,1,1)]
    N2110 = [[(2,1,1,0), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,0,1,1), (2,1,1,1)]
    N2101 = [[(2,1,0,1), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,1,1,1)]
    N2011 = [[(2,0,1,1), x] for x in L]
    L = [(2,0,0,0), (2,1,0,0), (2,0,1,0), (2,0,0,1), (2,1,1,0), (2,1,0,1), (2,0,1,1)]
    N2111 = [[(2,1,1,1), x] for x in L]
    E0 = [sorted(e) for e in N0000+N0100+N0010+N0001+N0110+N0101+N0011+N0111]
    E1 = [sorted(e) for e in N1000+N1100+N1010+N1001+N1110+N1101+N1011+N1111]
    E2 = [sorted(e) for e in N2000+N2100+N2010+N2001+N2110+N2101+N2011+N2111]
    Gamma = Graph([BB_states, E0+E1+E2])
    return Gamma

######## event file functions

def game_id_list(season = 2022, team="BAL"):
    """
    This will read in a retrosheet event file <season><team>.eva
    (all events during home games by <team> in the <season> regular season.
    It returns the list of dates the teams played (in chronological order).

    EXAMPLES:
        sage: L = game_id_list(season = 2022, team="BAL")
        Finished reading file 2022BAL.EVA
        sage: len(L)
        81
        sage: print(L)
        ['202204110', '202204120', '202204130', '202204150', '202204160', '202204170',
         '202204290', '202204300', '202205010', '202205020', '202205030', '202205040',
         '202205050', '202205081', '202205082', '202205090', '202205160', '202205170', 
          ... ,
         '202209230', '202209240', '202209250', '202210030', '202210051', '202210052']

    """
    L_id = []
    GSL = game_states_list(season, team)
    print("Finished reading file "+str(season)+team + ".EVA")
    for x in GSL:
        if str(season) in x[0]:
            L_id = L_id + [x[0]]
    return L_id


def visiting_team_list(season = 2022, team="BAL"):
    """
    This will read in a retrosheet event file <season><team>.eva
    (all events during home games by <team> in the <season> regular season.
    It returns the list of visiting teams played (in alphabetical order).

    EXAMPLES:
        sage: L = visiting_team_list(season = 2022, team="BAL")
        sage: print(L)
         ['BOS', 'TBA', 'SEA', 'OAK', 'CHN', 'TOR', 'DET', 'HOU', 'NYA', 'CHA', 'KCA',
          'MIN', 'MIL', 'WAS', 'ANA', 'CLE', 'TEX', 'PIT']

    """
    L_visit = []
    GSL = game_states_list(season, team)
    n0 = len(GSL)
    for i in range(n0):
        gamei = GSL[i]
        L_visit = L_visit + [gamei[1]]
    return list(Set(L_visit))
    
def game_states_list(season = 2022, team="BAL", verbose=False):
    """
    This will read in a retrosheet event file <season><team>.eva
    (all events during home games by <team> in the <season> regular season.
    The option verbose=True also prints out the total number of plays
    by the ht in each game.

    By reading in each so-called play record type, this function parses
    the fields and saves the data into lists. These lists are used to 
    output the (final) list of all states occurring in each game of the
    <season> in which <team> is playing a home game, chronologically ordered.

    The outputted list is organized as follows:
    It is a list of lists, each sublist associated to a game in the given
    season, with the given team as the home team. Each sublist
    consists of 
    (0) the game date (only once, at the head of the sublist), and for each play in the game:
    (1) the visiting team,
    (2) the home team,
    (3) the inning,
    (4) the team at bat,
    (5) the 6th field in the play record,
    (6) the game number for that season,
    (7) the play number of that year.

    EXAMPLES:
        sage: game_states_BAL2022 = game_states_list(season = 2022, team="BAL")
        sage: len(game_states_BAL2022) # number of home games
         81
        sage: game_states_BAL2022[-1][:10] # first 10 entries for last home game
         ['202210052', 'TOR', 'BAL', '1', 'TOR', 'S9/G34', 79, 13057, '1', 'TOR']
        sage: game_states_BAL2022[0][:10] # first 10 entries for 1st home game
         ['202204110', 'MIL', 'BAL', '1', 'MIL', '53/G5', 0, 53, '1', 'MIL']
        sage: number_of_B1 = 0
        sage: for i in range(n0):
        ....:     n1 = len(game_states_BAL2022[i])
        ....:     #print(n0, n1)
        ....:     for j in range(1,n1):
        ....:         if "B-1" in game_states_BAL2022[i][5]:
        ....:             #print(game_states_BAL2022[i][5])
        ....:             number_of_B1 = number_of_B1 + 1
        ....: 
        sage: number_of_B1
        427
        sage: S_home = []
        ....: S_visit = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and not("BAL" == gamei[j-1]) and ("S" == gamei[j][0]) and not("SB" in gamei[j]):
        ....:             S_visit = S_visit +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(S_visit)/81.0
        7.02469135802469
        sage: S_home = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and ("BAL" == gamei[j-1]) and ("S" == gamei[j][0]) and not("SB" in gamei[j]):
        ....:             S_home = S_home +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(S_home)/81.0
        5.66666666666667
        sage: D_home = []
        ....: D_visit = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and not("BAL" == gamei[j-1]) and ("D" == gamei[j][0]) and not("DP" in gamei[j]):
        ....:             D_visit = D_visit +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(D_visit)/81.0
        1.83950617283951
        sage: D_home = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and ("BAL" == gamei[j-1]) and ("D" == gamei[j][0]) and not("DP" in gamei[j]):
        ....:             D_home = D_home +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(D_home)/81.0
        1.75308641975309
        sage: T_home = []
        ....: T_visit = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and not("BAL" == gamei[j-1]) and ("T" == gamei[j][0]) and not("TP" in gamei[j]):
        ....:             T_visit = T_visit +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(T_visit)/81.0
        0.0864197530864197
        sage: T_home = []
        ....: for i in range(n0):
        ....:     gamei = game_states_BAL2022[i]
        ....:     n1 = len(gamei)
        ....:     for j in range(1,n1-2):
        ....:         if (gamei[j-1] in teams) and ("BAL" == gamei[j-1]) and ("T" == gamei[j][0]) and not("TP" in gamei[j]):
        ....:             T_home = T_home +[(gamei[j],gamei[j+1], gamei[j+2])]
        ....: 
        sage: len(T_home)/81.0
        0.111111111111111


    """
    if team in AL_team_names:
        event_file = retrosheet_directory+str(season) + team + ".EVA"
    if team in NL_team_names:
        event_file = retrosheet_directory+str(season) + team + ".EVN"
    f = open(event_file,"r")
    lines = f.readlines()
    #print(lines[0].split(","))
    N0 = len(lines)
    #print(N0)
    id_indices = []
    L0 = []
    L1 = []
    home_team = []
    visiting_team = []
    dates = []
    ht_plays = []
    for j in range(N0):
        line = lines[j]
        if line[:2] == "id":
            id_indices = id_indices+[j]
            L0 = L0 + [[line[-10:-2], lines[j+2][-4:-1], lines[j+3][-4:-1]]]
            dates = dates + [line[-10:-1]]
            visiting_team = visiting_team + [lines[j+2][-4:-1]]
            home_team = home_team + [lines[j+3][-4:-1]]
    #print(dates[0], dates[79])
    ht_plays_count = 0
    num_games = len(id_indices)
    for i in range(num_games-1):
        j0 = id_indices[i]
        j1 = id_indices[i+1]
        #print(j0,j1)
        for j in range(j0,j1):
            line = lines[j]
            if line[:4] == "play":
                if line[7] == "1": ##### tests if ht is at bat
                    ht_plays_count = ht_plays_count + 1
                spl = line.split(",")
                ht = home_team[i]
                vt = visiting_team[i]
                if int(spl[2])==0:
                    L1 = L1 + [L0[i]+[spl[1], vt, spl[6].rstrip()] + [i,j]]
                if int(spl[2])==1:
                    L1 = L1 + [L0[i]+[spl[1], ht, spl[6].rstrip()] + [i,j]]
        ht_plays = ht_plays +[ht_plays_count]
    j0 = id_indices[num_games-1]
    j1 = N0
    i = num_games-1
    #print(i,j0,j1)
    for j in range(j0,j1):
        line = lines[j]
        if line[:4] == "play":
            #print(j,line, int(line[7]))
            if line[7] == "1": ##### tests if ht is at bat
                ht_plays_count = ht_plays_count + 1
            spl = line.split(",")
            ht = home_team[i]
            vt = visiting_team[i]
            if int(spl[2])==0:
                L1 = L1 + [L0[i]+[spl[1], vt, spl[6].rstrip()] + [i,j]]
            if int(spl[2])==1:
                L1 = L1 + [L0[i]+[spl[1], ht, spl[6].rstrip()] + [i,j]]
    ht_plays = ht_plays +[ht_plays_count]
    #print(ht_plays_count, len(visiting_team))
    L2 = []
    for x in L1:
        date = x[0]
        vt = x[1]
        ht = x[2]
        L2 = L2 + [[date, vt, ht]]
    L3 = []
    for j in range(num_games):
        y = [dates[j].rstrip(), visiting_team[j], home_team[j]]
        L4 = [dates[j], visiting_team[j], home_team[j]] # start of full list of plays for the y game
        for x in L1:
            len_x = len(x)
            if y == [x[0], x[1], x[2]]:
                L4 = L4 + [x[3+i] for i in range(len_x-3)]
        L3 = L3 + [L4]
    if verbose:
       #print("Number of plays by ht: ", ht_plays_count)
       return L3, ht_plays_count
    f.close()
    return L3

def separate_field_into_parts(field0):
    """
    Returns part 1, part 2, and part(s) 3.

    EXAMPLE:
        sage: field0 = "K"
        sage: separate_field_into_parts(field0)
         ('K', [], [])
        sage: field0 = "FC4/G34.3-H;1-2(E4);B-1"
        sage: separate_field_into_parts(field0)
         ('FC4', ['G34'], ['3-H', '1-2(E4)', 'B-1'])
        sage: field0 = "D8/L78XD+.2-H"
        sage: separate_field_into_parts(field0)
         ('D8', ['L78XD+'], ['2-H'])
        sage: field0 = "FC1/BG1S-.2-H(E1/TH)(NR)(UR);1-2;B-1"
        sage: separate_field_into_parts(field0)
         ['FC1', ['BG1S-'], ['2-H(E1/TH)(NR)(UR)', '1-2', 'B-1']]
        sage: pr = "play,6,1,mullc002,02,.1C+1FF>P,SB2"
        sage: spl_rec = pr.split(",")
        sage: parts = separate_field_into_parts(spl_rec[6]); parts
         ('SB2', [], [])
        sage: field0 = "5(2)3/GDP/G56.1-2"
        sage: separate_field_into_parts(field0)
         ['5(2)3', ['GDP', 'G56'], ['1-2']]

    """
    ############ change order of the below construction ########## BUG!!!
    ####### first split by "."
    ####### then split by "/" (unless "/" is inside "(...)" as in "(E2/TH)"
    ################################# 
    count_p = field0.count(".")
    if count_p == 1:
        field_p = field0.split(".")
        field1p = field_p[0]
        parts12p = field1p.split(";")
        field2p = field_p[1]
        parts23p = field2p.split(";")
        if not("E" in field1p):
            parts12 = field1p.split("/")
        else:
            parts12 = [field1p, []]
        #print(field1p, field2p, parts12, parts12p, parts23p)
        if len(parts12)==1:
            if not(";" in field1p):
                part1 = parts12[0]
                part2 = []
            else:
                part1 = parts12p[0]
                part2 = parts12p[1]
            #part2 = parts12[1]
            #print(len(parts12p), part2)
            return ([part1]+[[part2]]+[parts23p])
        if len(parts12)>1:
            part1 = parts12[0]
            part2 = parts12[1:]
            #print(part1, part2,parts23p)
            return ([part1]+[part2]+[parts23p])
    field1 = field0.split("/")
    n1 = len(field1)
    if n1 == 1:
        field1 = field0.split(".")
        part1 = field1[0]
        part2 = []
        if len(field1)>1:
            part3 = field1[1].split(";")
        else:
            part3 = []
    else:
        part1 = field1[0]
        part2 = []
        part3 = []
    for i in range(1,n1):
        if not("." in field1[i]):
            part2 = part2+[field1[i]]
        else:
            part2 = part2+[field1[i].split(".")[0]]
        #print(field1[i].split("."))
        if len(field1[i].split("."))>1:
            #print(field1[i].split(".")[1])
            if ";" in field1[i].split(".")[1]:
                #print((field1[i].split(".")[1]).split(";")[-1], field1[i].split(";")[1:])
                part3 = part3 + [(field1[i].split(".")[1]).split(";")[0]] + field1[i].split(";")[1:]
            else:
                #print(-1,field1[i].split(".")[1:])
                part3 = part3 + field1[i].split(".")[1:]
        else:
            part3 = part3 + [[]]
    return part1, part2, part3
    

def convert_to_state_FC(current_game_state, play_record, season = 2023):
    """
    *********** programming in progress **********

    This function takes a play record and current game state and returns
    the modified game state.

    ************************************************************************
    ********* every convert function needs a season added    **********
    ********* for accurate reset_state values                **********
    ************************************************************************


    EXAMPLE:
        sage: play_record = "play,3,0,lemad001,21,BCBX,FC4/G4.B-1"
        sage: current_game_state = (0,0,1,0,1,0,0,0)
        sage: convert_to_state_FC(current_game_state, play_record)
        sage: play_record = "play,3,1,mullc002,01,FX,FC/G4.2-3;1X2(4E6)(6);B-1"
        sage: cgs = (1, 1, 1, 0, 3, 0, 2, 1)
        sage: cgs = convert_to_state_FC(cgs, play_record); cgs
        (2, 1, 0, 1, 3, 0, 2, 1)

    *********** programming in progress **********

    """
    ZZ8 = ZZ^8
    v = ZZ8(current_game_state)
    gm_st = v
    spl_rec = play_record.split(",")
    field6 = spl_rec[-1]
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    if len(part3)>0 and len(part3[0])>0:
        sum_part3 = ''.join(part3)
    elif (len(part3)==2) and (len(part3[0])==0):   ## part3 has form [ [], "xyz"]
        sum_part3 = part3[1] 
    else:
        sum_part3 = part3 
    outs = gm_st[0]
    runner_on_1st = gm_st[1]
    runner_on_2nd = gm_st[2]
    runner_on_3rd = gm_st[3]
    inning = gm_st[4]
    vs = gm_st[5]
    hs = gm_st[6]
    team_at_bat = gm_st[7]
    ### test for not "X" but with "FC" 
    if ("FC" in part1) and (len(part3)==1) and not("X" in sum_part3) and (len(part3[0])==0):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_3rd = 0
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and not("X" in sum_part3) and ("3-H" in part3[0]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and not("X" in sum_part3) and ("2-H" in part3[0]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and not("X" in sum_part3) and ("1-3" in part3[0]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("B-2" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1-H" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-2" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1XH" in part3[0]) and ("E" in part3[0]) and ("B-3" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("3XH" in part3[0]) and ("E" in part3[0]) and ("B-2" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("2X3" in part3[0]) and ("E" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1X3" in part3[0]) and ("E" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("BX2" in part3[2] and not("E" in part3[2])):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("testFCwithlenpart3=3", ("FC" in part1), (len(part3)==3), ("3XH" in part3[0] and not("E" in part3[0])))
    if ("FC" in part1) and (len(part3)==3) and ("3XH" in part3[0] and not("E" in part3[0])) and ("2-H" in part3[1]) and ("B-2" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0] and ("E" in part3[1])) and ("1X3" in part3[1]) and ("B-1" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3XH" in part3[0] and not("E" in part3[0])) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3XH" in part3[0] and ("E" in part3[0])) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2XH" in part3[0] and not("E" in part3[0])) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs + 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2-H" in part3[0] and ("1X2" in part3[1]) and ("E" in part3[1])) and not(is_p_num_p_in_string(part3[1])) and ("B-1" in part3[2]):
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2X3" in part3[1] and not("E" in part3[1])) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3XH" in part3[0] and not("E" in part3[0])) and ("2X3" in part3[1] and not("E" in part3[1])) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 2
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2X3(" in part3[1] and not("E" in part3[1])) and ("BX2" in part3[2]) and not("E" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 2
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        #outs = outs + 2
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 2
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3X3" in part3[0]) and ("1-2" in part3[1]) and ("BX1" in part3[2]) and not("E" in sum_part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 2
        runner_on_3rd = 1
        outs = outs + 2
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(part1, part2, part3,("FC" in part1), (len(part3)==4), ("3-H" in part3[0]), ("2-3" in part3[1]), ("1x2" in part3[2]), ("B-1" in part3[3]), not("E" in sum_part3))
    if ("FC" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1X3" in part3[2]) and ("E" in part3[2]) and ("B-1" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1X2" in part3[2]) and ("B-1" in part3[3]) and not("E" in sum_part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("3-H" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("1-H" in part3[0]) and ("B-2" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and ("DP" in part2) and (len(part3)==2) and ("3XH" in part3[0]) and ("BX1" in part3[1]) and not("E" in sum_part3):
        outs = outs+2
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        #runner_on_3rd = 0
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and ("DP" in part2) and (len(part3)==2) and ("3XH" in part3[0]) and ("BX2" in part3[1]) and not("E" in sum_part3):
        outs = outs+2
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        #runner_on_3rd = 0
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("2X2" in part3[0]) and ("BX1" in part3[1]) and not("E" in sum_part3):
        outs = outs+2
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        #runner_on_3rd = 0
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ######### next case is tricky with a double negation on the out
    if ("FC" in part1) and ("G" in part2) and (len(part3)==2) and ("3XH" in part3[0] and "E" in part3[0] and not(is_p_num_p_in_string(part3[0]))) and ("2-3" in part3[1]):
        #print(parts, 2)
        #outs = outs + 1 ## the runner on 3rd was not out, but scored due to the error E, unless there is also a "(num)" substring
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(parts, ("FC" in part1), ("G" in part2), (len(part3)==3), ("2-3" in part3[0]), ("1X2" in part3[1]), ("E" in part3[1]), is_p_num_p_in_string(part3[1]), ("B-1" in part3[2]), 2)
    if ("FC" in part1) and ("G" in part2[0]) and (len(part3)==3) and ("2-3" in part3[0]) and ("1X2" in part3[1]) and ("E" in part3[1]) and (is_p_num_p_in_string(part3[1])) and ("B-1" in part3[2]):
        #print(parts, is_p_num_p_in_string(part3[1]), 2)
        outs = outs + 1 ## the runner on 2nd was out, then not out on "E", the out because of a "(num)" substring
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and ("G" in part2) and (len(part3)==1) and ("1X2" in part3[0] and "E" in part3[0] and not(is_p_num_p_in_string(part3[0]))):
        #print(parts, 2)
        #outs = outs + 1 ## the runner on 3rd was not out, but scored due to the error E
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and ("G" in part2) and (len(part3)==1) and ("1X3" in part3[0] and "E" in part3[0] and not(is_p_num_p_in_string(part3[0]))):
        #print(parts, 2)
        #outs = outs + 1 ## the runner on 3rd was not out, but scored due to the error E
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and ("3XH" in part3[0]):
        #print(parts, 2)
        outs = outs + 1
        runner_on_1st = 1
        #runner_on_2nd = 1
        runner_on_3rd = 0
        #if team_at_bat == 0:
        #    vs = vs + 2
        #else:
        #    hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part2)>0) and ("G" in part2[0]) and (len(part3)==3) and ("2-3" in part3[0]) and ("1X2" in part3[1] and "E" in part3[1] and not(is_p_num_p_in_string(part3[0]))) and ("B-1" in part3[2]):
        #print(parts, 2)
        #outs = outs + 1 ## the runner on 3rd was not out, but scored due to the error E
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-2" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-1" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(("FC" in part1), (len(part3)==4), ("3XH" in part3[0]), ("E" in part3[0]), ("2-3" in part3[1]), ("1-2" in part3[2]), ("B-1" in part3[3]))
    if ("FC" in part1) and (len(part3)==4) and ("3XH" in part3[0] and "E" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==4) and ("3XH" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-2" in part3[3]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3XH" in part3[0]) and ("2-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        outs = outs + 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1-H" in part3[0]) and ("B-3" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("2-3" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and not("X" in sum_part3) and ("1-2" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("1X2" in part3[0] and "E" in part3[0]) and ("B-1" in part3[1]):
        #print(parts, 2)
        #print(part1, part2, part3)
        #outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("2-3" in part3[0]) and ("1X2" in part3[1] and "E" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and ("2X2" in part3[0]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        #runner_on_1st = 1
        runner_on_2nd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==1) and ("2X3" in part3[0]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3X" in part3[0]) and ("2-3" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("3X" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and not("X" in sum_part3) and ("2-3" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ### test for runner outs "X" with batter single "FC" 
    if ("FC" in part1) and (len(part3)==2) and ("X" in sum_part3) and not("B-1" in part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        if base == "B":
            runner_on_1st = 0
        if base == "2":
            runner_on_2nd = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==2) and ("X" in sum_part3) and ("B-1" in part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        if base == "2":
            runner_on_2nd = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("X" in sum_part3) and ("1-2" in part3) and ("B-1" in part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        if base == "1":
            runner_on_1st = 0
        if base == "2":
            runner_on_2nd = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("1X2" in part3[1]) and ("E" in part3[1]) and ("2-3" in part3[0]) and ("B-1" in part3[2]):
        #print(parts, 2)
        #print(part1, part2, part3)
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("FC" in part1) and (len(part3)==3) and ("X" in sum_part3) and ("2-3" in part3) and ("B-1" in part3):
        #print(parts, 2)
        #print(part1, part2, part3)
        outs = outs + 1
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "2":
        #    runner_on_2nd = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(part1, part2, part3,"FC" == part1[:2], len(part3) == 3 ,part3[0][:3] == "3-H", part3[1][:3] == "1-2",part3[2][:3] == "B-1"  )
    ######### need lots more cases ... ###########
    if "FC" == part1[:2] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
        if v[7]==0:
            v = v + ZZ8((0,0,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "FC" == part1[:2] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
        if v[7]==0:
            v = v + ZZ8((0,0,-1,1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,-1,1,0,0,1,0))
        return reset_state(v, season)
    if "FC" == part1[:2] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        ## in this case, there was already a runner on 1st+2nd+3rd, so we don't add one
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "FC" == part1[:2] and len(part3) == 2 and part3[0][:3] == "1-3" and part3[1][:3] == "B-1":
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,0,1,0,0,0,0))
    if "FC" == part1[:2] and len(part3) == 2 and part3[0][:3] == "1-2" and part3[1][:3] == "B-1":
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,1,0,0,0,0,0))
    if "FC" == part1[:2] and (len(part3) == 1) and part3[-1][:3] == "B-1":
        if v[1]==0:
            v = v + ZZ8((0,1,0,0,0,0,0,0))
        elif v[2]==0: # runner on 1st is forced to 2nd
            v = v + ZZ8((0,0,1,0,0,0,0,0))    
    return reset_state(v, season)


def convert_to_state_S(current_game_state, play_record, season = 2023):
    """
    *********** programming in progress **********

    This function takes a play record and current game state and returns
    the modified game state.

    ** It only works currently if the play is a S and does NOT (yet)
       account for any runners on base advancing. **
    ** The code below must include use of part(s) 2 and part(s) 3
       of the "parts" variable below. **

    EXAMPLE:
        sage: play_record = "play,3,0,lemad001,21,BCBX,S4/G4"
        sage: current_game_state = (0,0,1,0,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 1, 0, 1, 0, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S4/G4.3-H"
        sage: current_game_state = (0,0,0,1,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 0, 1, 1, 0, 0)
        sage: play_record = "play,3,1,duckd001,21,BCBX,S4/G4.1-H"
        sage: current_game_state = (0,1,0,0,1,0,0,1)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 0, 1, 0, 1, 1)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S4/G4.1-H"
        sage: current_game_state = (0,1,0,0,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 0, 1, 1, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S7/L7.1-3"
        sage: current_game_state = (0,1,0,0,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 1, 1, 0, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S7/L7.2-3"
        sage: current_game_state = (0,0,1,0,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 1, 1, 0, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S7/L7.3-H.2-H"
        sage: current_game_state = (0,0,1,1,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 0, 0, 1, 2, 0, 0)
        sage: play_record = "play,3,1,duckd001,21,BCBX,S7/L7.3-H.2-H"
        sage: current_game_state = (0,0,1,1,1,0,0,1)
        sage: convert_to_state_S(current_game_state, play_record)
        (0, 1, 0, 0, 1, 0, 2, 1)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S4/G4.3-H.2-3.1-2"
        sage: current_game_state = (0,1,1,1,1,0,0,0)
        sage: convert_to_state_S(current_game_state, play_record)
         (0, 1, 1, 1, 1, 1, 0, 0)

    """
    ZZ8 = ZZ^8
    v = ZZ8(current_game_state)
    spl_rec = play_record.split(",")
    field6 = spl_rec[-1]
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    if len(part3)>0 and len(part3[0])>0:
        sum_part3 = ''.join(part3)
    elif len(part3)==2 and part3[0]==[]:   ## part3 has form [ [], "xyz"]
        sum_part3 = part3[1] 
    else:
        sum_part3 = part3 
    outs = v[0]
    runner_on_1st = v[1]
    runner_on_2nd = v[2]
    runner_on_3rd = v[3]
    inning = v[4]
    vs = v[5]
    hs = v[6]
    team_at_bat = v[7]
    #if "BX2(74)" in part3:
    #print(parts, "test2")
    if "S" == part1[0] and (len(part3)>0) and len(part3[0]) == 0:
        #print("S", v)
        if (v[1] == 0):
            v = v + ZZ8((0,1,0,0,0,0,0,0))
            return reset_state(v, season)
        if (v[1] == 1) and (v[2] == 0):
            v = v + ZZ8((0,0,1,0,0,0,0,0))
            return reset_state(v, season)
        if (v[1] == 1) and (v[2] == 1) and (v[3] == 0):
            v = v + ZZ8((0,0,0,1,0,0,0,0))
            return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("2XH" in part3[0]) and not("E" in part3[0]):
        runner_on_1st = 1 ## from the "S"
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        #if team_at_bat == 1:
        #    hs = hs+2
        #else:
        #    vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("3-3" in part3[0]):
        #print(parts,"3")
        v = v + ZZ8((0,1,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("1-1" in part3[0]):
        #print(parts,"3")
        v = v + ZZ8((0,1,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("2-2" in part3[0]):
        #print(parts,"3")
        v = v + ZZ8((0,1,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("BX2" in part3[0]) and ("E" in part3[0]) and not(is_p_num_p_in_string(part3[0])):
        print("BX2", "3", ("BX2" in part3[0]), ("E" in part3[0]), not(is_p_num_p_in_string(part3[0])))
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 0
        #outs = outs + 1
        #if team_at_bat == 1:
        #    hs = hs+0
        #else:
        #    vs = vs+0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        #v = v + ZZ8((0,0,1,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("B-2" in part3[0]):
        #print(parts,"3")
        v = v + ZZ8((0,0,1,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("B-3" in part3[0]):
        #print(parts,"3")
        v = v + ZZ8((0,0,0,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("1-H" in part3[0]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if ("S" == part1[0]) and (len(part3) == 1) and ("2-H" in part3[0]):
        #print(parts,"3",v[7])
        if v[7]==0:
            v = v + ZZ8((0,1,-1,0,0,1,0,0))
        else:
            v = v + ZZ8((0,1,-1,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("3-H" in part3[0]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,1,0,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,1,0,-1,0,0,1,0))
        return reset_state(v, season)
    #print(parts,"3")
    if "S" == part1[0] and (len(part3) == 2) and ("3-3" in part3[0]) and ("2-2" in part3[1]) and not("E" in part1[0]):
        #print(("S" == part1[0]), (len(part3) == 2), ("3-3" in part3[0]), ("2-2" in part3[1]), not("E" in part1[0]),"3")
        runner_on_1st = 1 ## from the "S"
        runner_on_2nd = 1
        runner_on_3rd = 1
        #outs = outs + 1
        #if team_at_bat == 1:
        #    hs = hs+2
        #else:
        #    vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-H" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,1,-1,-1,0,2,0,0))
        else:
            v = v + ZZ8((0,1,-1,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-H" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,0,-1,0,2,0,0))
        else:
            v = v + ZZ8((0,0,0,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-H" in part3[0]) and ("1-H" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,-1,0,0,2,0,0))
        else:
            v = v + ZZ8((0,0,-1,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("B-2" in part3[1]) and ("E" in part3[0]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("B-2" in part3[1] and "E" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-H" in part3[0]) and ("1-2" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-H" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,0,0,0,2,0,0))
        else:
            v = v + ZZ8((0,-1,0,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-3" in part3[0]) and ("B-2" in part3[1]):
        #print(parts,"3")
        v = v + ZZ8((0,0,0,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1-3" in part3[0]) and ("B-2" in part3[1]):
        #print(parts,"3")
        v = v + ZZ8((0,-1,1,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-3" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,0,1,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,0,1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-H" in part3[0]) and ("B-3" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,-1,1,0,1,0,0))
        else:
            v = v + ZZ8((0,0,-1,1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-2" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,1,0,-1,0,1,0,0))
        else:
            v = v + ZZ8((0,1,0,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-2" in part3[1]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,1,0,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,1,0,0,0,1,0))
        return reset_state(v, season)
    #print(part3, ("S" == part1[0]), ("2XH" in part3[0]), ("1-3" in part3[1]), ("B-2" in part3[2]))
    #######       conditions involving "X" in part3
    if "S" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("BX3" in part3[1]) and not("E" in part3[1]):
        #print(parts, "BX")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,0,0,0,1,0,0))
        else:
            v = v + ZZ8((1,-1,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and not("E" in part3[1]) and ("BX2" in part3[1]):
        #print(parts, "1XH")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-H" in part3[0]) and ("BX2" in part3[1]) and not("E" in part3[1]):
        #print(parts, "BX")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,-1,0,0,1,0,0))
        else:
            v = v + ZZ8((1,0,-1,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1XH" in part3[0]) and ("B-3" in part3[1]):
        #print(parts, "1XH")
        v = v + ZZ8((1,-1,0,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("1X2" in part3[0]) and not("E" in part3[0]) and ("2-2" in part3[1]):
        #print(parts, "1XH")
        v = v + ZZ8((1,-1,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2XH" in part3[0]) and not("E" in part3[0]) and ("BX2" in part3[1]) and not("E" in part3[1]):
        #print(parts, "1XH")
        v = v + ZZ8((2,0,-1,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2XH" in part3[0]) and ("E" in part3[0]) and ("B-2" in part3[1]):
        #print(parts, "1XH")
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1XH" in part3[2]):
        #print(parts, "1XH")
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("S" == part1[0]) and (len(part3) == 3) and ("2XH" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, "2XH")
        v = v + ZZ8((1,-1,0,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2XH" in part3[1]) and ("1-3" in part3[2]):
        #print(parts, "2XH")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,-1,0,0,1,0,0))
        else:
            v = v + ZZ8((1,0,-1,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and ("BX2" in part3[2]):
        #print(parts, "BX2")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((1,-1,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("BX2" in part3[2]):
        #print(parts, "BX2")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,-1,0,0,2,0,0))
        else:
            v = v + ZZ8((1,-1,-1,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1X3" in part3[2]) and not("E" in part3[2]):
        #print(parts, "1X3")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,-1,-1,0,2,0,0))
        else:
            v = v + ZZ8((1,0,-1,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2XH" in part3[1]) and not("E" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, "1X3")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,0,-1,0,1,0,0))
        else:
            v = v + ZZ8((1,0,0,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1X3" in part3[1]) and not("E" in part3[1]) and ("B-2" in part3[2]):
        #print(parts, "1X3")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,1,-1,0,1,0,0))
        else:
            v = v + ZZ8((1,-1,1,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1XH" in part3[2]) and ("B-2" in part3[3]):
        #print(parts, "1X3")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,0,-1,0,2,0,0))
        else:
            v = v + ZZ8((1,-1,0,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("BX" in part3[1]):
        #print(parts, "BX")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,0,-1,0,1,0,0))
        else:
            v = v + ZZ8((1,0,0,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("3-H" in part3[0]) and ("1X3" in part3[1]):
        #print(parts, "1X")
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,0,-1,0,1,0,0))
        else:
            v = v + ZZ8((1,0,0,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("BX2" in part3[3]):
        #print(parts,"3")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        if team_at_bat == 1:
            hs = hs+2
        else:
            vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1X3" in part3[2]) and not("E" in part3[2]) and ("B-2" in part3[3]):
        #print(parts,"3")
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 1:
            hs = hs+2
        else:
            vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #######       conditions NOT involving "X" in part3
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-H" in part3[2]):
        #print("cts_S", parts,"3")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+3
        else:
            vs = vs+3
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,-1,-1,0,3,0,0))
        else:
            v = v + ZZ8((0,0,-1,-1,0,0,3,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]):
        #print(parts,"3")
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+2
        else:
            vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-H" in part3[1]) and ("B-3" in part3[2]):
        #print("cts_S", parts,"3")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+2
        else:
            vs = vs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-3" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,-1,1,0,2,0,0))
        else:
            v = v + ZZ8((0,-1,-1,1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-2" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,0,0,0,2,0,0))
        else:
            v = v + ZZ8((0,-1,0,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,0,1,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,0,1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,1,0,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,1,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("B-3" in part3[3]):
        #print(parts,"3")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+3
        else:
            vs = vs+3
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
        #if v[7]==0:
        #    v = v + ZZ8((0,-1,0,-1,0,3,0,0))
        #else:
        #    v = v + ZZ8((0,-1,0,-1,0,0,3,0))
        #return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("B-2" in part3[3]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((0,-1,0,-1,0,3,0,0))
        else:
            v = v + ZZ8((0,-1,0,-1,0,0,3,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("1X3" in part3[0]):
        #print(parts,"1X3")
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((1,0,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-3" in part3[0]) and ("1X3" in part3[1]) and not("E" in part3[1]):
        #print(parts,"1X3")
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((1,0,-1,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("2-3" in part3[0]) and ("1X2" in part3[1]):
        #print(parts,"1X3")
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((1,0,-1,1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 1 and (len(part3[0])>2) and (part3[0][:3] == "1-3"):
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,0,1,0,0,0,0))
    if "S" == part1[0] and len(part3) == 1 and (len(part3[0])>2) and (part3[0][:3] == "2-3"):
        v = v + ZZ8((0,1,-1,1,0,0,0,0))
    if "S" == part1[0] and (len(part3) == 2) and ("2XH" in part3[0]) and ("1-3" in part3[1]):
        v = v + ZZ8((1,-1,-1,1,0,0,0,0))
    if "S" == part1[0] and (len(part3) == 2) and ("2XH" in part3[0]) and ("B-2" in part3[1]):
        v = v + ZZ8((1,0,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1X3" in part3[1]) and ("B-2" in part3[2]):
        #print(parts,"3")
        if v[7]==0:
            v = v + ZZ8((1,-1,0,0,0,1,0,0))
        else:
            v = v + ZZ8((1,-1,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and ("2-H" in part3[0]) and ("1-2" in part3[1]):
        if v[7] == 0:
            v = v + ZZ8((0,-1,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and ("2-H" in part3[0]) and ("B-2" in part3[1]):
        if v[7] == 0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and (len(part3[0])>2) and (part3[0][:3] == "2-H") and part3[1][:3] == "1-3":
        if v[7]==0:
            v = v + ZZ8((0,0,-1,1,0,1,0,0))
        if v[7]==1:
            v = v + ZZ8((0,0,-1,1,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and ("2-H" in part3[0]) and ("B-H" in part3[1]):
        if v[7] == 0:
            v = v + ZZ8((0,0,-1,0,0,2,0,0))
        else:
            v = v + ZZ8((0,0,-1,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 1 and (len(part3[0])>2) and (part3[0][:3]=="1-2"):
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,1,0,0,0,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-3" and part3[1][:3]=="1-2":
        ## in this case, there was already a runner on 1st, 2nd, so we don't add one
        v = v + ZZ8((0,0,0,1,0,0,0,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]):
        ## in this case, there was already a runner on 1st,2nd,3rd, so we don't add one
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((0,0,0,-1,0,2,0,0))
        else:
            v = v + ZZ8((0,0,0,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-2" in part3[3]):
        ## in this case, there was already a runner on 1st,2nd,3rd, so we don't add one
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((0,-1,0,0,0,2,0,0))
        else:
            v = v + ZZ8((0,-1,0,0,0,0,2,0))
        return reset_state(v, season)
    ###### test for "1X", "2X", "3X"
    if ("S" == part1[0]) and not("SB" in part1) and (len(part3)<=2) and ("BX" in sum_part3):
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        if ("S" == part1[0]) and (len(part3)==1) or (len(part3)==2 and len(part3[0])==0):
            return reset_state(v, season)
        if (len(part3)==2) and ("2-H" in part3[0]) and ("X" in part3[1]):
            runner_on_2nd = 0
            runner_on_2nd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("X" in part3[0]):
        #print(parts)
        i0 = part3[0].index("X")
        base = part3[0][i0-1]
        if base == "1":
            v = v + ZZ8((1,0,0,0,0,0,0,0))
        elif base == "2":
            v = v + ZZ8((1,0,-1,0,0,0,0,0))
        elif base == "3":
            v = v + ZZ8((1,0,0,-1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("X" in part3[1]) and ("3-H" in part3[0]):
        i0 = part3[1].index("X")
        base = part3[1][i0-1]
        #print(parts, i0, base)
        if (base == "1") or (base=="B"):
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,1,0,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,1,0,-1,0,0,1,0))
        if base == "2":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,1,0,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,1,0,-1,0,0,1,0))
        if base == "3":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,1,0,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,1,0,-1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 2) and ("X" in part3[1]) and ("2-H" in part3[0]):
        i0 = part3[1].index("X")
        base = part3[1][i0-1]
        #print(parts, i0, base)
        if (base == "1") or (base=="B"):
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,0,-1,0,0,1,0,0))
            else:
                v = v + ZZ8((1,0,-1,0,0,0,1,0))
        if base == "2":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,1,-1,0,0,1,0,0))
            else:
                v = v + ZZ8((1,1,-1,0,0,0,1,0))
        if base == "3":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,1,-1,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,1,-1,-1,0,0,1,0))
        return reset_state(v, season)
    #print("BX2", parts, ("2-H" in part3[0]), ("1-3" in part3[1]), ("BX2" in part3[2]))
    if "S" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0])  and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("BX1" in part3[3]):
        #print("BX2",parts)
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,-1,0,0,2,0,0))
        else:
            v = v + ZZ8((1,-1,-1,0,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1XH" in part3[1]) and ("B-2" in part3[2]):
        runner_on_2nd = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("BX2" in part3[2]):
        #print("BX2",parts)
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,-1,-1,1,0,1,0,0))
        else:
            v = v + ZZ8((1,-1,-1,1,0,0,1,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("BX2" in part3[2]):
        #print("BX2",parts)
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,-1,-1,0,2,0,0))
        else:
            v = v + ZZ8((1,0,-1,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1X2" in part3[2]):
        #print("BX2",parts)
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((1,0,-1,-1,0,2,0,0))
        else:
            v = v + ZZ8((1,0,-1,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("X" in part3[1]) and ("1-2" in part3[2]):
        #print(parts)
        i0 = part3[1].index("X")
        base = part3[1][i0-1]
        if base == "1":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,-1,1,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,-1,1,-1,0,0,1,0))
        if base == "2":     ## already a runner on 2nd
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,-1,0,-1,0,1,0,0))
            else:
                v = v + ZZ8((1,-1,0,-1,0,0,1,0))
        if base == "3":     ## doesn't make sense/won't occur
            v = v + ZZ8((1,1,-1,-1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("X" in part3[2]):
        #print(parts)
        i0 = part3[2].index("X")
        base = part3[2][i0-1]
        if base == "1":
            if v[7]==0:                            ## team_at_bat = v[7]
                v = v + ZZ8((1,-1,-1,0,0,1,0,0))
            else:
                v = v + ZZ8((1,-1,-1,0,0,0,1,0))
        if base == "2":     ## doesn't make sense/won't occur
            v = v + ZZ8((1,1,-1,0,0,0,0,0))
        if base == "3":     ## doesn't make sense/won't occur
            v = v + ZZ8((1,1,-1,-1,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 1) and ("1X" in part3[0]):
        #print("1X", parts)
        v = v + ZZ8((1,0,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and ("X" in part3[0]) and ("B-1" in part3[1]):
        #print(parts)
        i0 = part3[0].index("X")
        base = part3[0][i0-1]
        if base == "1":
            v = v + ZZ8((1,1,0,0,0,0,0,0))
        if base == "2":
            v = v + ZZ8((1,1,-1,0,0,0,0,0))
        if base == "3":
            v = v + ZZ8((1,1,0,-1,0,0,0,0))
    if "S" == part1[0] and len(part3) == 2 and ("X" in part3[0]) and ("1-2" in part3[1]):
        #print(parts)
        i0 = part3[0].index("X")
        base = part3[0][i0-1]
        if base == "1":      # doesn't really make sense
            v = v + ZZ8((1,0,1,0,0,0,0,0)) 
        if base == "2":      # take a runner off 1st, 2nd then put one back on 2nd
            v = v + ZZ8((1,-1,0,0,0,0,0,0))
        if base == "3":      # take a runner off 1st, 3rd then put one on 2nd
            v = v + ZZ8((1,-1,1,-1,0,0,0,0))
    if "S" == part1[0] and len(part3) == 2 and ("X" in part3[0]) and ("B-2" in part3[1]):
        #print(parts)
        i0 = part3[0].index("X")
        base = part3[0][i0-1]
        if base == "1":
            v = v + ZZ8((1,-1,1,0,0,0,0,0))
        if base == "2":
            v = v + ZZ8((1,0,1,0,0,0,0,0))
        if base == "3":
            v = v + ZZ8((1,0,1,-1,0,0,0,0))
    ###### test for "BX"
    if "S" == part1[0] and (len(part3) == 1) and ("BX" in part3[0]):
        #print("BX", parts)
        v = v + ZZ8((1,0,0,0,0,0,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and (part3[0][:3]=="3-H") and ("BX" in part3[1]) and v[7]==0:
        #print(parts)
        v = v + ZZ8((1,0,0,-1,0,1,0,0))
    if "S" == part1[0] and len(part3) == 2 and (part3[0][:3]=="3-H") and ("BX" in part3[1]) and v[7]==1:
        v = v + ZZ8((1,0,0,-1,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="1-2" and v[7]==0:
        ## in this case, there was already a runner on 1st, 3rd, so we don't add one
        #print(parts)
        v = v + ZZ8((0,0,1,-1,0,1,0,0))
    ###### most test for "BX"
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="2-3") and (part3[1][:3]=="1-2") and ("BX" in part3[2]):
        #print(parts)
        v = v + ZZ8((1,0,0,1,0,0,0,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="3-H") and (part3[1][:3]=="1-3") and ("BX" in part3[2]) and v[7]==0:
        #print(parts)
        v = v + ZZ8((1,-1,0,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="3-H") and (part3[1][:3]=="1-3") and ("BX" in part3[2]) and v[7]==1:
        #print(parts)
        v = v + ZZ8((1,-1,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="2-H") and (part3[1][:3]=="1-2") and ("BX" in part3[2]) and v[7]==0:
        #print(parts)
        v = v + ZZ8((1,-1,0,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="2-H") and (part3[1][:3]=="1-2") and ("BX" in part3[2]) and v[7]==1:
        #print(parts)
        v = v + ZZ8((1,-1,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="2-H") and (part3[1][:3]=="1-3") and ("BX" in part3[2]) and v[7]==0:
        #print(parts)
        v = v + ZZ8((1,-1,-1,1,0,1,0,0))
    if "S" == part1[0] and len(part3) == 3 and (part3[0][:3]=="2-H") and (part3[1][:3]=="1-3") and ("BX" in part3[2]) and v[7]==1:
        #print(parts)
        v = v + ZZ8((1,-1,-1,1,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and (part3[0][:3]=="2-3") and ("BX" in part3[1]):
        #print(parts)
        v = v + ZZ8((1,0,-1,1,0,0,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and ("BX" in part3[1]) and v[7]==0:
        #print(parts)
        v = v + ZZ8((1,0,-1,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and ("BX" in part3[1]) and v[7]==1:
        v = v + ZZ8((1,0,-1,0,0,0,1,0))
    ##### testing longer cases
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and ("1-2" in part3[1]) and v[7]==1:
        ## in this case, there was already a runner on 1st, 3rd, so we don't add one
        v = v + ZZ8((0,0,1,-1,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="1-3" and v[7]==0:
        ## in this case, there was already a runner on 1st, 3rd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="1-3" and v[7]==1:
        ## in this case, there was already a runner on 1st, 3rd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-3" and v[7]==0:
        ## in this case, there was already a runner on 3rd, so we don't add one
        v = v + ZZ8((0,1,-1,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-3" and v[7]==1:
        ## in this case, there was already a runner on 3rd, so we don't add one
        v = v + ZZ8((0,1,-1,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and ("3-H" in part3[0]) and ("2-H" in part3[1]) and v[7]==0:
        v = v + ZZ8((0,1,-1,-1,0,2,0,0))
        return reset_state(v, season)
    if "S" == part1[0] and len(part3) == 2 and ("3-H" in part3[0]) and ("2-H" in part3[1]) and v[7]==1:
        v = v + ZZ8((0,1,-1,-1,0,0,2,0))
        return reset_state(v, season)
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]) and (v[7]==0):
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,0,-1,0,2,0,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]) and v[7]==1:
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,0,-1,0,0,2,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        ## in this case, there are 2 HRs
        if v[7]==0:
            v = v + ZZ8((0,0,1,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,1,0,0,0,1,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]) and v[7]==1:
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,-1,-1,0,0,2,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]) and v[7]==0:
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,-1,-1,0,2,0,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and v[7]==1:
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,-1,0,0,0,2,0))
    if "S" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and v[7]==0:
        ## in this case, there are 2 HRs
        v = v + ZZ8((0,0,-1,0,0,2,0,0))
    if "S" == part1[0] and len(part3) == 3 and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
        ## in this case, there was already a runner on 1st,2nd,3rd, so we don't add one
        if v[7]==0:                            ## team_at_bat = v[7]
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 1 and (len(part3[0])>2) and (part3[0][:3]=="1-H") and v[7]==0:
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,0,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 1 and (len(part3[0])>2) and (part3[0][:3]=="1-H") and v[7]==1:
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 1 and part3[0][:3]=="1-H" and v[7]==1:
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,0,0,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 1 and part3[0][:3]=="2-H" and v[7]==0:
        v = v + ZZ8((0,1,-1,0,0,1,0,0))
    if "S" == part1[0] and len(part3) == 1 and part3[0][:3]=="2-H" and v[7]==1:
        v = v + ZZ8((0,1,-1,0,0,0,1,0))
    if "S" == part1[0] and len(part3) == 1 and part3[0][:3]=="3-H" and v[7]==0:
        v = v + ZZ8((0,1,0,-1,0,1,0,0))
    if "S" == part1[0] and len(part3) == 1 and part3[0][:3]=="3-H" and v[7]==1:
        v = v + ZZ8((0,1,0,-1,0,0,1,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-H" and v[7]==0:
        v = v + ZZ8((0,1,-1,-1,0,2,0,0))
    if "S" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-H" and v[7]==1:
        v = v + ZZ8((0,1,-1,-1,0,0,2,0))
    return reset_state(v, season)


def convert_to_state_D(current_game_state, play_record, season = 2023):
    """
    *********** programming in progress **********

    This function takes a play record and current game state and returns
    the modified game state.

    ** It only works currently if the play is a S and does NOT (yet)
       account for any runners on base advancing. **
    ** The code below must include use of part(s) 2 and part(s) 3
       of the "parts" variable below. **

    EXAMPLE:
        sage: play_record = "play,3,0,lemad001,21,BCBX,D9/L9D"
        sage: current_game_state = (0,0,0,0,1,0,0,0)
        sage: convert_to_state_D(current_game_state, play_record)
         (0, 0, 1, 0, 1, 0, 0, 0)
        sage: play_record = "play,3,1,duckd001,21,BCBX,D4/G4.1-3"
        sage: current_game_state = (0,1,0,0,1,0,0,1)
        sage: convert_to_state_D(current_game_state, play_record)
         (0, 0, 1, 1, 1, 0, 0, 1)
        sage: play_record = "play,3,1,duckd001,21,BCBX,D4/G4.2-H"
        sage: current_game_state = (0,0,1,0,1,0,0,1)
        sage: convert_to_state_D(current_game_state, play_record)
         (0, 0, 1, 0, 1, 0, 1, 1)
        sage: play_record = "play,3,0,duckd001,21,BCBX,D4/G4.2-3"
        sage: current_game_state = (0,0,1,0,1,0,0,0)
        sage: convert_to_state_D(current_game_state, play_record)
         (0, 0, 1, 1, 1, 0, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,D4/G4.3-H"
        sage: current_game_state = (0,0,0,1,1,0,0,0)
        sage: convert_to_state_D(current_game_state, play_record)
         (0, 0, 1, 0, 1, 1, 0, 0)

    """
    ZZ8 = ZZ^8
    v = ZZ8(current_game_state)
    spl_rec = play_record.split(",")
    field6 = spl_rec[-1]
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    outs = v[0]
    runner_on_1st = v[1]
    runner_on_2nd = v[2]
    runner_on_3rd = v[3]
    inning = v[4]
    vs = v[5]
    hs = v[6]
    team_at_bat = v[7]
    if len(part3)>0 and len(part3[0])>0:
        sum_part3 = ''.join(part3)
    elif len(part3)==2 and part3[0]==[]:   ## part3 has form [ [], "xyz"]
        sum_part3 = part3[1] 
    else:
        sum_part3 = part3 
    ## test for "DGR"
    if ("DGR" == part1) and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if v[7]==0:
            vs = vs + 2
        else:
            hs = hs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        #print(parts,len(part3),v)
        return reset_state(v, season)
    if ("DGR" == part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("DGR" == part1) and (len(part3) == 2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("DGR" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-H" in part3[1]):
        if v[7]==0:
            v = v + ZZ8((0,0,0,-1,0,2,0,0))
        else:
            #print(parts, 2)
            v = v + ZZ8((0,0,0,-1,0,0,2,0))
        return reset_state(v, season)
    if ("DGR" == part1) and (len(part3) == 1) and ("3-H" in part3[0]):
        if v[7]==0:
            v = v + ZZ8((0,0,1,-1,0,1,0,0))
        else:
            #print(parts, 2)
            v = v + ZZ8((0,0,1,-1,0,0,1,0))
        return reset_state(v, season)
    if ("DGR" == part1) and (len(part3) == 1) and ("2-H" in part3[0]):
        #print(parts, v)
        if v[7]==0:
            v = v + ZZ8((0,0,0,0,0,1,0,0))
        else:
            v = v + ZZ8((0,0,0,0,0,0,1,0))
        return reset_state(v, season)
    if "DGR" == part1 and len(part3) == 1 and (len(part3[0])==0):
        if runner_on_1st==1 and runner_on_2nd==0:
            v = v + ZZ8((0,-1,1,1,0,0,0,0))
        if runner_on_1st==0 and runner_on_2nd==1:
            #print(parts, 2)
            v = v + ZZ8((0,0,0,1,0,0,0,0))
            return reset_state(v, season)
        if runner_on_1st==0 and runner_on_2nd==0:
            v = v + ZZ8((0,0,1,0,0,0,0,0))
        return reset_state(v, season)
    #### fallback case:
    if "DGR" in part1:
        runner_on_2nd = 1
        if runner_on_1st==1:
            runner_on_1st = 0
            runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##########################################################################################
    if "D" == part1[0] and (len(part3) == 1) and ("1-3" in part3[0]):
        #outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ######### only valid if there is no out on the play
    ## test for "X"
    if "D" == part1[0] and (len(part3) == 1) and ("BX2" in part3[0]):
        outs = outs + 1
        runner_on_2nd = 0
        runner_on_1st = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 1) and ("X" in part3[0]):
        outs = outs + 1
        runner_on_2nd = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("1XH" in part3[0]) and not("E" in part3[0]) and ("B-3" in part3[1]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("X" in part3[1]) and ("3-H" in part3[0]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("X" in part3[1]) and ("2-H" in part3[0]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(part1, ("D" == part1), (len(part3)==2), ("1-H" in part3[0]), ("E" in part3[1]), ("BX3" in part3[1]))
    if ("D" in part1) and (len(part3)==2) and ("1-H" in part3[0]) and ("E" in part3[1]) and ("BX3" in part3[1]):
        if "(" in part3[1]:
            bx3e = part3[1].split("(")
            if not("E" in bx3e[1]): # there is an out at 3rd
                runner_on_1st = 0
                runner_on_2nd = 0
                runner_on_3rd = 0
                outs = outs + 1
                #print("2", outs)
            if ("E" in bx3e[1]): # there is no out at 3rd
                runner_on_1st = 0
                runner_on_2nd = 0
                runner_on_3rd = 1
                #outs = outs + 1
                #print("2", outs)
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 2) and ("1-H" in part3[0]) and ("BX" in part3[1]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 2) and ("3-H" in part3[0]) and ("B-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 2) and ("2-H" in part3[0]) and ("B-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 2) and ("2-H" in part3[0]) and ("B-1" in part3[1]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("D+3part-part3", ("D" == part1[0]), (len(part3) == 3), ("3-H" in part3[0]), ("1XH" in part3[1]), ("B-3" in part3[2]), not("E" in part3[1]))
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1XH" in part3[1]) and ("B-3" in part3[2]) and not("E" in part3[1]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1XH" in part3[1]) and ("B-3" in part3[2]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("D+4part-part3", ("D" == part1[0]), (len(part3) == 4), ("3-H" in part3[0]), ("2-H" in part3[1]), ("1-H" in part3[2]), ("BX3" in part3[3]), not("E" in part3[3]))
    if ("D" == part1[0]) and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("BX3" in part3[3]) and not("E" in part3[3]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ############# going back to not "X"
    if "D" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-H" in part3[1]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-3" in part3[1]):
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]):
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-3" in part3[2]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-3" in part3[2]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-H" in part3[1]) and ("B-3" in part3[2] and "E" in part3[2]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(parts)
    #if (len(part3) == 4):
    #    print(("3-H" in part3[0]), ("2-H" in part3[1]), ("1XH" in part3[2]), ("B-3" in part3[3]))
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("X" in part3[2]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("1-H" in part3[1]) and ("X" in part3[2]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("BX3" in part3[2]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1XH" in part3[2]) and ("B-3" in part3[3]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("BX2" in part3[3]):
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "D" == part1[0] and (len(part3) == 2) and ("X" in part3[0] or "X" in part3[1]):
        outs = outs + 1
        runner_on_2nd = 1
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        #if base == "B":
        #    runner_on_1st = 0
        if base == "1":
            runner_on_1st = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ## tests for not "X":
    if "D" == part1[0] and (len(part3)>0) and (len(part3[0]) == 0):
        v = v + ZZ8((0,0,1,0,0,0,0,0))
    if ("D" == part1[0]) and (len(part3) == 1) and ("B-3" in part3[0]):
        v = v + ZZ8((0,0,0,1,0,0,0,0))
    if ("D" == part1[0]) and (len(part3) == 1) and ("1-3" in part3[0]):
        v = v + ZZ8((0,-1,0,1,0,0,0,0))
    if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="2-3":
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,0,0,1,0,0,0,0))
    if "D" == part1[0] and len(part3) == 2 and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        if v[7]==0:
            v = v + ZZ8((0,-1,1,0,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,1,0,0,0,1,0))
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-3" in part3[1]):
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        #print(part3)
        if v[7]==0:
            v = v + ZZ8((0,-1,1,1,0,1,0,0))
        else:
            v = v + ZZ8((0,-1,1,1,0,0,1,0))
        return reset_state(v, season)
    if ("D" == part1[0]) and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("B-3" in part3[3]):
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        #print(part3)
        if v[7]==0:
            v = v + ZZ8((0,-1,-1,0,0,3,0,0))
        else:
            v = v + ZZ8((0,-1,-1,0,0,0,3,0))
        return reset_state(v, season)
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and part3[1][:3]=="1-3" and v[7]==0:
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        v = v + ZZ8((0,-1,0,1,0,1,0,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and part3[1][:3]=="1-3" and v[7]==1:
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        #print(part3)
        v = v + ZZ8((0,-1,0,1,0,0,1,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-3" and v[7]==0:
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,1,0,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-3" and v[7]==1:
        ## in this case, there was already runners on 2nd+3rd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,0,1,0))
    #if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="1-H" and v[7]==0:
    #    v = v + ZZ8((0,0,1,0,0,1,0,0))
    #if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="1-H" and v[7]==1:
    #    v = v + ZZ8((0,0,1,0,0,0,1,0))
    if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="2-H" and v[7]==0:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,1,0,0))
    if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="2-H" and v[7]==1:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,0,0,0,0,0,1,0))
    if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="3-H" and v[7]==0:
        v = v + ZZ8((0,0,1,-1,0,1,0,0))
    if "D" == part1[0] and len(part3) == 1 and part3[0][:3]=="3-H" and v[7]==1:
        v = v + ZZ8((0,0,1,-1,0,0,1,0))
    if "D" == part1[0] and len(part3) == 1 and ("1-H" in part3[0]) and v[7]==0:
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,-1,1,0,0,1,0,0))
    if "D" == part1[0] and len(part3) == 1 and ("1-H" in part3[0]) and v[7]==1:
        ## in this case, there was already a runner on 1st, so we don't add one
        v = v + ZZ8((0,-1,1,0,0,0,1,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and part3[1][:3]=="1-H" and v[7]==0:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,-1,0,0,0,2,0,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="2-H" and part3[1][:3]=="1-H" and v[7]==1:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,-1,0,0,0,0,2,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-H" and v[7]==0:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,0,0,-1,0,2,0,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="2-H" and v[7]==1:
        ## in this case, there was already a runner on 2nd, so we don't add one
        v = v + ZZ8((0,0,0,-1,0,0,2,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="1-H" and v[7]==0:
        v = v + ZZ8((0,-1,1,-1,0,2,0,0))
    if "D" == part1[0] and len(part3) == 2 and part3[0][:3]=="3-H" and part3[1][:3]=="1-H" and v[7]==1:
        v = v + ZZ8((0,-1,1,-1,0,0,2,0))
    return reset_state(v, season)

def convert_to_state_T(current_game_state, play_record, season = 2023):
    """
    *********** programming in progress **********

    This function takes a play record and current game state and returns
    the modified game state.


    EXAMPLE:
        sage: play_record = "play,3,0,lemad001,21,BCBX,T9/L9D"
        sage: current_game_state = (0,1,1,0,1,0,0,0)
        sage: convert_to_state_T(current_game_state, play_record)
         (0, 0, 0, 1, 1, 2, 0, 0)

    """
    ZZ8 = ZZ^8
    v = ZZ8(current_game_state)
    gm_st = v
    outs = gm_st[0]
    runner_on_1st = gm_st[1]
    runner_on_2nd = gm_st[2]
    runner_on_3rd = gm_st[3]
    inning = gm_st[4]
    vs = gm_st[5]
    hs = gm_st[6]
    team_at_bat = gm_st[7]
    play_record = play_record.rstrip()
    spl_rec = play_record.split(",")
    field6 = spl_rec[-1]
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    v1 = v[1]
    v2 = v[2]
    v3 = v[3]
    if ("T" == part1[0]) and (len(part3) == 1) and ("B-H" in part3[0]):
        #print(part3)
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("T" == part1[0]) and (len(part3) == 1) and ("BXH" in part3[0]):
        #print(part3)
        v = v + ZZ8((1,0,0,0,0,0,0,0))
        return reset_state(v, season)
    if "T" == part1[0] and (len(part3) == 2) and ("1-H" in part3[0]) and ("B-H" in part3[1]):
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs + 2
        else:
            hs = hs + 2
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "T" == part1[0] and (len(part3) == 3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-H" in part3[2]):
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "T" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]):
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "T" == part1[0] and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]):
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if "T" == part1[0] and (len(part3) == 4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("BXH" in part3[3]) and not("E" in part3[3]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs + 3
        else:
            hs = hs + 3
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##########################################################################################
    ######### only valid if there is no out on the play
    if "T" == part1[0]:
        if v[7]==0:
            cgs = (v[0],0,0,1,v[4],v[5]+v1+v2+v3,v[6],v[7])
            return reset_state(cgs, season)
        if v[7]==1:
            cgs = (v[0],0,0,1,v[4],v[5],v[6]+v1+v2+v3,v[7])
            return reset_state(cgs, season)

def convert_to_state_E(current_game_state, play_record, season = 2023):
    """
    *********** programming in progress **********

    This function takes a play record and current game state and returns
    the modified game state.


    EXAMPLE:
        sage: play_record = 
        sage: current_game_state = 
        sage: convert_to_state_E(current_game_state, play_record)
         

    """
    ZZ8 = ZZ^8
    v = ZZ8(current_game_state)
    gm_st = v
    outs = gm_st[0]
    runner_on_1st = gm_st[1]
    runner_on_2nd = gm_st[2]
    runner_on_3rd = gm_st[3]
    inning = gm_st[4]
    vs = gm_st[5]
    hs = gm_st[6]
    team_at_bat = gm_st[7]
    play_record = play_record.rstrip()
    spl_rec = play_record.split(",")
    field6 = spl_rec[-1]
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    v1 = v[1]
    v2 = v[2]
    v3 = v[3]
    #print("E -- ", parts, "DP" in part2, outs)
    #print(part3, ("E" in part1), (len(part3)==2), ("2XH" in part3[0]), ("E" in part3[0]), is_p_num_p_in_string(part3[0]), ("B-3" in part3[1]))
    if ("FLE" in part1):
        return reset_state(v, season)
    if ("3E1" in part1) and (len(part3)>0) and (len(part3[0])==0):
        #print(parts,part2=="DP",outs)
        runner_on_1st = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)>0) and (len(part3[0])==0) and not("CS" in part1) and not("EV" in part1):
    #print(parts,part2=="DP",outs)
        runner_on_1st = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==1) and ("2-3" in part3[0]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==1) and ("2-H" in part3[0]):
        #print(parts,part3[0]=="2-3",outs)
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        #outs = outs+1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==1) and ("1-2" in part3[0]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 0
        #outs = outs+1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("2XH" in part3[1]) and not("E" in part3[1]):
        #print(parts,part3[0]=="2-3",outs)
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs+1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("PO" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("1-2" in part3[1]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("EV" in part1) and (len(part3)==1) and ("BX3(" in part3[0]): ## "Bx3(num" means the error doesn't negate the out 
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs+1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("EV" in part1) and (len(part3)==1) and ("B-3" in part3[0]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("EV" in part1) and (len(part3)==1) and ("B-2" in part3[0]):
        #print(parts,part3[0]=="2-3",outs)
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==1) and (part3[0]=="B-1") and not("EV" in part1):
        runner_on_1st = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("1-2" in part3[0]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("2-3" in part3[0]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("1-3" in part3[0]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("2-H" in part3[0]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("3-H" in part3[0]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("G" in part2) and (len(part3)==1) and (part3[0]=="1-2") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("G" in part2) and (len(part3)==1) and (part3[0]=="2-2") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and ("G" in part2) and (len(part3)==1) and (part3[0]=="2-3") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("1X3" in part3[0]) and not("EV" in part1):
        #print(parts, "E" in part1, vs, hs, outs, (len(part3)==1), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and ("BX2(" in part3[0]) and not("E" in part3[0]) and not("EV" in part1): ## error not negated
        #print(parts, "E" in part1, vs, hs, outs, (len(part3)==1), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 0
        runner_on_2nd = 0
        #runner_on_3rd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==1) and (part3[0]=="1-2") and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1XH(" in part3[0]) and not("E" in part3[0]) and (part3[1]=="B-1") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("3-H" in part3[0]) and (part3[1]=="2-3") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("B-3" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("2-H" in part3[0]) and ("B-3" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("2-H" in part3[0]) and ("1-2" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("3-H" in part3[0]) and (part3[1]=="1-2") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("1-H" in part3[0]) and (part3[1]=="B-2") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1-H" in part3[0]) and (part3[1]=="B-1") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and ("3-H" in part3[0]) and (part3[1]=="B-1") and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        #runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-1" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="2-3"), (part3[1]=="1-2"))
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="2-3"), (part3[1]=="1-2"))
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("BX2(" in part3[1]) and not("E" in part3[1]):
        #print(parts, 2)
        outs = outs + 1 ## the runner from 2nd was not 
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2XH" in part3[0] and "E" in part3[0] and not(is_p_num_p_in_string(part3[0]))) and ("B-3" in part3[1]):
        #print(parts, 2)
        #outs = outs + 1 ## the runner from 2nd was not out, but scored due to the error E, unless there is also a "(num)" substring
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(part3, ("E" in part1), (len(part3)==2), ("2XH" in part3[0]), ("E" in part3[0]), is_p_num_p_in_string(part3[0]), ("B-3" in part3[1]))
    if ("E" in part1) and (len(part3)==2) and ("2XH" in part3[0] and "E" in part3[0] and (is_p_num_p_in_string(part3[0]))) and ("B-3" in part3[1]):
        #print(parts, 2)
        outs = outs + 1 ## the runner from 2nd is out, scored even with the error E, because there is also a "(num)" substring
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat == 0:
        #    vs = vs + 1
        #else:
        #    hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2XH" in part3[0]) and ("B-1" in part3[1] and not("E" in part3[0])) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("2XH" in part3[0] and ("(E" in part3[0])) and ("B-3" in part3[1]) and not("EV" in part1):
        #print(parts, "E" in part1,vs,hs,outs,(len(part3)==2), (part3[0]=="3-H"), (part3[1]=="B-1"))
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("BX2" in part3[1] and not("E" in part3[1])) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-2" in part3[1]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("BX2" in part3[1]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and (part3[0]=="1-3") and (part3[1]=="B-1") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and (part3[0]=="2-3") and (part3[1]=="B-2") and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and (part3[0]=="2-3") and (part3[1]=="B-1") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==2) and (part3[0]=="1-2") and (part3[1]=="B-1") and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("B-2" in part3[1]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and not("EV" in part1):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]) and not("EV" in part1):
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 0
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]) and not("EV" in part1):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("1-H" in part3[1]) and ("B-2" in part3[2]) and not("EV" in part1):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and not("EV" in part1):
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 1
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and (("1-3" in part3[1]) or ("2-3" in part3[1])) and ("B-1" in part3[2]) and not("EV" in part1):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and (("1-3" in part3[1]) or ("2-3" in part3[1])) and ("B-2" in part3[2]) and not("EV" in part1):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", v)
            return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("2-3" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-H" in part3[1]) and ("B-2" in part3[2]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-H" in part3[2]) and ("B-2" in part3[3]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+3
        else:
            hs = hs+3
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("B-1" in part3[1]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 0
        #runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("B-2" in part3[1]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        #outs = outs + 1
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("1-H" in part3[1]) and ("BX2(" in part3[2]) and not("E" in part3[2]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2XH" in part3[1])  and not("E" in part3[1]) and ("1-2" in part3[2]) and not("EV" in part1):
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs + 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("BX2(" in part3[2]) and not("E" in part3[2]) and not("EV" in part1):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("B-1" in part3[2]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1 or (len(part2)>0 and "E" in part2[0])) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-1" in part3[2]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-1" in part3[3]):
        runner_on_1st = 1
        runner_on_2nd = 0
        #runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        runner_on_1st = 1
        runner_on_2nd = 1
        #runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("E" in part1) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-2" in part3[3]):
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)



def convert_to_state(current_game_state, play_record, season = 2023, verbose=False):
    """
    *********** programming in progress **********

    This function takes a play record, from the year season, and current 
    game state and returns the modified game state.

    The parameter season is *only* used to determine if the player
    on 2nd base is added in the case of tied extra innings. This started
    in the shortened 2020 season.

    A "game state" is a 8-tuple (s0,s1,s2,s3,j,vs,hs,team_at_bat), where
    * s0 denotes the number of outs (represented as one of the integers 0,1,2)
    * s1 is 0 if there is no runner on 1st base and 1 otherwise,
    * s2 is 0 if there is no runner on 2nd base and 1 otherwise,
    * s3 is 0 if there is no runner on 3rd base and 1 otherwise,
    * j is the inning number,
    * vs is the current score of the visiting team,
    * hs is the current score of the home team,
    * team_at_bat = 0 if the visiting team is at bat, and = 1 if it's the home team. 
    


    EXAMPLE:
        sage: current_game_state = (0,1,0,0,1,0,0,0)
        sage: play_record = "play,1,0,judga001,22,FBBFS,K"
        sage: convert_to_state(current_game_state, play_record)
         (1, 1, 0, 0, 1, 0, 0, 0)
        sage: play_record = "play,3,1,duckd001,21,BCBX,S4/G4.1-H"
        sage: current_game_state = (0,1,0,0,1,0,0,1)
        sage: convert_to_state(current_game_state, play_record)
         (0, 1, 0, 0, 1, 0, 0, 1)
        sage: play_record = "play,3,0,duckd001,21,BCBX,S4/G4.3-H.2-3.1-2"
        sage: current_game_state = (0,1,1,1,1,0,0,0)
        sage: convert_to_state(current_game_state, play_record)
         (0, 1, 1, 1, 1, 1, 0, 0)
        sage: play_record = "play,3,0,duckd001,21,BCBX,D4/G4.3-H"
        sage: current_game_state = (0,0,0,1,1,0,0,0)
        sage: convert_to_state(current_game_state, play_record)
         (0, 0, 1, 0, 1, 1, 0, 0)
        sage: play_record = "play,3,0,lemad001,21,BCBX,T9/L9D"
        sage: current_game_state = (0,1,1,0,1,0,0,0)
        sage: convert_to_state(current_game_state, play_record)
         (0, 0, 0, 1, 1, 2, 0, 0)
        sage: play_record = "play,1,0,lemad001,32,BBCBF.FB,W"
        sage: current_game_state = (0,0,0,0,1,0,0,0)
        sage: cgs = convert_to_state(current_game_state, play_record); cgs
         (0, 1, 0, 0, 1, 0, 0, 0)
        sage: play_record = "play,1,0,judga001,22,FBBFS,K"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 1, 0, 0, 1, 0, 0, 0)
        sage: play_record = "play,1,0,rizza001,00,X,S9/L9+.1-2"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 1, 1, 0, 1, 0, 0, 0)
        sage: play_record = "play,2,1,mounr001,01,FX,8/F8XD+"
        sage: cgs = (0,0,0,0,2,0,0,1)
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 0, 0, 0, 2, 0, 0, 1)
        sage: play_record = "play,2,1,hendg002,10,BX,S9/L9+"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 1, 0, 0, 2, 0, 0, 1)
        sage: play_record = "play,2,1,uriar001,31,BBBCB,W.1-2"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 1, 1, 0, 2, 0, 0, 1)
        sage: play_record = "play,2,1,fraza001,01,CX,S9/G34.2-H;1-3"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         (1, 1, 0, 1, 2, 0, 1, 1)
        sage: play_record = "play,9,0,volpa001,00,.,NP"
        sage: cgs = convert_to_state(cgs, play_record); cgs
         No Play
         (1, 1, 1, 0, 2, 0, 1, 1)
        sage: cgs = (1, 1, 0, 0, 6, 0, 0, 0)
        sage: pr = "play,3,0,rizza001,32,BBCC1B.>S,K+CS2(26)/DP"
        sage: cgs = convert_to_state(cgs, pr); cgs
         (0, 0, 0, 0, 6, 0, 0, 1)

    *********** programming in progress **********
    ############################################################################################
    ####### don't forget to check if "X" in spl_rec[5] (else batter is still at bat!!) #########
    ############################################################################################
    """         ## if No Play then ignore this play
    ZZ8 = ZZ^8
    if current_game_state==None:
        print(current_game_state, play_record, "\n Please enter a non-trivial game state.")
        return (0,0,0,0,0,0,0,0)
    gm_st = current_game_state
    play_record = play_record.rstrip()
    #print(gm_st, type(gm_st))
    v = ZZ8(gm_st)
    spl_rec = play_record.split(",")
    if verbose:
        print("Batter is: ", retrosheet_playerID(player_id = spl_rec[3]))
    #print(gm_st, spl_rec[6])
    if not(spl_rec[0]=="play") and not(spl_rec[0]=="radj"):
        print("This is only for play records. Try again with a retrosheet play record.")
        return gm_st
    if (gm_st[0]>0) and (not(spl_rec[2]==str(gm_st[7]))) and not(spl_rec[0]=="radj"):
        print(spl_rec, gm_st)
        print("The at-bat records between the state and the play record are inconsistent. Try again.")
        return gm_st
    outs = gm_st[0]
    runner_on_1st = gm_st[1]
    runner_on_2nd = gm_st[2]
    runner_on_3rd = gm_st[3]
    inning = gm_st[4]
    vs = gm_st[5]
    hs = gm_st[6]
    team_at_bat = gm_st[7]
    if spl_rec[0]=="radj":
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    field6 = spl_rec[-1]
    if field6 == "NP":            ## if No Play then ignore this play
        if verbose:               ## "NP" state is not ignored in the listing ...
            print("No Play") 
        return gm_st
    if field6 == "NP":            ## if No Play then ignore this play
        if verbose:               ## "NP" state is not ignored in the listing ...
            print("No Play") 
        return gm_st
    parts = separate_field_into_parts(field6)
    part1 = parts[0]
    part2 = parts[1]
    part3 = parts[2]
    #print(parts, 1)
    ####### define sum_part3
    if len(part3)>0 and len(part3[0])>0:
        #print(parts)
        sum_part3 = ''.join(part3)
    elif len(part3)==2 and (len(part3[0])==0):   ## part3[0] has form [ [], "xyz"]
        sum_part3 = part3[1] 
    else:
        sum_part3 = part3
    ### test for "OA" (Other Advance - base runner advance
    ###                not otherwise covered by a code)
    #if part1=="OA":
    #    print(parts)
    if (part1=="OA") and (len(part3)==1) and ("X" in part3[0]):
    #   print(parts, "2")
        outs = outs + 1
        sum_part3 = part3[0]
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        if base == "1":
            runner_on_1st = 0
        if base == "2":
            runner_on_2nd = 0
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==1) and ("3-H" in part3[0]):
    #   print(parts, "2")
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        #runner_on_1st = 0
        #runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==1) and ("2-3" in part3[0]):
    #   print(parts, "2")
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==1) and ("1-2" in part3[0]):
        #print(parts, "2")
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
    #   print(parts, "2")
        #outs = outs + 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==2) and ("3XH" in part3[0]) and not("E" in part3[0]) and ("2-3" in part3[1]):
    #   print(parts, "2")
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==2) and ("2X3" in part3[0]) and ("E" in part3[0]) and not(is_p_num_p_in_string(part3[0])) and ("1-2" in part3[1]):
    #   print(parts, "2")
        #outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==2) and ("2-3" in part3[0]) and ("1X2" in part3[1]):
    #   print(parts, "2")
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="OA") and (len(part3)==2) and ("X" in part3[0]) and ("1-2" in part3[1]):
    #   print(parts, "2")
        outs = outs + 1
        sum_part3 = part3[0]
        i0 = sum_part3.index("X")
        base = sum_part3[i0-1]
        runner_on_1st = 0
        runner_on_2nd = 1
        if base == "3":
            runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="W+OA") and (len(part3)==1) and ("3XH" in part3[0]):
    #   print(parts, "2")
        outs = outs + 1
        runner_on_1st = 1
        #runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ### test for "C/E" (error on catcher)
    if part1[0]=="C" and (len(part3)==2) and ("1-2" in part3[0]) and ("B-1" in part3[1]):
    #   print(parts, "2")
        runner_on_1st = 1
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ### test for "DI" (defensive indifference)
    #if part1=="DI":
    #    print(parts)
    if part1=="DI" and (len(part3)==1) and ("1-2" in part3[0]):
    #   print(parts, "2")
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if part1=="DI" and (len(part3)==1) and ("2-3" in part3[0]):
        runner_on_2nd = 0
        runner_on_3rd = 1
    #print(spl_rec[3], parts, field6, len(field6))
    ### test for "PO" (putout, often from pitcher to 1st, catching the runner)
    if ("PO1(E" in part1) and (len(part3)==1) and ("1-2" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 0
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO1(E" in part1) and (len(part3)==1) and ("1-3" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO1(E" in part1) and (len(part3)==1) and ("1-H" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO1(E" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and not("X" in spl_rec[5]):
        #print(part1,part2,part3,spl_rec[5])
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO2(E" in part1) and (len(part3)==1) and ("2-H" in part3[0]):
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO2(E" in part1) and (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO3(E" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO3(E" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+PO1" in part1) and (not("E" in part1)) and (len(part2)==1) and ("DP" in part2[0]):
        runner_on_1st = 0
        outs = outs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #if ("K+POCS2" in part1) and (not("E" in part1)) and ("DP" in part2):
    if ("K+POCS2" in part1) and (not("E" in part1)) and (len(part2)==1) and ("DP" in part2[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        outs = outs + 2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PO" in part1) and (not("E" in part1)):
    #   print(parts, "2")
        if "PO1" in part1:
            runner_on_1st = 0
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        elif "PO2" in part1:
            runner_on_2nd = 0
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        elif "PO3" in part1:
            runner_on_3rd = 0
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    #print(parts,part2=="DP",outs)
    ####         test if it is "W+SB"
    if ("W+SB2" in field6) and not("E" in field6):  ## false positive if MREV
        runner_on_1st = 1
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("W+SB3" in field6) and not("E" in field6):  ## false positive if MREV
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("W+SB3" in field6) and not("MREV" in field6) and (len(part3)==1) and ("2-H" in part3[0]):  ## false positive if MREV
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #### very special cases, including "PB"
    if ("K+WP" in field6) and (len(part3)==1) and ("B-1" in part3[0]):
        runner_on_1st = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6 or "K+PB" in field6) and (len(part3)==1) and ("2-3" in part3[0]):
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6 or "K+PB" in field6) and (len(part3)==1) and ("1-2" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 1
        outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6 or "K+PB" in field6) and (len(part3)==1) and ("B-2" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 1
        #outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("B-1" in part3[1]):
        runner_on_1st = 1
        #runner_on_2nd = 0
        runner_on_3rd = 0
        #outs = outs+1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("PB" == part1) and (len(part3)==1) and ("1-3" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs+1
        #if team_at_bat == 0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+PB" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs+1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+PB" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        outs = outs+1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6) and (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-1" in part3[1]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+WP" in field6 or "K+PB" in field6) and (len(part3)==4) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]) and ("B-1" in part3[3]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 0
        #outs = outs+1
        if team_at_bat == 0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##         test if it is "CS"
    ######  BUG??  ("E" in field6) gives false positive if MREV or UREV
    ######      FIX?   replace field6 -> part1   FIX???
    if ("CSH" in field6) and not("E" in part1) and (len(part3)==1) and ("1X3" in part3[0]):
        runner_on_1st = 0
        runner_on_3rd = 0
        outs = outs + 2    ## this is a "DP"
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+CSH" in field6) and not("E" in part1):
        runner_on_3rd = 0
        outs = outs + 2    ## this is a "DP"
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CSH" in field6):
        runner_on_3rd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+CS3" in field6) and not("E" in part1):
        runner_on_2nd = 0
        outs = outs + 2    ## this is a "DP"
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+CS2" in part1) and not("E" in part1) and (len(part3) == 1) and ("3-H" in part3[0]):
        runner_on_1st = 0
        runner_on_1st = 0
        runner_on_1st = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        outs = outs + 2      ## this is a "DP"
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+CS2" in field6) and not("E" in part1):
        runner_on_1st = 0
        outs = outs + 2      ## this is a "DP"
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS2" in field6) and ("MREV" in field6):
        runner_on_1st = 0
        runner_on_2nd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS2" in part1) and not("E" in part1) and (len(part3) == 1) and ("2-3" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS2" in field6) and not("E" in part1):
        runner_on_1st = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("1  ", ("CS2" in field6), ("E" in part1))
    if ("CS2" in field6) and ("E" in part1):
        runner_on_1st = 0
        runner_on_2nd = 1
        #outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+CS3" in part1) and ("E" in part1):
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1    
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS3" in part1) and ("E" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        #outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS3" in field6) and not("E" in part1):
        runner_on_2nd = 0
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("CS3" in field6) and ("E" in part1):
        runner_on_2nd = 0
        runner_on_3rd = 1
        #outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ######### test SB2, SB3
    ##         test if it is "SB"
    #print("SB2 test", "SB2" in part1, len(part3)==2, "3-H" in part3[0])
    if (part1 == "K+SB3") and (len(part2)==1) and (len(part2[0])==0) and (len(part3)==1) and ("2-H" in part3[0]):
        outs = outs + 1
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("K+SB3;SB2.2-H(E2/TH)(NR)", (part1 == "K+SB3"), (len(part2)==1), ("SB2" in part2[0]), (len(part3)==1), ("2-H" in part3[0]))
    if (part1 == "K+SB3") and (len(part2)==1) and ("SB2" in part2[0]) and (len(part3)==1) and ("2-H" in part3[0]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SB3" in part1) and (len(part3)==1) and ("2-H" in part3[0]): ## example: wild-pitch + steal-3rd = run
        #outs = outs + 1
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SB3" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("1-2" in part3[1]):
        #outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB2;SBH") and (len(part2)==0) and (len(part3)==0):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB2") and (len(part2)==0) and (len(part3)==0):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB3") and (len(part2)==0) and (len(part3)==0):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #if team_at_bat==0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB2") and (len(part3)==1) and ("1-3" in part3[0]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB2") and (len(part3)==2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        outs = outs + 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SB3" in part1) and (len(part2)>0) and ("SB2" in part2[0]) and (len(part3)==1) and ("2-H" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SB2" in field6) and ("E" in field6):
        if ("SBH" in field6) and (len(part3)==1) and ("1-3" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==1) and ("1-3" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==1) and ("1-H" in part3[0]) and not("X" in spl_rec[5]):
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==1) and ("3-H" in part3[0]) and not("X" in spl_rec[5]):
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==2) and ("3-H" in part3[0]) and ("1-H" in part3[1]):
            if team_at_bat==0:
                vs = vs+2
            else:
                hs = hs+2
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    if ("SB3" in field6) and ("E" in field6):
        if (len(part3)==1) and ("2-H" in part3[0]):
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            #runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==1) and ("1-2" in part3[0]): ## so "E" applies to base advance 1-2, not score 2-H
            #if team_at_bat==0:
            #    vs = vs+1
            #else:
            #    hs = hs+1
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==2) and ("2-H" in part3[0]) and ("1-H" in part3[1]):
            if team_at_bat==0:
                vs = vs+2
            else:
                hs = hs+2
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
            if team_at_bat==0:
                vs = vs+1
            else:
                hs = hs+1
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    if (field6 in ["SB2","SB2\n"]) and not("E" in field6):
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ### test for double stolen bases
    ## print(field6, "DP" in part2, v, (len(part3)==1) and ("1X2" in part3[0]))
    if ("K+SB3;SB2" in field6) and not("E" in field6) and (len(part3)==0):
        #print(field6, (len(part3)==0), v)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SB3;SB2" in field6) and not("E" in field6) and (len(part3)==0):
        #print(field6, (len(part3)==0), v)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)==0 or (len(part3)==1 and len(part3[0])==0)):
        outs = outs+1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and ("DP" in part2) and (len(part3)==1) and ("1X1" in part3[0]):
        outs = outs+2
        runner_on_1st = 0
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and ("DP" in part2 or "NDP" in part2) and (len(part3)==1) and ("1X2" in part3[0]):
        outs = outs+2
        runner_on_1st = 0
        runner_on_2nd = 0
        #runner_on_3rd = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)>0) and ("B-1" in part3[0]):
        runner_on_1st = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)==1) and ("1-2" in part3[0]):
        #print(part1, "2-3")
        runner_on_1st = 0
        runner_on_2nd = 1
        #runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1) and (len(part3)==1) and ("2-3" in part3[0]):
        #print(part1, "2-3")
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K23" == part1) and (len(part3)==1) and ("2-3" in part3[0]):
        #print(part1, "2-3")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)==1) and ("BX1" in part3[0]) and ("E" in part3[0]) and not(is_p_num_p_in_string(part3[0])):
        #outs = outs+1
        runner_on_1st = 1
        #runner_on_2nd = 0
        #runner_on_3rd = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)==2) and ("2-3" in part3[0]) and ("BX1" in part3[1]) and not("E" in part3[1]):
        outs = outs+1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)==2) and ("2X3" in part3[0]) and not("E" in part3[0]) and ("1-2" in part3[1]):
        outs = outs+2
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print("E-2x3+E",("K" == part1[0]), (len(part3)==2), ("2X3" in part3[0]), ("E" in part3[0]), ("1-2" in part3[1]))
    if ("K" == part1[0]) and (len(part3)==2) and ("2X3" in part3[0]) and ("E" in part3[0]) and ("1-2" in part3[1]):
        outs = outs+1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and ("FO" in part2) and (len(part3)==4) and ("3XH" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]) and ("B-1" in part3[3]):
        outs = outs+1
        runner_on_1st = 1
        runner_on_2nd = 1
        runner_on_3rd = 1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K" == part1[0]) and (len(part3)>0) and ("BX1" in part3[0]):
        outs = outs+1
        #print(part1, outs)
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if field6 == "K+SB2":
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1 == "K+SB2") and (len(part3)==1) and ("1-3" in part3[0]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (field6 in ["SB3","SB3\n"]) and not("E" in field6):
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+SB3" in part1) and (len(part2)>0) and ("SB2" in part2[0]) and (len(part3)==1) and ("2-H" in part3[0]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+SB3" in part1) and (len(part2)>0) and ("SB2" in part2[0]):
        outs = outs + 1
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+SB3" in field6):
        outs = outs + 1
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("K+SBH" in part1) and (len(part2)>0) and ("SB2" in part2[0]) and (len(part3)>0) and ("3-H" in part3[0]):
        outs = outs + 1
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("SBH" in field6):
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if field6 == "K+SBH":
        outs = outs + 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##################################
    ### "HR", "WP", "BK" cases
    #print(parts)
    if ("HR" in part1):
        #print(parts, "0")
        if team_at_bat==0:
            vs = vs + runner_on_1st + runner_on_2nd + runner_on_3rd + 1
        else:
            hs = hs + runner_on_1st + runner_on_2nd + runner_on_3rd + 1
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="BK") and (len(part3) == 1) and ("1-2" in part3[0]):
        #print(parts, "1-2")
        if (runner_on_1st == 1) and (runner_on_2nd == 0) and (runner_on_3rd == 0): 
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
        #if (runner_on_1st == 1) and (runner_on_2nd == 1) and (runner_on_3rd == 0): 
        #    runner_on_1st = 0
        #    runner_on_2nd = 1
        #    runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="BK") and len(part3) == 1 and ("2-3" in part3[0]):
        runner_on_3rd = 1
        runner_on_2nd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("BK" in part1) and (len(part3) == 1) and ("3-H" in part3[0]):
        #runner_on_1st = 1
        #runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("BK" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("BK" in part1) and (len(part3) == 2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        #if team_at_bat == 0:
        #    vs = vs+1
        #else:
        #    hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("BK" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("BK" in part1) and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("W+WP" in part1) and (len(part3) == 1) and (part3[0]=="2-3"):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("W+WP" in part1) and (len(part3) == 1) and (part3[0]=="1-2"):
        runner_on_1st = 1
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("W+WP" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 1) and (part3[0]=="1-2"):
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 1) and ("1-3" in part3[0]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 1) and ("2-3" in part3[0]):
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 1) and ("3-H" in part3[0]):
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        runner_on_3rd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 1) and ("2XH" in part3[0]):
        outs = outs + 1
        runner_on_2nd = 0
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-H" in part3[1]):
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs+2
        else:
            hs = hs+2
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
        #print(parts)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
        #print(parts)
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("WP" in part1) and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
        #print(parts)
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat == 0:
            vs = vs+1
        else:
            hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 1) and (part3[0]=="1-2"):
        runner_on_1st = 0
        runner_on_2nd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 1) and (part3[0]=="2-3"):
        runner_on_2nd = 0
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 2) and (part3[0]=="2-3") and (part3[1]=="1-2"):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 1) and ("3-H" in part3[0]):
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
        #runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 0
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (part1=="PB") and (len(part3) == 3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
        runner_on_1st = 0
        runner_on_2nd = 1
        runner_on_3rd = 1
        if team_at_bat==0:
            vs = vs + 1
        else:
            hs = hs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##################################
    ### "W" cases
    if (("W" in part1 and not("WP" in part1)) or ("IW" in part1) or ("HP" in part1)) and (len(part3)==3):
        if ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-2" in part3[2]):
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 1
            if team_at_bat == 0:
                vs = vs+2
            else:
                hs = hs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 1
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    if (("W" in part1 and not("WP" in part1)) or ("IW" in part1) or ("HP" in part1)) and (len(part3)==2):
        if ("2-3" in part3[0]) and ("1-2" in part3[1]):
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("3-H" in part3[0]) and ("2-H" in part3[1]):  #### add more cases
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 0
            if team_at_bat == 0:
                vs = vs+2
            else:
                hs = hs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("3-H" in part3[0]) and ("1-3" in part3[1]): 
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("3-H" in part3[0]) and ("1-2" in part3[1]): 
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 0
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("2-H" in part3[0]) and ("1-3" in part3[1]):  
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("2-H" in part3[0]) and ("1-2" in part3[1]):  
            runner_on_1st = 1
            runner_on_2nd = 1
            runner_on_3rd = 0
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    if (("W" in part1) or ("IW" in part1) or ("HP" in part1)) and (len(part3)==1):
        if ("3-H" in part3[0]): 
            runner_on_1st = 1
            #runner_on_2nd = 0
            runner_on_3rd = 0
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("2-3" in part3[0]):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("1-3" in part3[0]):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("1-2" in part3[0]):
            runner_on_1st = 1
            runner_on_2nd = 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("1X3" in part3[0] and not("E" in part3[0])):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_2nd = 0
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
    if (("W" in field6) or ("IW" in field6) or ("HP" in field6)) and (len(part3)==0):
        if runner_on_1st == 0:
            runner_on_1st = 1
        elif runner_on_1st == 1 and runner_on_2nd == 0:
            runner_on_2nd = 1
        elif runner_on_1st == 1 and runner_on_2nd == 1 and runner_on_3rd == 0:
            runner_on_3rd = 1
        elif runner_on_1st == 1 and runner_on_2nd == 1 and runner_on_3rd == 1:
            if team_at_bat == 0:
                vs = vs+1
            else:
                hs = hs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if (("W" in field6) or ("IW" in field6) or ("HP" in field6)):
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ####         test for fielding errors, "E"
    ############################################
    if ("E" in part1):
        return convert_to_state_E(current_game_state, play_record, season)
    ############################################
    #print(parts, part1[:2], part1[:2]=="FC")
    ## for "FC", send to convert_to_state_FC
    if ("FC" in part1):
        #print(parts, part1[:2], "FC again")
        return convert_to_state_FC(current_game_state, play_record, season)
    ### test for runner outs "X" with batter single "S" 
    if ("S" == part1[0]) and not("SB" in part1) and (len(part3)==1) and not("X" in sum_part3):
        #print(parts, 2)
        #    print(part1, part2, part3)
        return convert_to_state_S(current_game_state, play_record, season)
    if ("S" in part1) and not("CS" in part1):
        #print(parts, "test")
        #if spl_rec[3]=='matej003':
        #    print(current_game_state, parts, ("S" == part1[0]), not("SB" in part1), len(part3), ("X" in sum_part3))
        return convert_to_state_S(current_game_state, play_record)
    if ("D" == part1[0]):
        #print(parts, 3)
        return convert_to_state_D(current_game_state, play_record, season)
    if ("T" == part1[0]):
        #print(parts, 4)
        return convert_to_state_T(current_game_state, play_record, season)
    if ("(1)" in part1) and not("FO" in part2) and (len(part3)==1) and ("3-H" in part3[0]):
        #print("1")
        runner_on_1st = 0
        #runner_on_2nd = 0
        runner_on_3rd = 0
        outs = outs + 2
        if team_at_bat == 1:
            hs = hs+1
        else:
            vs = vs+1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    #print(("(1)" in part1), ("FO" in part2), (len(part3)==1), ("B-3" in part3[0]), ("E" in part3[0]), not("EV" in part3[0]))
    if ("(1)" in part1) and ("FO" in part2) and (len(part3)==1) and ("B-3" in part3[0]) and ("E" in part3[0]) and not("EV" in part3[0]):
        #print("1")
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    if ("(1)" in part1) and ("FO" in part2) and (len(part3)==2) and ("2-3" in part3[0]) and ("E" in part3[1]) and ("BX1" in part3[1]):
        #print("1")
        runner_on_1st = 1
        runner_on_2nd = 0
        runner_on_3rd = 1
        outs = outs + 1
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    ##########################################################################################
    ######### only completed if there is no DP
    ###########################################                          WIP
    if (part1[0] in ["1","2","3","4","5","6","7","8","9"]): 
        #print(parts, 2)
        #outs = outs+1
        if ("TP" in part2):
            outs = outs + 3
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and (len(part3[0])==0):
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and ("2-H" in part3[0]):
            #runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and ("1-H" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and ("B-1" in part3[0]):
            runner_on_1st = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        ######
        ###### putting captures first with an "X", then sorting by len(part3) as usual
	######
        ##print(not("(" in part1), len(part3)==2, "3-H" in part3[0], "1-H" in part3[1])
        if not("(" in part1) and (len(part3)==1) and ("1X" in part3[0]) and not("E" in part3[0]):
            runner_on_1st = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        elif not("(" in part1) and (len(part3)==1) and ("1X2" in part3[0]) and ("E" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        elif not("(" in part1) and (len(part3)==1) and ("1X3" in part3[0]) and ("E" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and ("2X" in part3[0]):
            runner_on_2nd = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==1) and ("3X" in part3[0]):
            runner_on_3rd = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("2X2" in part3[0]) and ("1X1" in part3[1]):
            #print("TP")
            runner_on_1st = 0
            runner_on_2nd = 0
            #runner_on_3rd = 0
            outs = outs + 3
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1X" in part3[1]):
            runner_on_1st = 0
            runner_on_3rd = 0
            outs = outs + 2
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("2X2" in part3[1]):
            runner_on_2nd = 0
            runner_on_3rd = 0
            outs = outs + 2
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-H" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-3" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==2) and ("2-H" in part3[0]) and ("1-3" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("2-3" in part3[0]) and ("1X" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("3X" in part3[0]) and ("2-3" in part3[1]):
            #runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("3XH" in part3[0]) and ("1-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("2X3" in part3[0]) and ("1-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("1-2" in part3[0]) and ("3X" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            outs = outs + 2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and len(part3)==2 and ("2-3" in part3[0]) and ("B-1" in part3[1]):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("E" in part1) and not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-1" in part3[1]):
            runner_on_1st = 1
            #runner_on_2nd = 0
            runner_on_3rd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 0
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and (len(part3)==1) and ("B-2" in part3[0]):
            runner_on_1st = 0
            runner_on_2nd = 1
            #outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and not("EV" in part1) and not("(" in part1) and (len(part3)==2) and ("1-3" in part3[0]) and ("B-2" in part3[1]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            #outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("1-2" in part3[0]) and ("B-1" in part3[1]):
            runner_on_1st = 1
            runner_on_2nd = 1
            #runner_on_3rd = 1
            #outs = outs + 1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("2-H" in part3[1]):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 0
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and not("(" in part1) and (len(part3)==2) and ("2-H" in part3[0]) and ("B-1" in part3[1]):
            runner_on_1st = 1
            runner_on_2nd = 0
            runner_on_3rd = 0
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("1-3" in part3[2]):
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+2
            else:
                vs = vs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("E" in part1) and not("(" in part1) and (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-2" in part3[2]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            #outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==3) and ("3XH" in part3[0]) and ("E" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", x)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", x)
            return reset_state(v, season)
        if  not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and not("B-1" in part3):
            runner_on_2nd = 0
            outs = outs + 1
            runner_on_3rd = 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if  not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and not("B-1" in part3):
            runner_on_1st = 0
            runner_on_2nd = 1
            outs = outs + 1
            runner_on_3rd = 0
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==2) and ("3-H" in part3[0]) and ("2X3" in part3[1]):
            runner_on_2nd = 0
            outs = outs + 2
            runner_on_3rd = 0
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            #print("3-H", x)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1-2" in part3[2]):
            #print(parts, 1)
            runner_on_1st = 0
            runner_on_2nd = 1
            runner_on_3rd = 1
            outs = outs + 1
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if not("(" in part1) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("1X" in part3[2]):
            #print(parts, 1)
            runner_on_1st = 0
            runner_on_2nd = 0
            runner_on_3rd = 1
            outs = outs + 2
            if team_at_bat == 1:
                hs = hs+1
            else:
                vs = vs+1
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        ###############
        # add if-then on if "(" in part1 then: next character is the base with a force out.
        ###############
        if len(part3)>0 and len(part3[0])>0:
            sum_part3 = ''.join(part3)
        elif (len(part3)==2) and (len(part3[0])==0):   ## part3 has form [ [], "xyz"]
            sum_part3 = part3[1] 
        else:
            sum_part3 = part3 
        #print(parts, "GDP",(len(part2)>0), ("DP" in part2[0]), (len(part3)==2), (part3[0]==[]), ("(1)" in part1)) 
        if (len(part2)>0) and ("DP" in part2[0]) and (len(part3)==2) and (part3[0]==[]) and ("(1)" in part1):
            outs = outs+2
            runner_on_1st = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part2)>0) and ("(3)" in part1) and ("DP" in part2[0]) and (len(part3)==2) and (part3[0]=="2-2") and (part3[1]=="1-1"):
            outs = outs+2
            runner_on_3rd = 0
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if (len(part3)==3) and ("3-H" in part3[0]) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
                #print(parts, 1)
                runner_on_1st = 1
                runner_on_2nd = 0
                runner_on_3rd = 1
                outs = outs + 1
                if team_at_bat == 1:
                    hs = hs+1
                else:
                    vs = vs+1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
        if (len(part3)==3) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
                #print(parts, 1)
                runner_on_1st = 1
                runner_on_2nd = 1
                runner_on_3rd = 0
                outs = outs + 1
                if team_at_bat == 1:
                    hs = hs+1
                else:
                    vs = vs+1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
        if (len(part3)==3) and ("2-H" in part3[0]) and ("1-3" in part3[1]) and ("B-1" in part3[2]):
                #print(parts, 1)
                runner_on_1st = 1
                runner_on_2nd = 0
                runner_on_3rd = 1
                outs = outs + 1
                if team_at_bat == 1:
                    hs = hs+1
                else:
                    vs = vs+1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
        if (len(part3)==3) and ("2-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
                #print(parts, 1)
                runner_on_1st = 1
                runner_on_2nd = 1
                runner_on_3rd = 0
                outs = outs + 1
                if team_at_bat == 1:
                    hs = hs+1
                else:
                    vs = vs+1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
        if "(" in part1:
            indxs = []
            bases_out = []
            for i in range(len(part1)):
                if part1[i]=="(":
                    indxs = indxs + [i]
                    bases_out = bases_out + [part1[i+1]]
                    outs = outs + 1
            #indx = part1.index("(")
            #print("5 FO",indxs, part1, outs, bases_out,bases_out == ["1","2"])
            if ("(1)" in part1) and ("2" in part1) and ("GTP" in part2) and (len(part3)==1) and (len(part3[0])==0):
                    outs = outs + 2
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
            if len(bases_out)==2:
                if (bases_out == ["1","2"]) and len(part3)==0:
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (bases_out == ["1","2"]) and ("GTP" in part2) and (len(part3)==1) and (len(part3[0])==0):
                    outs = outs + 1
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (bases_out == ["1","2"]) and (len(part3)==1) and ("B-1" in part3[0]):
                    #outs = outs + 1
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (bases_out == ["1","3"]) and len(part3)==0:
                    runner_on_1st = 0
                    runner_on_3rd = 0
                if (bases_out == ["2","3"]) and len(part3)==0:
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (bases_out == ["2","3"]) and len(part3)==2 and ("1-2" in part3[0]) and ("B-1" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)    
            if len(bases_out)==1:
                #print("1", bases_out)
                base_out = bases_out[0]
                #print("5 FO2",indxs, part1, outs, bases_out, base_out, ("FO" in part2), (len(part3)==2), ("1-H" in part3[0]), ("B-2" in part3[1]))
            if base_out=="1":
                #print("1", part3,len(part3)==2,"3X" in part3[0],"2-3" in part3[1])
                if (len(part3)==2) and ("M" in field6) and (len(part3[0])==0):
                    #print("2")
                    runner_on_1st = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)>0) and (len(part3[0])==0):
                    #print("2")
                    #runner_on_1st = 0
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("2-3" in part3[0]):
                    #print("2")
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("B-2" in part3[0]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("BX1" in part3[0] and "E" in part3[0]):
                    #print("2")
                    runner_on_1st = 1
                    #runner_on_2nd = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("BX2" in part3[0] and "E" in part3[0]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("3-H" in part3[0]):
                    #print("2")
                    runner_on_1st = 1
                    #runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part2)>1 and "G" in part2[1]) and (len(part3)==1) and ("2-H" in part3[0]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("3-H" in part3[0]) and ("2-H" in part3[1]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+2
                    else:
                        vs = vs+2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("3-H" in part3[0]) and ("B-2" in part3[1]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("2-H" in part3[0]) and ("BX2" in part3[1]) and ("E" in part3[1]):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 2
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                #print("FO1with2-H", "FO" in part2, len(part3)==2, "2-H" in part3[0], "BX1" in part3[1], "E" in part3[1])
                if ("FO" in part2) and (len(part3)==2) and ("2-H" in part3[0]) and ("BX1" in part3[1]) and ("E" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("2XH" in part3[0]) and ("E" in part3[0]) and ("B-1" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("2-H" in part3[0]) and ("BX2" in part3[1]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-2" in part3[2]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+2
                    else:
                        vs = vs+2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and ("DP" in part2) and len(part3)==2 and ("2XH" in part3[0]) and not("E" in part3[0]) and ("B-1" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    outs = outs + 2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)>0) and (len(part3[0])==0):
                    #print("2")
                    runner_on_1st = 0
                    outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==1) and ("2-3" in part3[0]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==1) and ("3-H" in part3[0]):
                    #print("2")
                    runner_on_1st = 0
                    #runner_on_2nd = 0
                    runner_on_3rd = 0
                    outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("3-H" in part3[0]) and ("2-3" in part3[1]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and not("E" in part3[0]) and ("2-3" in part3[0]) and ("B-1" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    #outs = outs + 1
                    #print("2", outs)
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("E" in part3[0]) and ("2-H" in part3[0]) and ("B-1" in part3[1]):
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    #print("2", outs)
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 1
                    outs = outs + 2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                #print(1)
                if not("B-1" in sum_part3) and not("B-2" in sum_part3):
                    #print(2)
                    outs = outs + 1
                    runner_on_1st = 0
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    #print(2,x)
                    return reset_state(v, season)
                else:
                    #print(part3, "B-2" in part3)
                    runner_on_1st = 0
                    if (len(part3)==1) and ("B-1" in part3[0]):
                        #outs = outs + 1
                        runner_on_1st = 1
                        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                        return reset_state(v, season)
                    if (len(part3)==1) and ("B-2" in part3[0]):
                        #outs = outs + 1
                        runner_on_2nd = 1
                        #print(4)
                        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                        return reset_state(v, season)
                    if (len(part3)==2) and ("3X" in part3[0]) and ("B-1" in part3[1]):
                        #print(1,parts)
                        runner_on_1st = 1
                        runner_on_3rd = 0
                        outs = outs+1
                        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                        return reset_state(v, season)
                    if (len(part3)==2) and ("2-H" in part3[0]) and ("B-2" in part3[1]):
                        #print(parts, 1)
                        runner_on_1st = 0
                        runner_on_2nd = 1
                        runner_on_3rd = 0
                        #outs = outs + 1
                        if team_at_bat == 1:
                            hs = hs+1
                        else:
                            vs = vs+1
                        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                        return reset_state(v, season)
                if (len(part3)==3) and ("3-H" in part3[0]) and ("2-H" in part3[1]) and ("B-1" in part3[2]):
                    #print(parts, 1)
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+2
                    else:
                        vs = vs+2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==3) and ("3-H" in part3[0]) and ("2X" in part3[1]) and ("B-1" in part3[2]):
                    #print(parts, 1)
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 0
                    outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("B-1" in part3[2]):
                    #print(parts, 1)
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==1) and ("2-3" in part3[0]):
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                if (len(part3)==2) and ("3-H" in part3[0]) and ("B-1" in part3[1]):
                    #outs = outs + 1
                    runner_on_1st = 1
                    runner_on_3rd = 0
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and (part3[0]==[]) and ("2-3" in part3[1]):
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                #return (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                ## test for "E"
                if (len(part3)==1) and ("E" in part3[0]):
                    #outs = outs + 1
                    #print("E")
                    runner_on_1st = 0
                    if ("B-1" in part3[0]):
                       runner_on_1st = 1
                    if ("B-2" in part3[0]):
                       #print("E2")
                       runner_on_1st = 0
                       runner_on_2nd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    #print(x, "3")
                    return reset_state(v, season)
            elif base_out=="2":
                if (len(part3)>0) and (len(part3[0])==0):
                    #print("2")
                    runner_on_2nd = 0
                    outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==1) and ("1-2" in part3[0]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("1-H" in part3[0]) and ("B-2" in part3[1]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("1-3" in part3[0]) and ("E" in part3[0]) and ("B-1" in part3[1]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    #outs = outs + 1
                    #if team_at_bat == 1:
                    #    hs = hs+1
                    #else:
                    #    vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("1-2" in part3[0]) and ("B-1" in part3[1]):
                    #print("2")
                    runner_on_1st = 1
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    #if team_at_bat == 1:
                    #    hs = hs+1
                    #else:
                    #    vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("GDP" in part2) and (len(part3)==1) and ("1-2" in part3[0]):
                    #print(2)
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    #runner_on_3rd = 0
                    outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("1-2" in part3[0]) and ("B-1" in part3[1]):
                    #print(2)
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("3-H" in part3[0]) and ("1-2" in part3[1]):
                    #print("2")
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 1
                    outs = outs + 2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                #print(2, "B-1" in sum_part3)
                if not("B-1" in sum_part3) and not("B-2" in sum_part3):
                    outs = outs + 2
                else:
                    outs = outs + 1
                    if not("B-1" in part3):
                       runner_on_1st = 1
                    if not("B-2" in part3):
                       runner_on_2nd = 1
                if outs>2:
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==3) and ("3-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]):
                    #print(parts, 1)
                    runner_on_1st = 1
                    runner_on_2nd = 1
                    runner_on_3rd = 0
                    #outs = outs + 1
                    if team_at_bat == 1:
                        hs = hs+1
                    else:
                        vs = vs+1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                runner_on_2nd = 0
                if (len(part3)==1) and (part3[-1][:3]=="1-2"):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="1-2"):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                #return (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            elif base_out=="3":
                #print(3)
                if (len(part3)>0) and (len(part3[0])==0):
                    #print("2")
                    runner_on_3rd = 0
                    outs = outs + 2
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==1) and (part3[-1][:3]=="1-2"):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==1) and (part3[-1][:3]=="2-3"):
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="1-2"):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if ("FO" in part2) and (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
                    #print("2")
                    #runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 1
                    #outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and ("2-3" in part3[0]) and ("1-2" in part3[1]):
                    runner_on_1st = 0
                    runner_on_2nd = 1
                    runner_on_3rd = 1
                    outs = outs + 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="2-3"):
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                    return reset_state(v, season)
                #if (len(part3)==3) and ("2-H" in part3[0]) and ("1-2" in part3[1]) and ("B-1" in part3[2]): ## duplicate??
                #    #print(parts, 1)
                #    runner_on_1st = 1
                #    runner_on_2nd = 1
                #    runner_on_3rd = 0
                #    #outs = outs + 1
                #    if team_at_bat == 1:
                #        hs = hs+1
                #    else:
                #        vs = vs+1
                #    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                #    return reset_state(v, season)
                #return (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        else:
            outs = outs+1
        ############### end      if "(" in part1
        #########     and so test for "DP"
        ############       check if "DP"
        if len(part2)>0 and ("DP" in part2[0]) and (outs>0):
            outs = outs+2
            v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
            return reset_state(v, season)
        if ("DP" in part2) or (len(part2)>0 and ("DP" in part2[0])):
            if (len(part3)==1) and ("X" in part3[0]):
                outs = outs + 1
                sum_part3 = part3[0]
                i0 = sum_part3.index("X")
                base = sum_part3[i0-1]
                if base == "1":
                    runner_on_1st = 0
                if base == "2":
                    runner_on_2nd = 0
                if base == "3":
                    runner_on_3rd = 0
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
            if (len(part3)==2) and ("2-3" in part3[0]) and ("X" in part3[1]):
                outs = outs + 1
                sum_part3 = part3[1]
                i0 = sum_part3.index("X")
                base = sum_part3[i0-1]
                if base == "1":
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                if base == "2":
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                if base == "3":
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
            if (len(part3)==3) and ("3-H" in part3[0]) and ("2-3" in part3[1]) and ("X" in part3[2]):
                outs = outs + 1
                if team_at_bat == 1:
                    hs = hs+1
                else:
                    vs = vs+1
                sum_part3 = part3[2]
                i0 = sum_part3.index("X")
                base = sum_part3[i0-1]
                if base == "1":
                    runner_on_1st = 0
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                if base == "2":
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                if base == "3":
                    runner_on_2nd = 0
                    runner_on_3rd = 1
                v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
                return reset_state(v, season)
        #############################################
        if (len(part3)==1) and (part3[-1][:3]=="1-2"):
            runner_on_1st = 0
            runner_on_2nd = 1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="1-2"):
            runner_on_1st = 0
            runner_on_2nd = 1
        if (len(part3)==1) and (part3[-1][:3]=="2-3"):
            runner_on_2nd = 0
            runner_on_3rd = 1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="2-3"):
            runner_on_2nd = 0
            runner_on_3rd = 1
        if (len(part3)==1) and (part3[-1][:3]=="1-3"):
            runner_on_1st = 0
            runner_on_3rd = 1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="1-3"):
            runner_on_1st = 0
            runner_on_3rd = 1
        if (len(part3)==1) and (part3[-1][:3]=="3-H") and team_at_bat==0:
            #runner_on_1st = 0
            runner_on_3rd = 0
            vs = vs+1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="3-H") and team_at_bat==0:
            #runner_on_1st = 0
            runner_on_3rd = 0
            vs = vs+1
        if (len(part3)==1) and (part3[-1][:3]=="3-H") and team_at_bat==1:
            #runner_on_1st = 0
            runner_on_3rd = 0
            hs = hs+1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="3-H") and team_at_bat==1:
            #runner_on_1st = 0
            runner_on_3rd = 0
            hs = hs+1
        if (len(part3)==1) and (part3[-1][:3]=="2-H") and team_at_bat==0:
            #runner_on_1st = 0
            runner_on_2nd = 0
            vs = vs+1
        if (len(part3)==2) and (part3[0]==[]) and (part3[-1][:3]=="2-H") and team_at_bat==0:
            #runner_on_1st = 0
            runner_on_2nd = 0
            vs = vs+1
        if (len(part3)==1) and (part3[-1][:3]=="2-H") and team_at_bat==1:
            #runner_on_1st = 0
            runner_on_2nd = 0
            hs = hs+1
    #################################################################################
    if outs>2:
        gs = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        #(outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat) = reset_state(gs, season)
    else:
        v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
        return reset_state(v, season)
    return (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)

def reset_state(cgs, season = 2022):
    """
    Returns the reset game state when there are three outs.

    ##############################    
    Need to add the info_inning parameter to the state, as this number is where the game
    is typically over (9 innings). For double headers, this could be 7 innings, with a player
    on 2nd base if the game is tied on reaching that point. For tie games in 2020 or later, 
    there is a player on 2nd after this many inning. 
    For now, we simply set this as a global constant.
    ##############################

    EXAMPLES:
        sage: cgs = (3, 0, 1, 0, 5, 3, 3, 1)
        sage: cgs = reset_state(cgs); cgs
         (0, 0, 0, 0, 6, 3, 3, 0)
        sage: season = 2018
        sage: cgs = (3, 0, 1, 0, 11, 3, 3, 1)
        sage: cgs = reset_state(cgs, season); cgs
         (0, 0, 0, 0, 12, 3, 3, 0)


    """
    outs = cgs[0]
    if outs < 3:
        return cgs
    gm_st = cgs
    outs = gm_st[0]
    runner_on_1st = gm_st[1]
    runner_on_2nd = gm_st[2]
    runner_on_3rd = gm_st[3]
    inning = gm_st[4]
    vs = gm_st[5]
    hs = gm_st[6]
    team_at_bat = gm_st[7]
    if outs>2:
        outs = 0
        runner_on_1st = 0
        runner_on_2nd = 0
        runner_on_3rd = 0
        if team_at_bat==1:
            inning = inning + 1
            #print(inning, season, inning > info_inning_parameter, season > 2019, team_at_bat)
            if (inning > info_inning_parameter) and (season > 2019):  ## typically, info_inning_parameter = 9
                runner_on_2nd = 1
            team_at_bat = 0
        else:
            #print(inning, season, inning > info_inning_parameter, season > 2019, team_at_bat)
            team_at_bat = 1
            if (inning > info_inning_parameter) and (season > 2019):  ## typically, info_inning_parameter = 9
                runner_on_2nd = 1
    v = (outs, runner_on_1st, runner_on_2nd, runner_on_3rd, inning, vs, hs, team_at_bat)
    #print(season, inning, inning > info_inning_parameter, season > 2019, cgs, v)
    return v

def event_file_to_game_states(game_file, verbose=False):
    """
    This returns the list of plays and corresponding game states.

    This function is useful for debugging output flagged by the 
    warning "The at-bat records between the state and the play record are inconsistent. Try again."
    
    verbose=True returns results form inning_ender as well
    
    EXAMPLES:
        sage: game_file = "game-file_NYY-BAL_2023-04-08.txt"
        sage: L = event_file_to_game_states(game_file)
        sage: L[0]
         ('play,1,0,lemad001,22,BCFBS,K', (1, 0, 0, 0, 1, 0, 0, 0))
        sage: L[81]
         ('play,9,1,fraza001,22,CB.SBX,6/L6', (2, 0, 1, 0, 9, 4, 1, 1))
        sage: L[82]
         ('play,9,1,uriar001,10,.*BX,43/G4', (0, 0, 0, 0, 10, 4, 1, 0))
        sage: game_file = "WAS-BAL-2022-06-22-0.txt"
        sage: event_file_to_game_states(game_file)
         [('play,1,0,hernc005,12,BFCX,4/L34-', (1, 0, 0, 0, 1, 0, 0, 0)),
         ('play,1,0,sotoj001,00,X,E6/G4D.B-1', (1, 1, 0, 0, 1, 0, 0, 0)),
         ('play,1,0,bellj005,11,C1BX,S8/L8S.1X3(85)', (2, 1, 0, 0, 1, 0, 0, 0)),
          ...
         ('play,6,1,manct001,10,BX,HR/F7LD.2-H', (2, 0, 0, 0, 6, 0, 7, 1)),
         ('play,6,1,santa003,12,BCSX,S8/L8D', (2, 1, 0, 0, 6, 0, 7, 1)),
         ('play,6,1,mounr001,00,,NP', (2, 1, 0, 0, 6, 0, 7, 1)),
         ('play,6,1,mounr001,12,.CBSFX,9/F89D', (0, 0, 0, 0, 7, 0, 7, 0))]
        sage: game_file = "/BAL-home_2022/NYA-BAL-2022-04-15-0.txt"
        sage: L = event_file_to_game_states(game_file); L
        [('play,1,0,rizza001,02,FFFH,HP', (0, 0, 0, 0, 1, 0, 0, 0)),
         ('play,1,0,stanm004,01,SX,S8/G6M.1-2', (0, 0, 1, 0, 1, 0, 0, 0)),
         ('play,1,0,donaj001,01,CX,8/F8D', (1, 0, 1, 0, 1, 0, 0, 0)),
         ('play,1,0,gallj002,12,BFCX,31/G34.2-3;1-2', (2, 0, 1, 0, 1, 0, 0, 0)),
         ...
         ('play,11,0,gallj002,00,X,2/G2-', (0, 0, 0, 0, 11, 1, 0, 1)),
         ('radj,haysa001,2', (0, 0, 1, 0, 11, 1, 0, 1)),
         ('play,11,1,matej003,02,.LLFX,6/L6D', (1, 0, 1, 0, 11, 1, 0, 1)),
         ('play,11,1,bemba001,32,BBBCCB,W', (1, 1, 1, 0, 11, 1, 0, 1)),
         ('play,11,1,gutik001,32,SSB2BBFB,W.2-3;1-2', (1, 1, 1, 0, 11, 1, 0, 1)),
         ('play,11,1,mullc002,02,.CCFS,K', (2, 1, 1, 0, 11, 1, 0, 1)),
         ('play,11,1,uriar001,32,CFBB*B.>B,W.3-H(UR);2-3;1-2', (2, 1, 1, 0, 11, 1, 0, 1))]
        sage: L = event_file_to_game_states(game_file, verbose=True)
        sage: L[:8]
        [('play,1,0,lemad001,22,BCFBS,K', (1, 0, 0, 0, 1, 0, 0, 0), 0),
         ('play,1,0,judga001,32,BBBCSF.FB,W', (1, 1, 0, 0, 1, 0, 0, 0), 0),
         ('play,1,0,rizza001,02,CFFX,36(1)1/GDP/G3', (0, 0, 0, 0, 1, 0, 0, 1), 1),
         ('play,1,1,mullc002,02,CFX,S7/L7', (0, 1, 0, 0, 1, 0, 0, 1), 1),
         ('play,1,1,rutsa001,31,B1BBCX,S17/G1.1-3', (0, 1, 0, 1, 1, 0, 0, 1), 1),
         ('play,1,1,santa003,32,BBBFS.FFFX,9/SF/F89XD+.3-H', (1, 1, 0, 0, 1, 0, 1, 1), 0),
         ('play,1,1,mounr001,10,BX,54(1)/FO/G56.B-1', (2, 1, 0, 0, 1, 0, 1, 1), 0),
         ('play,1,1,hendg002,12,CF.BX,56(1)/FO/G56.B-1', (0, 0, 0, 0, 2, 0, 1, 0), 0)]

    """
    game_dir = ""
    #game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    #L = event_file_to_game_states(game_dir+game_file)
    game_file0 = retrosheet_directory + game_dir + game_file
    #print("bdcl->sobp->eftgs", game_file, "2\n", game_dir, "3\n", game_file0)
    f = open(game_file0)
    lines = f.readlines()
    N0 = len(lines)
    #print(N0)
    ans = []
    cgs = (0,0,0,0,1,0,0,0)
    season = 2023                            #### default initialization
    #print(season)
    for f1 in lines:
        f2 = f1.rstrip()
        spl_rec = f2.split(",")
        #print(spl_rec)
        if spl_rec[0]=="id":
            season = ZZ(spl_rec[1][3:7])    #### corrected season
            #print(season)
        if len(spl_rec)>6:
            parts = separate_field_into_parts(spl_rec[-1])
            #print(spl_rec, parts)
        #print(cgs, f2)
        if (f2[:4]=="play" or f2[:4]=="radj") and not("NP" in parts[0]):
            #print(f2, season, cgs)
            cgs = convert_to_state(cgs, f2, season)
            #print(f2, season, cgs)
            if not(verbose):
                ans = ans + [(f2, cgs)]
            if verbose:
                #print("3", game_file)
                ans = ans + [(f2, cgs, inning_ender(f2, game_file)[-1])]
            #cgs = cgs0
            #print(cgs, len(ans), f2)
    f.close()
    return ans



##################################################################################
## using event_file_to_game_states is isn't too hard to write a Boolean function
## which answers the question:
## did the at-bat team score a run sometime later that same inning?
## Input: * a play (as a string), and
##        * an event file (or game file)
## Output: True/False
##################################################################################

def inning_ender(play_event, game_file):
    """
    Input: 
    * play_event - a play (as a string in Retrosheet play record notation)
    * game_file - a file of a game (named as a string, while the file itself
                  is a series of records from a single game in Retrosheet 
                  event game notation) that should include the play given
                  in the first argument.
    Returns a pair:
     1) the play (as a string in Retrosheet play record notation)
        that ends the inning for the given play <play_event> in the given
        game <game_file> (as a file in Retrosheet event/single game notation), 
        and if the given play itself ends the inning, it simply returns
        <play_event>, and
     2) the difference between the team score at the end of the inning
        and the team score at the start of the <play_event> at-bat. 


    EXAMPLES:
        sage: game_file = "NYA-BAL-2023-04-08-0.txt" # opening home game of 2023 for BAL
        sage: play_event = 'play,1,0,lemad001,22,BCFBS,K' # first at-bat of the game
        sage: inning_ender(play_event, game_file)
         ('play,1,0,rizza001,02,CFFX,36(1)1/GDP/G3', 0)
        sage: play_event = 'play,5,0,volpa001,12,FFBX,T8/F9D+'
        sage: inning_ender(play_event, game_file)
         ('play,5,0,torrg001,31,BCBBX,4/P34D', 3)

    """
    L = event_file_to_game_states(game_file)
    N = len(L)
    L1 = [x[0] for x in L] ## the plays, as RS strings
    L2 = [x[1] for x in L] ## the corresponding states
    if not(play_event in L1):
        print("The play " + play_event + " did not occur in game " + game_file)
        return play_event, -1
    i0 = L1.index(play_event)
    at_bat = L2[i0][-1] ## the last coordinate of the game state associated to the given play
    if at_bat == 0: ## visiting team
        current_score = L2[i0][-3]
    else:  ## at_bat = home team
        current_score = L2[i0][-2]
    for i in range(i0, N-1):
        if L2[i][-1] != at_bat:
            if at_bat == 0: ## visiting team
                 return L1[i+1], L2[i+1][-3]-current_score
            else: ## home team
                 return L1[i+1], L2[i+1][-2]-current_score
    return play_event, -1


def frequency_game_states(game_file, verbose=False):
    """
    Returns the list of game states reached in the game, by either team, 
    and their frequency (in the lex order). 
   
    The verbose option returns ?????nonesense????
      ##### still under construction

    EXAMPLES:
        sage: game_file = "NYA-BAL_2023-04-08-0.txt"
	sage: frequency_game_states(game_file)
	[((0, 0, 0, 0), 18),
	 ((1, 0, 0, 0), 14),
	 ((2, 0, 0, 0), 8),
	 ((0, 1, 0, 0), 4),
	 ((1, 1, 0, 0), 10),
	 ((2, 1, 0, 0), 7),
	 ((0, 0, 1, 0), 1),
	 ((1, 0, 1, 0), 1),
	 ((2, 0, 1, 0), 4),
	 ((0, 0, 0, 1), 2),
	 ((1, 0, 0, 1), 0),
           ...
        ]
        sage: game_file = "NYA-BAL-2023-04-08-0.txt" # opening home game of 2023 for BAL
        sage: frequency_game_states(game_file, verbose=True)
        total occurrances:  76
        total states:  16
        [(17, (0, 0, 0, 0)),
         (31, (1, 0, 0, 0)),
         (39, (2, 0, 0, 0)),
         (40, (0, 1, 0, 0)),
         (48, (1, 1, 0, 0)),
         (54, (2, 1, 0, 0)),
         (55, (0, 0, 1, 0)),
         (56, (1, 0, 1, 0)),
         (59, (2, 0, 1, 0)),
         (61, (0, 0, 0, 1)),
         (61, (1, 0, 0, 1)),
         (62, (2, 0, 0, 1)),
         (63, (0, 1, 1, 0)),
         (65, (1, 1, 1, 0)),
         (66, (2, 1, 1, 0)),
         (66, (0, 1, 0, 1)),
         (66, (1, 1, 0, 1)),
         (67, (2, 1, 0, 1)),
         (67, (0, 0, 1, 1)),
         (67, (1, 0, 1, 1)),
         (67, (2, 0, 1, 1)),
         (67, (0, 1, 1, 1)),
         (67, (1, 1, 1, 1)),
         (67, (2, 1, 1, 1))]

    """
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    L1 = event_file_to_game_states(game_file, verbose)
    #print("Opening: " + game_file + " from frequency_game_states. \n")
    #print(L1)
    L1_notNP = []        ## don't count "NP"
    for x in L1:
        pr = x[0]
        spl_rec = pr.split(",")
        field6 = spl_rec[-1]
        if not("NP" in field6):
            L1_notNP = L1_notNP + [x]
        #else:
            #print(x)
            #break
    print([(x[1],x[2]) for x in L1_notNP])
    if verbose:
        L2b = [(x[1], int(math.copysign(1, x[1][-1]-0.1))) for x in L1_notNP] # 2nd entry = 1.0 if they score
	                                                              # in that inning, = 0 otherwise
        L2b_indices = []
        for s in bb_states:
            count_s = 0
            for y in L2b:
                #print(y, s, verbose, y[:4] == s)
                if y[:4] == s:
                    count_s = count_s + 1
            L2b_indices = L2b_indices + [(s, count_s)]
        #print(L2b_indices)
    L2 = [ZZ4(x[1][:4]) for x in L1_notNP]
    #print(len(L1_notNP), len(L2))
    ttl = 0
    L3 = []
    L3b = []
    sts = []
    for i in range(24):
        y = ZZ4(bb_states[i])
        #print(y, list_as_function(y, L2b_indices))
        ct = L2.count(y)
        L3 = L3 + [(ct, y)]
        if verbose:
            L3b = L3b + [(y, ct, list_as_function(y, L2b_indices))]
        ttl = ttl+ct
        if ct>0:
            sts = sts + [y]
    L3.sort()
    if verbose:
        print("total occurrances: ",ttl)
        print("total states: ",len(sts))
        print(L2b)
        return L2b_indices
    else:
        L3.reverse()
        return L3

def frequency_game_states_VT(game_file, verbose=False):
    """
    Returns the list of game states reached in the game by the Visiting Team (VT)
    and their frequency (in the lex order). The verbose option returns the same output but 
    prints out more detailed information.

    EXAMPLES:
        sage: game_file = "game-file_NYY-BAL_2023-04-08.txt"
	sage: frequency_game_states_VT(game_file, verbose=False)
	[((0, 0, 0, 0), 9),
	 ((1, 0, 0, 0), 7),
	 ((2, 0, 0, 0), 5),
	 ((0, 1, 0, 0), 2),
	 ((1, 1, 0, 0), 4),
	 ((2, 1, 0, 0), 2),
	 ((0, 0, 1, 0), 1),
	 ((1, 0, 1, 0), 0),
	  ...

    """
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    L1 = event_file_to_game_states(game_file)
    #print(L1)
    L1_notNP = []
    for x in L1:
        pr = x[0]
        spl_rec = pr.split(",")
        field6 = spl_rec[-1]
        if not("NP" in field6):
            L1_notNP = L1_notNP + [x]
        #else:
            #print(x)
            #break
    L2 = [ZZ4(x[1][:4]) for x in L1_notNP if x[1][7]==0]
    #print(len(L1_notNP), len(L2))
    ttl = 0
    L3 = []
    sts = []
    for i in range(24):
        y = ZZ4(bb_states[i])
        ct = L2.count(y)
        L3 = L3 + [(y, ct)]
        ttl = ttl+ct
        if ct>0:
            sts = sts + [y]
    if verbose:
        print("total occurrances: ",ttl)
        print("total states: ",len(sts))
        return L3
    else:
        return L3

def frequency_game_states_HT(game_file, verbose=False):
    """
    Returns the list of game states reached in the game by the Home Team (HT)
    and their frequency (in the lex order).

    EXAMPLES:
        sage: game_file = "game-file_NYY-BAL_2023-04-08.txt"
	sage: frequency_game_states_HT(game_file, verbose=True)
	total occurrances:  37
	total states:  9
	[((0, 0, 0, 0), 9),
         ((1, 0, 0, 0), 7),
         ((2, 0, 0, 0), 3),
         ((0, 1, 0, 0), 2),
         ((1, 1, 0, 0), 6),
	 ((2, 1, 0, 0), 5),
	 ((0, 0, 1, 0), 0), ...

    Here, the "total states" counts those distinct states that arose
    in the game. In the above example, the first six states did arise but 
    seventh one (listed last above), the state (0, 0, 1, 0), did not arise.
    Therefore, it would not be added to the six and would not contribute to 
    the total state count.

    """
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    L1 = event_file_to_game_states(game_file)
    #print(L1)
    L1_notNP = []
    for x in L1:
        pr = x[0]
        spl_rec = pr.split(",")
        field6 = spl_rec[-1]
        if not("NP" in field6):
            L1_notNP = L1_notNP + [x]
        #else:
            #print(x)
            #break
    L2 = [ZZ4(x[1][:4]) for x in L1_notNP if x[1][7]==1]
    #print(len(L1_notNP), len(L2))
    ttl = 0
    L3 = []
    sts = []
    for i in range(24):
        y = ZZ4(bb_states[i])
        ct = L2.count(y)
        L3 = L3 + [(y, ct)]
        ttl = ttl+ct
        if ct>0:
            sts = sts + [y]
    if verbose:
        print("total occurrances: ",ttl)
        print("total states: ",len(sts))
        return L3
    else:
        return L3 


def frequency_homegames_states(season = 2022, team = "BAL"):
    """
    Returns totals for the homegames in the given season for the given team.

    EXAMPLES:

    """
    master_dir = team+"-home_"+str(season)+"/"
    mypath = retrosheet_directory + master_dir
    from os import listdir
    from os.path import isfile, join
    game_files = [f for f in listdir(mypath) if isfile(join(mypath, f))]
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    #print(master_dir,mypath, len(game_files))
    L1 = []
    L2 = []
    N = len(game_files)
    NN = 24 # = len(bb_states)
    #print(N,NN)
    for i in range(N):
        fl = master_dir+game_files[i]
        L1 = L1 + [frequency_game_states(fl)]
    for j in range(NN):
        freq = 0
        for i in range(N):
            freq = freq + L1[i][j][0]
        a = bb_states[j]
        L2 = L2 + [(a,freq)]
    return L2

def frequency_games_states(game_files, verbose=False):
    """
    Returns totals for the games in the list of strings, game_files.
    ###########
    ####### modify so it creates a list of temp game files, stored in /tmp,
    ####### from the given season and team. Then read these in and add them up.
    ###########

    EXAMPLES:
        sage: game_files = ["game-file_NYY-BAL_2023-04-07.txt", "game-file_NYY-BAL_2023-04-08.txt"]
        sage: frequency_games_states(game_files)
        [((0, 0, 0, 0), 35),
         ((1, 0, 0, 0), 24),
         ((2, 0, 0, 0), 17),
         ((0, 1, 0, 0), 10),
         ((1, 1, 0, 0), 15),
         ((2, 1, 0, 0), 13),
         ((0, 0, 1, 0), 5),
         ((1, 0, 1, 0), 8),
         ((2, 0, 1, 0), 8),
         ((0, 0, 0, 1), 2),
         ((1, 0, 0, 1), 2),
         ((2, 0, 0, 1), 6),
         ((0, 1, 1, 0), 3),
         ((1, 1, 1, 0), 5),
         ((2, 1, 1, 0), 7),
         ((0, 1, 0, 1), 2),
         ((1, 1, 0, 1), 1),
         ((2, 1, 0, 1), 1),
         ((0, 0, 1, 1), 1),
         ((1, 0, 1, 1), 0),
         ((2, 0, 1, 1), 0),
         ((0, 1, 1, 1), 0),
         ((1, 1, 1, 1), 0),
         ((2, 1, 1, 1), 0)]
        sage: game_files = ["game-file_NYY-BAL_2023-04-07.txt", "game-file_NYY-BAL_2023-04-08.txt", "game-file_NYY-BAL_2023-04-09.txt"]
        sage: frequency_games_states(game_files)
        [((0, 0, 0, 0), 56),
         ((1, 0, 0, 0), 39),
         ((2, 0, 0, 0), 29),
         ((0, 1, 0, 0), 13),
         ((1, 1, 0, 0), 21),
         ((2, 1, 0, 0), 15),
         ((0, 0, 1, 0), 7),
         ((1, 0, 1, 0), 11),
         ((2, 0, 1, 0), 11),
         ((0, 0, 0, 1), 2),
         ((1, 0, 0, 1), 2),
         ((2, 0, 0, 1), 6),
         ((0, 1, 1, 0), 3),
         ((1, 1, 1, 0), 7),
         ((2, 1, 1, 0), 8),
         ((0, 1, 0, 1), 2),
         ((1, 1, 0, 1), 2),
         ((2, 1, 0, 1), 2),
         ((0, 0, 1, 1), 1),
         ((1, 0, 1, 1), 1),
         ((2, 0, 1, 1), 0),
         ((0, 1, 1, 1), 0),
         ((1, 1, 1, 1), 0),
         ((2, 1, 1, 1), 0)]

    """
    ##### collect frequency lists for each of the games then add them up
    ##### and return the sum.
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    #print(game_files)
    L1 = []
    L2 = []
    N = len(game_files)
    NN = 24 # = len(bb_states)
    #print(N,NN)
    for i in range(N):
        fl = game_files[i]
        L1 = L1 + [frequency_game_states(fl)]
    for j in range(NN):
        freq = 0
        for i in range(N):
            freq = freq + L1[i][j][0]
        a = bb_states[j]
        L2 = L2 + [(a,freq)]
    return L2

def frequency_states_team_season(season = 2022, team="BAL", post_season = False, save_game_files = False):
    """
    Returns the state totals for the home games in the given season and home team.

    ###########
    ####### modify so it creates a list of temp game files, stored in /tmp,
    ####### from the given season and team. Then read these in and add them up.
    ###########

    EXAMPLES:
        
    """
    if team in ["SFN","PHI", "NYN","SDN","MIL","LAN","COL"]:
        master_file = str(season)+team+".EVN"
    else:
        master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    f = open(master_file0,"r")
    #print(master_file0)
    lines = f.readlines()
    N0 = len(lines)
    #print(N0)
    team_and_date = ""
    ht_name = master_file[4:][:3]
    for i in range(N0):
        f1 = lines[i].rstrip()
        if f1[:3]=="id," and (i<N0-2):
            team = lines[i+2][-4:].rstrip()
            date = f1[6:][:4]+"-"+f1[6:][4:6]+"-"+f1[6:][6:8]+"-"+f1[6:][8:9]
            team_and_date = team_and_date + team +"-"+ ht_name +"-"+ date +","
            #vt_list = vt_list + [(i, lines[i+2][-4:])]
            #id_list = id_list + [(i, f1[6:])]
            #print((i, lines[i+2][-4:]), (i, f1[6:]))
    ## we now can create tmp filenames for the game files.
    ### loop over the list in team_and_date.split(",") and call
    ### each entry+".txt" game_outfile. Next call
    ### save_game_event_log(game_outfile, master_file = "2023BAL.EVA", play_date)
    ###
    gfs = []
    game_filenames = team_and_date.split(",")
    if ("" in game_filenames):
        game_filenames.remove("")
    #print("game filenames: ", game_filenames, "\n")
    for x in game_filenames:
        team_home = x[4:7]
        team_visiting  = x[0:3]
        game_outfile = team_home + "-home_" + str(season) + "/" + x+".txt"
        gfs = gfs+[game_outfile]
        play_date = ""
        for w in x[8:].split("-"):
            play_date = play_date + w
        if save_game_files: 
            save_game_event_log(game_outfile, master_file, play_date, post_season = False)
        #print("Saving: " + game_outfile + "\n")
    tbl = frequency_games_states(gfs, verbose=False)
    f.close()
    return tbl

def frequency_transition_states(game_file, verbose=False):
    """
    Returns the list of pairs of game states reached in the game, 
    by either team, and their frequency (in the lex order).
    
    The verbose option returns the same output but prints out more 
    detailed information. See
    frequency_game_states_HT 
    for an example.
    #########  Warning: verbose=True does not work  ###########

    EXAMPLES:
        sage: game_file = "game-file-NYY-BAL_2023-04-08.txt"
        sage: frequency_transition_states(game_file, verbose=True)
        total occurrances:  75
        total state pairs:  31
        [(((0, 0, 0, 0), (0, 0, 0, 0)), 0),
         (((0, 0, 0, 0), (1, 0, 0, 0)), 12),
         (((0, 0, 0, 0), (2, 0, 0, 0)), 0),
         (((0, 0, 0, 0), (0, 1, 0, 0)), 4),
         ...

    """
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    L1 = event_file_to_game_states(game_file)
    #print(L1)
    L1_notNP = []        ## don't count "NP"
    for x in L1:
        pr = x[0]
        spl_rec = pr.split(",")
        field6 = spl_rec[-1]
        if not("NP" in field6):
            L1_notNP = L1_notNP + [x]
        #else:
            #print(x)
            #break
    L2 = []
    #L2b = []
    N1 = len(L1_notNP)
    for i in range(N1-1):
       x = L1_notNP[i]
       y = L1_notNP[i+1]
       L2 = L2 + [(ZZ4(x[1][:4]),ZZ4(y[1][:4]))]
       #L2b = L2b + [(x[1],y[1])]
    #print(len(L1_notNP), len(L2))
    ttl = 0
    L3 = []
    sts = []
    for i in range(24):
        s1 = ZZ4(bb_states[i])
        for j in range(24):
            s2 = ZZ4(bb_states[j])
            ct = L2.count((s1,s2))
            if not(verbose):
                L3 = L3 + [((s1,s2), ct)]
            #else:
            #    L3 = L3 + [((s1,s2), ct, inning_ender0(s1, game_file)[1])]
            ttl = ttl+ct
            if ct>0:
                sts = sts + [(s1,s2)]
    if verbose:
        print("total occurrances: ",ttl)
        print("total state pairs: ",len(sts))
        return L3
    else:
        return L3


def inning_ender0(game_state, game_file):
    """
    ##### rewrote inning_ender to have the state as the first argument, not the play (as a RS string)
    Input: 
    * game_state - a state (as an 8-tuple in the usual notation)
    * game_file - a file of a game (named as a string, while the file itself
                  is a series of records from a single game in Retrosheet 
                  event game notation) that should include the play game_state,
                  and the string name should be of the form VVV-HHH-YYYY-MM-DD-G.txt
		  where VVV = visiting team name abbreviation,
		        HHH = home team name abbreviation,
			YYYY = season (year) game was played
			MM = month game was played,
			DD = date game was played
			G = 0 if only game of 1st game of double header,
			    1 if 2nd game of double header,
			    and so on.
    Returns a pair:
     1) the game state of the play that ends the inning containing the given 
        state <game_state> in the given game <game_file> (as a file in 
        Retrosheet event/single game notation), 
        and if the given state itself is the end of the inning, 
        it simply returns <game_state>, and
     2) the difference between the team score at the end of the inning
        and the team score at the start of the <play_event> at-bat. 


    EXAMPLES:
        sage: game_file = "NYA-BAL-2023-04-08-0.txt" # opening home game of 2023 for BAL
        sage: game_state =  (0, 0, 0, 1, 5, 1, 1, 0)
        sage: inning_ender0(game_state, game_file)
         ((0, 0, 0, 0, 5, 4, 1, 1), 3)

    """
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    #print("1", game_dir, game_file)
    L = event_file_to_game_states(game_file)
    N = len(L)
    L1 = [x[0] for x in L] ## the plays in the game
    L2 = [x[1] for x in L] ## the corresponding states
    if not(game_state in L2):
        print("The state " + str(game_state) + " did not occur in game " + game_file)
        return game_state, -1
    i0 = L2.index(game_state)
    at_bat = L2[i0][-1] ## the last coordinate of the game state associated to the given play
    if at_bat == 0: ## visiting team
        current_score = L2[i0][-3]
    else:  ## at_bat = home team
        current_score = L2[i0][-2]
    for i in range(i0, N):
        if L2[i][-1] != at_bat:
            if at_bat == 0: ## visiting team
                 return L2[i], L2[i][-3]-current_score
            else: ## home team
                 return L2[i], L2[i][-2]-current_score
    


def frequency_transitions_states(game_files, verbose=False):
    """
    Returns frequency totals for the pairs (s1, s2), where s1->s2, for each game in the list, game_files.
    ###########
    ####### modify so it creates a list of temp game files, stored in /tmp,
    ####### from the given season and team. Then read these in and add them up.
    ###########

    #########  Warning: verbose=True does not work  ###########
    
    EXAMPLES:
        sage: game_files = ["game-file_NYY-BAL_2023-04-07.txt", "game-file_NYY-BAL_2023-04-08.txt"]
        sage: frequency_transitions_states(game_files)


    """
    ##### collect frequency lists for each of the games then add them up
    ##### and return the sum.
    ZZ4 = ZZ^4
    bb_states = baseball_states()
    #print(game_files)
    L1a = []
    L1b = []
    L2 = []
    N = len(game_files)
    for i in range(N):
        fl = game_files[i]
        if not(verbose):
            fts = frequency_transition_states(fl)
        #else:
        #    fts = frequency_transition_states(fl, verbose=True)
        L1a = L1a + [fts]
    L1b = [x[0] for x in fts]
    #NN = len(pairs of states)
    #print(N,NN)
    NN = len(L1b)
    for j in range(NN):
        fr = 0
        for i in range(N):
            fr = fr + L1a[i][j][1]
        a = L1b[j]
        L2 = L2 + [(a,fr)]
    return L2
    

def frequency_transitions_team_season(season = 2022, team="BAL", post_season = False, save_game_files = False, verbose=False):
    """
    Returns the state transition totals for the home games in the given season and home team.
    If the event file (<season><team>.EVA or *.EVN) has already been split up into 
    individual game files located in their own subdirectory.

    NOTE: The subdirectory <team_home + "-home_" + str(season) + "/"> must exists within the events directory.

    NOTE: Use event_file_to_game_states for debugging output flagged by the 
          warning "The at-bat records between the state and the play record are inconsistent. Try again."
          1) Locate the game with the warning
          2) locate game file, eg 
             game_file = "BAL-DET-2023-04-29-1.txt"
          3) run L = event_file_to_game_states(game_file), 
             or perhaps L = event_file_to_game_states("DET-home_2023/"+game_file),
             to help find exact play and current game state, eg
          4) play_record = "play,8,1,ibana001,12,.BFFS,K"
             cgs = (2, 1, 1, 0, 8, 4, 7, 1)
             cgs = convert_to_state(cgs, play_record); cgs  ######## is this expected?
                                                            ######## if not, use separate_field_into_parts for parsing help

    #########  Warning: verbose=True does not work  ###########

    ###########
    ####### modify so it creates a list of temp game files, stored in /tmp,
    ####### from the given season and team. Then read these in and add them up.
    ###########

    EXAMPLES:
        sage: L = frequency_transitions_team_season(season = 2022, team="BAL", post_season = False, save_game_files = False); L[:10]
         [(953, ((0, 0, 0, 0), (1, 0, 0, 0))),
          (729, ((1, 0, 0, 0), (2, 0, 0, 0))),
          (538, ((2, 0, 0, 0), (0, 0, 0, 0))),
          (334, ((0, 0, 0, 0), (0, 1, 0, 0))),
          (326, ((2, 1, 0, 0), (0, 0, 0, 0))),
          (254, ((1, 0, 0, 0), (1, 1, 0, 0))),
          (228, ((1, 1, 0, 0), (2, 1, 0, 0))),
          (212, ((2, 0, 0, 0), (2, 1, 0, 0))),
          (184, ((0, 1, 0, 0), (1, 1, 0, 0))),
          (134, ((2, 0, 1, 0), (0, 0, 0, 0)))]

    """
    if team in NL_team_names:
        master_file = str(season)+team+".EVN"
    elif team in AL_team_names:
        master_file = str(season)+team+".EVA"
    else:
        print("Team name must be in AL or in NL.")
        master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    f = open(master_file0,"r")
    #print(master_file0)
    lines = f.readlines()
    N0 = len(lines)
    #print(N0)
    team_and_date = ""
    ht_name = master_file[4:][:3]
    for i in range(N0-2):
        f1 = lines[i].rstrip()
        if f1[:3]=="id,":
            team = lines[i+2][-4:].rstrip()
            date = f1[6:][:4]+"-"+f1[6:][4:6]+"-"+f1[6:][6:8]+"-"+f1[6:][8:9]
            team_and_date = team_and_date + team +"-"+ ht_name +"-"+ date +","
            #vt_list = vt_list + [(i, lines[i+2][-4:])]
            #id_list = id_list + [(i, f1[6:])]
            #print((i, lines[i+2][-4:]), (i, f1[6:]))
    ## we now can create tmp filenames for the game files.
    ### loop over the list in team_and_date.split(",") and call
    ### each entry+".txt" game_outfile. Next call
    ### save_game_event_log(game_outfile, master_file = "2023BAL.EVA", play_date = "202304080", post_season = False)
    ###
    gfs = []
    game_filenames = team_and_date.split(",")
    if ("" in game_filenames):
        game_filenames.remove("")
    #print(game_filenames)
    for x in game_filenames:
        team_home = x[4:7]
        team_visiting  = x[0:3]
        game_outfile = team_home + "-home_" + str(season) + "/" + x + ".txt"
        gfs = gfs+[game_outfile]
        play_date = ""
        for w in x[8:].split("-"):
            play_date = play_date + w
        if save_game_files: 
            save_game_event_log(game_outfile, master_file, play_date, post_season = False)
    tbl = frequency_transitions_states(gfs, verbose)         #############    verbose=True doesn't work
    f.close()
    if not(verbose):
        tbl2 = [(x[1],x[0]) for x in tbl]
    else:
        tbl2 = [(x[1],x[0],x[2]) for x in tbl]
    tbl2.sort()
    tbl2.reverse()
    ### if verbose=True then *also* return
    ##  1) number of plays until end of inning (using
    ##     event_file_to_game_states function)
    ##  2) difference between team score at end of inning and
    ##     current team score (to see if batter contributed,
    ##     possibly indirectly, a run)
    return tbl2
    

def list_of_homegame_filenames(season = 2023, team = "BAL"):
    """
    Returns chronologically sorted list of games.

    EXAMPLES:
        sage: list_of_homegame_filenames(season = 2022, team = "BAL")
         ['MIL-BAL-2022-04-11-0.txt',
          'MIL-BAL-2022-04-12-0.txt',
          'MIL-BAL-2022-04-13-0.txt',
          'NYA-BAL-2022-04-15-0.txt',
          ...
         ]
        sage: list_of_homegame_filenames(season = 2023, team = "BAL")
         ['NYA-BAL-2023-04-07-0.txt',
          'NYA-BAL-2023-04-08-0.txt',
          'NYA-BAL-2023-04-09-0.txt',
          'OAK-BAL-2023-04-10-0.txt',
          ...
         ]

    """
    master_dir = team+"-home_"+str(season)+"/"
    mypath = retrosheet_directory + master_dir  ## assumes this is populated by games
                                                ## (run frequency_states_team_season(season = 2022, team="BAL")
						## if necessary)
    from os import listdir
    from os.path import isfile, join
    game_files = [f for f in listdir(mypath) if (isfile(join(mypath, f)) and not(".DS_Store" in f))]
    sorted_gamefiles = sorted(game_files, key=extract_date)
    return sorted_gamefiles


def homegame_list(season = 2022, team="BAL", post_season = False):
    """
    Returns the list of all home games in the given season and given home team.

    EXAMPLES:
        sage: homegame_list(season = 2023, team="BAL", post_season = False)
         'NYA-BAL-2023-04-07-0,NYA-BAL-2023-04-08-0, ... ,BOS-BAL-2023-10-01-0,'
    """
    if team in ["SFN","PHI", "NYN","SDN","MIL","LAN","COL"]:
        master_file = str(season)+team+".EVN"
    else:
        master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    f = open(master_file0,"r")
    g = open(game_outfile,"a")
    lines = f.readlines()
    N0 = len(lines)
    #print(N0)
    team_and_date = ""
    ht_name = master_file[4:][:3]
    for i in range(N0):
        f1 = lines[i].rstrip()
        if f1[:3]=="id," and (i<N0-1):
            team = lines[i+2][-4:].rstrip()
            date = f1[6:][:4]+"-"+f1[6:][4:6]+"-"+f1[6:][6:8]+"-"+f1[6:][8:9]
            team_and_date = team_and_date + team +"-"+ ht_name +"-"+ date +","
            #vt_list = vt_list + [(i, lines[i+2][-4:])]
            #id_list = id_list + [(i, f1[6:])]
            #print((i, lines[i+2][-4:]), (i, f1[6:]))
    f.close()
    g.close()
    return team_and_date


def list_last_inning_team_season(season = 2022, team="BAL", post_season = False):
    """
    Returns the list of dates of games and the last inning number (usually 8.5 or 9),
    and the number of plays in the game.

    ###########

    EXAMPLES:
        sage: list_last_inning_team_season(season = 2022, team="BAL", post_season = False)
         ('2022-04-12-0', 'MIL', '9', 118),
          ('2022-04-13-0', 'MIL', '9', 103),
          ('2022-04-15-0', 'NYA', '9', 97),
          ('2022-04-16-0', 'NYA', '9', 97),
          ('2022-04-17-0', 'NYA', '9', 108),
          ('2022-04-29-0', 'BOS', '9', 100),
	   ...
          ('2022-05-18-0', 'NYA', '9', 76),
          ('2022-05-19-0', 'NYA', '9', 125),
          ('2022-05-20-0', 'TBA', '13', 170),
          ('2022-05-21-0', 'TBA', '9', 82),
          ('2022-05-22-0', 'TBA', '11', 173),
          ('2022-05-31-0', 'SEA', '9', 109),
          ('2022-06-01-0', 'SEA', '9', 93),
	  ///


    """
    if team in ["SFN","PHI", "NYN","SDN","MIL","LAN","COL"]:
        master_file = str(season)+team+".EVN"
    else:
        master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    f = open(master_file0,"r")
    lines = f.readlines()
    N0 = len(lines)
    #print(N0)
    inning_enders0 = []
    inning_enders = []
    game_dates = []
    vt_names = []
    #team_and_date = ""
    #ht_name = master_file[4:][:3]
    for i in range(1,N0):
        line_start = 0 
        line_end = 0
        number_plays_in_game = -1
        f1 = lines[i].rstrip()
        if f1[:3]=="id,":
            #line_start = 1000 
            #line_end = 2000
            #number_plays_in_game = -1
            date = f1[6:][:4]+"-"+f1[6:][4:6]+"-"+f1[6:][6:8]+"-"+f1[6:][8:9]
            game_dates = game_dates + [date]
            vt_names = vt_names + [strip_list_last_char(lines[i+2][-5:])]
            inning_enders0 = []
            for j in range(i,N0):
                f2 = lines[j].rstrip()
                f3 = lines[j-1].rstrip()
                if f2[:4]=="play" and f3[:5]=="start":
                    line_start = j
                    #print(f2,f3,line_start)
                if f2[:4]=="data" and f3[:4]=="play":
                    inning_enders0 = inning_enders0 + [f3.split(",")[1]]
                    line_end = j
                    break
                    #print(f1,line_end)
            number_plays_in_game = line_end - line_start
            #print(i,j)
            inning_enders = inning_enders + [(inning_enders0[0], number_plays_in_game)]
    f.close()
    N1a = len(game_dates)
    N1b = len(vt_names)
    N2 = len(inning_enders)
    #print(N0,N1a,N1b,N2)
    ans = [(game_dates[j], vt_names[j], inning_enders[j][0], inning_enders[j][1]) for j in range(N2)]
    return ans
    

def save_game_event_log(game_outfile, master_file = "2023BAL.EVA", play_date = "202304080", post_season = False):
    """
    Returns the file of the game in game_outfile. saved to the directory retrosheet_directory. 
    The game must occur on play_date and the game must occur in the retrosheet event file, master_file.
    For post-season games, set post_season = True.
 

    EXAMPLES:
        sage: game_outfile = "game-file-NYY-BAL_2023-04-08.txt"
        sage: master_file = "2023BAL.EVA"
        sage: play_date = "202304080"
        sage: save_game_event_log(game_outfile, master_file, play_date)
         'Finished writing BAL to file game-file_NYY-BAL_2023-04-08.txt'

    """
    #if team in ["SFN","PHI", "NYN","SDN","MIL","LAN","COL"]:
    #    master_file = str(season)+team+".EVN"
    #else:
    #    master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    f = open(master_file0,"r")
    game_outfile0 = retrosheet_directory + game_outfile
    g = open(game_outfile0,"a")
    lines = f.readlines()
    N0 = len(lines)
    i0 = 0; j0 = 0 ## initialize
    #print(N0)
    id_list = []
    team_name = master_file[4:][:3]
    for i in range(N0):
        f1 = lines[i].rstrip()
        if f1[:3]=="id,":
            id_list = id_list + [(i, f1[6:])]
            #print(i)
    M0 = len(id_list)
    for i in range(M0):
        x = id_list[i]
        if i < M0 - 1:
            y = id_list[i+1]
        else:
            y = [N0, ""]
        #print(i,x[0],x[1],play_date)
        if x[1]==play_date:
            i0 = x[0]
            j0 = y[0]
            #print(x)
    for i in range(i0, j0):
        f1 = lines[i].rstrip()
        #print(i, f1)
        g.write(f1+"\n")
    f.close()
    g.close()
    return "Finished writing {} to file {}".format(team_name, game_outfile)


def how_many_calls_with_playerID_atbat(plyrid, games_file, play_call = "E", verbose=False):
    """
    Returns a pair of integers -  
    * the number of plays with plyrid at bat where the call 
    play_call was made taken from the retrosheet event 
    file games_file (the *.EVA or *.EVN filename, as a string), and 
    * the total number of at-bats for plyrid (in the event file).
    Here
    plyrid = the retrosheet bio ID string
    play_call = string taken from 
         ["E", "K", "WP", "HP", "WnotWP", "DI", "GDP", "DP", "DPnotGDP", "DGR"] 
    If verbose = True the the play(s) themselves are listed

    EXAMPLES:
        sage: plyrid = "mullc002"
        sage: games_file = "2019BAL.EVA" 
        sage: play_call = "E"
        sage: how_many_calls_with_playerID_atbat(plyrid, games_file, play_call, verbose=True)
         The list of plays is:  ['play,2,1,mullc002,11,BCX,T9/G.2-H;1-H;B-H(E4/TH)(NR)\n']
          (1, 46)
        sage: plyrid = "mullc002"
        ....: games_file = "2021BAL.EVA"
        ....: play_call = "HP"
        ....: how_many_calls_with_playerID_atbat(plyrid, games_file, play_call, verbose=True)
         The list of plays is:  ['play,4,1,mullc002,22,FCB.FFFFF*BH,HP\n', 'play,7,1,mullc002,12,.BCCH,HP\n', 
          'play,9,1,mullc002,00,.H,HP\n', 'play,5,1,mullc002,22,.SCB*BH,HP.2-3;1-2\n']
          (4, 489)


    """
    gfile = retrosheet_directory + games_file
    f = open(gfile, "r")
    lines = f.readlines()
    N0 = len(lines)
    countp = 0
    countr = 0
    L = []
    for i in range(N0):
        line = lines[i]
        if plyrid in line:
            countp = countp + 1
            if play_call == "DPnotGDP":
                    if ("DP" in line) and not("GDP" in line):
                        countr = countr + 1
                        if verbose:
                            L = L + [line]
            if play_call == "WnotWP":
                    if ("W" in line) and not("WP" in line):
                        countr = countr + 1
                        if verbose:
                            L = L + [line]
            if play_call in line:
                countr = countr + 1
                if verbose:
                    L = L + [line]
    if not(verbose):
        return countr
    else:
        #print("The total at-bats for " + retrosheet_playerID(plyrid) + " is: ", countp)
        print("The list of plays is: ", L)
        return countr, countp


def batter_during_call_list(games_file, play_call = "E"):
    """
    Returns the list of 
    1) batters (in chronological order) for which play_call 
    occurred during their time at bat, taken from games_file,
    2) the play in which it occurred (in retrosheet notation),
    3) the visiting team name,
    4) the date of the game (and name of home team), derived from 
    the associated id record (also in retrosheet notation).
    Here
    games_file = retrosheet event file with *.EVA or *.EVN filename, as a string 
    play_call = string taken from 
         ["E", "K", "WP", "HP", "WnotWP", "DI", "GDP", "DP", "DPnotGDP", "DGR"] 

    Does not capture the play_call if it's in the opening play of the game.

    #####  Add to the output the date of the game 
    #####  (use that to return the state and the state transition) ...
    ## 1) construct list L0 of all line numbers for the game date (the game id record)
    ## 2) from the play containing the string <play_call>, find the line number, n1
    ## 3) locate the largest line number n0 in L0 less than n1.
    ## 4) return the date from the id record on line n0.
    ## 5) from date, run event_file_to_game_states(ht_game_on_date)
    ## 6) for each play except the lead-off play: 
    ##    * extract game state for the play on that date, 
    ##    * extract the game state for previous play,
    ##    * return this pair as a state transition.
    ## 7) Analyze stats for this.

    EXAMPLES:
        sage: games_file = "2019BAL.EVA" 
        sage: LL = batter_during_call_list(games_file, play_call = "E")
        sage: LL.sort()
        sage: LL[:10]
         [('andre001',
          'play,3,0,andre001,00,X,S8/L89D+.2-H;B-2(E8)',
          ('CHA', 'BAL202308300'),
          ((2, 0, 1, 0, 3, 6, 4, 0), (2, 0, 1, 0, 3, 7, 4, 0))),
         ('arozr001',
          'play,6,0,arozr001,22,BCBCX,E5/G5.B-1',
          ('TBA', 'BAL202309160'),
          ((2, 0, 0, 0, 6, 0, 8, 0), (2, 1, 0, 0, 6, 0, 8, 0))),
         ('bemba001',
          'play,5,1,bemba001,01,1FX,S4/F9LS.1-H(E4)(NR)(UR);B-2',
          ('SEA', 'BAL202306250'),
          ((1, 1, 0, 0, 5, 2, 2, 1), (1, 0, 1, 0, 5, 2, 3, 1))),
         ('bettm001',
          'play,7,0,bettm001,00,.>B,SB3;SB2.2-H(E2/TH)(NR);1-3',
          ('LAN', 'BAL202307180'),
          ((0, 1, 1, 0, 7, 5, 1, 0), (0, 0, 0, 1, 7, 6, 1, 0))),
         ('castr006',
          'play,8,0,castr006,11,..BS.X,E5/TH/G5.B-1',
          ('PIT', 'BAL202305140'),
          ((0, 0, 0, 0, 8, 4, 0, 0), (0, 1, 0, 0, 8, 4, 0, 0))),
         ('dever001',
          'play,3,0,dever001,10,B>B,SB3;SB2.2-H(E2/TH)(NR);1-3',
          ('BOS', 'BAL202310010'),
          ((1, 1, 1, 0, 3, 0, 0, 0), (1, 0, 0, 1, 3, 1, 0, 0))),
         ('dever001',
          'play,3,0,dever001,20,B>B.X,E6/G6.3-H(UR);B-1',
          ('BOS', 'BAL202310010'),
          ((1, 0, 0, 1, 3, 1, 0, 0), (1, 1, 0, 0, 3, 2, 0, 0))),
         ('dever001',
          'play,9,0,dever001,12,FFFB>B,SB2.1-3(E2/TH)',
          ('BOS', 'BAL202309290'),
          ((0, 1, 0, 0, 9, 2, 0, 0), (0, 0, 0, 1, 9, 2, 0, 0))),
         ('franw002',
          'play,4,0,franw002,12,FCBX,E3/G3.B-1',
          ('TBA', 'BAL202305090'),
          ((0, 0, 0, 0, 4, 1, 3, 0), (0, 1, 0, 0, 4, 1, 3, 0))),
         ('fraza001',
          'play,2,1,fraza001,00,X,FC/SH/BG5S-.1-2;B-1(E5)',
          ('ANA', 'BAL202305170'),
          ((0, 1, 0, 1, 2, 0, 0, 1), (0, 1, 1, 1, 2, 0, 0, 1)))]

    """
    gfile = retrosheet_directory + games_file
    #print("bdcl", gfile)
    f = open(gfile, "r")
    lines = f.readlines()
    N0 = len(lines)
    countp = 0
    countr = 0
    L0 = []
    L = []
    for i in range(N0-1):  ### used to be range(N0-1). Why remove last index?
        line = lines[i]
        if ("id," in line) and (len(line)>0) and (line[0]=="i"):
            L0 = L0 + [(i,line,lines[i+2][-4:])]
    for i in range(N0-1):
        line = lines[i].rstrip()  ### used to be lines[i][:-1]. why remove last char?
        if play_call == "DPnotGDP":
            if ("DP" in line) and not("GDP" in line) and ("," in line):
                countr = countr + 1
                spl_rec = line.split(",")
                if ("play" in line) and not("replay" in line):
                    gdate = game_date_of_play(L0, i, line)[1]
                    vtname = game_date_of_play(L0, i, line)[0]
                    #print("bdcl2", gdate, vtname)
                    sts = states_on_before_play(gdate, vtname, line)
                    #print(sts)
                    L = L + [(spl_rec[3], line, game_date_of_play(L0, i, line), sts)]
        if play_call == "WnotWP":
            if ("W" in line) and not("WP" in line) and ("," in line):
                countr = countr + 1
                spl_rec = line.split(",")
                if ("play" == line[:4]) and not("replay" in line):
                    gdate = game_date_of_play(L0, i, line)[1]
                    vtname = game_date_of_play(L0, i, line)[0]
                    #print("bdcl3", gdate, vtname)
                    sts = states_on_before_play(gdate, vtname, line)
                    L = L + [(spl_rec[3], line, game_date_of_play(L0, i, line), sts)]
        if (play_call in line) and ("," in line):
            countr = countr + 1
            spl_rec = line.split(",")
            if ("play" == line[:4]) and not("replay" in line):
                gdate = game_date_of_play(L0, i, line)[1]
                vtname = game_date_of_play(L0, i, line)[0]
                sts = states_on_before_play(gdate, vtname, line)
                #print("bdcl4", "gdate", gdate, "vtname", vtname, "spl_rec", spl_rec, "sts", sts)
                L = L + [(spl_rec[3], line, game_date_of_play(L0, i, line), sts)]
    f.close()
    return L

def game_date_of_play(list_of_gameids, play_line_number, play_record):
    ## utility for above batter_during_call_list function.
    N1 = len(list_of_gameids)
    for j in range(1,N1):
        gamedate = list_of_gameids[j-1][1]
        vt_name = list_of_gameids[j-1][2]
        if list_of_gameids[j][0] > play_line_number: ## one of these must return True first
            #print("game_date_of_play", vt_name, (gamedate.split(","))[1])
            return vt_name.rstrip(), (gamedate.split(","))[1].rstrip()
    gamedate = list_of_gameids[-1][1]
    vt_name = list_of_gameids[-1][2]
    return vt_name.rstrip(), (gamedate.split(","))[1].rstrip()


def states_on_before_play(gdate, vtname, play_record):
    ## utility for above batter_during_call_list function.
    gdir = gdate[:3] + "-home_" + gdate[3:][:4] + "/"
    game_file = gdir + vtname + "-" + gdate[:3] + "-" + gdate[3:][:4] + "-" + gdate[3:][4:6] + "-" + gdate[3:][6:8] + "-" +  gdate[-1] + ".txt"
    #print("from bdcl->sobp", game_file)
    L1 = event_file_to_game_states(game_file)
    L10 = [x[0] for x in L1]
    L11 = [x[1] for x in L1]
    #print("states_on_before_play", L10, gdate, vtname, play_record)
    if not(play_record in L10):
        return play_record
    else:
        j = L10.index(play_record)
    if j > 0:
        return L11[j-1], L11[j]
    if (j == 0) and (play_record[7]=="0"):  ############################# if play is 1st play of game then there is no "prior state" ...
        return (0, 0, 0, 0, 1, 0, 0, 0), L11[j]
    if (j == 0) and (play_record[7]=="1"):  ############################# if play is 1st play of game then there is no "prior state" ...
        return (0, 0, 0, 0, 1, 0, 0, 1), L11[j]
    
def number_of_calls_per_batter(games_file, play_call = "E"):
    """
    Returns the number of play_call each batter in involved with, 
    taken from games_file.  Here
    games_file = retrosheet event file with *.EVA or *.EVN filename, as a string 
    play_call = string taken from 
         ["E", "K", "WP", "HP", "WnotWP", "DI", "GDP", "DP", "DPnotGDP", "DGR"] 

 

    EXAMPLES:
        sage: games_file = "2023BAL.EVA"
        sage: L = number_of_calls_per_batter(games_file, play_call = "DI"); L
        [(1, 'Langeliers, Shea')]
        sage: L = number_of_calls_per_batter(games_file, play_call = "HP"); L[-4:]
        [(2, 'Turner, Justin'),
         (3, 'Frazier, Adam'),
         (3, "O'Hearn, Ryan"),
         (4, 'Urias, Ramon')]
        sage: sage: games_file = "2022BAL.EVA"
        sage: L = number_of_calls_per_batter(games_file, play_call = "E"); L[-4:]
        [(6, 'Mancini, Trey'),
         (7, 'Mateo, Jorge'),
         (8, 'Hays, Austin'),
         (9, 'Mullins, Cedric')]


    """
    L = batter_during_call_list(games_file, play_call)
    N = [x[0] for x in L]
    #print(N)
    plyr_set = list(set(N))
    #print(plyr_set)
    M = []
    for nm in plyr_set:
        M = M + [(N.count(nm), retrosheet_playerID(nm))]
    M.sort()
    return M

def retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl2023.csv"):
    """
    Returns the list of all scores of the MLB teams, including team names and league (AL or NL),
    which team is visitor and which is home, and the number of half-innings (usually 18).

    EXAMPLES:
        sage: L = retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl2023.txt"); L[:15]
        [('20230330', 'MIL', 'NL', 'CHN', 'NL', 0, 4, 17),
         ('20230330', 'PIT', 'NL', 'CIN', 'NL', 5, 4, 18),
         ('20230330', 'ARI', 'NL', 'LAN', 'NL', 2, 8, 17),
         ('20230330', 'NYN', 'NL', 'MIA', 'NL', 5, 3, 18),
         ('20230330', 'COL', 'NL', 'SDN', 'NL', 7, 2, 18),
         ('20230330', 'TOR', 'AL', 'SLN', 'NL', 10, 9, 18),
         ('20230330', 'ATL', 'NL', 'WAS', 'NL', 7, 2, 18),
         ('20230330', 'BAL', 'AL', 'BOS', 'AL', 10, 9, 18),
         ('20230330', 'CHA', 'AL', 'HOU', 'AL', 3, 2, 18),
         ('20230330', 'MIN', 'AL', 'KCA', 'AL', 2, 0, 18),
         ('20230330', 'SFN', 'NL', 'NYA', 'AL', 0, 5, 17),
         ('20230330', 'ANA', 'AL', 'OAK', 'AL', 1, 2, 17),
         ('20230330', 'CLE', 'AL', 'SEA', 'AL', 0, 3, 17),
         ('20230330', 'DET', 'AL', 'TBA', 'AL', 0, 4, 17),
         ('20230330', 'PHI', 'NL', 'TEX', 'AL', 7, 11, 17)]


    """
    glf = retrosheet_directory + game_log_csv_file
    import csv
    f = open(glf, "r")
    lines = f.readlines()
    N0 = len(lines)
    L = []
    for i in range(N0):
        line = lines[i].split(",")
        rdate = strip_list_last_char(line[0])
        vteam = strip_list_last_char(line[3])
        vtleague = strip_list_last_char(line[4])
        hteam = strip_list_last_char(line[6])
        htleague = strip_list_last_char(line[7])
        vscore = ZZ(line[9])
        hscore = ZZ(line[10])
        half_innings = ZZ(line[11])/3	
        L = L + [(rdate, vteam, vtleague, hteam, htleague, vscore, hscore, half_innings)]
    f.close()
    return L

    
def scores_in_homegames(team = "BAL", season = 2022):
    """
    Returns the list of all (date, vt name, ht name, vs, hs)
    from the list of games in gamefiles.

    EXAMPLES:
        sage: gamefiles = ""
        #sage: scores_in_gamefiles(gamefiles, team = "ARI", season = 2023)
        sage: scores_in_homegames(team = "ARI", season = 2023)
        Done checking scores
        [('20230406', 'LAN', 'ARI', 5, 2),
         ('20230407', 'LAN', 'ARI', 3, 6),
         ('20230408', 'LAN', 'ARI', 8, 12),
         ('20230409', 'LAN', 'ARI', 6, 11),
         ('20230410', 'MIL', 'ARI', 0, 3),
         ('20230411', 'MIL', 'ARI', 7, 1),
         ('20230412', 'MIL', 'ARI', 3, 7),
         ('20230420', 'SDN', 'ARI', 7, 5),
         ('20230421', 'SDN', 'ARI', 0, 9),
         ('20230422', 'SDN', 'ARI', 5, 3),
         ('20230423', 'SDN', 'ARI', 7, 5),
         ('20230424', 'KCA', 'ARI', 4, 5),
         ('20230425', 'KCA', 'ARI', 5, 4),
         ('20230426', 'KCA', 'ARI', 0, 2),
         ('20230505', 'WAS', 'ARI', 1, 3),
         ('20230506', 'WAS', 'ARI', 7, 8),
         ('20230507', 'WAS', 'ARI', 9, 8),
         ('20230508', 'MIA', 'ARI', 2, 5),
         ('20230509', 'MIA', 'ARI', 6, 2),
         ('20230510', 'MIA', 'ARI', 5, 4),
         ('20230511', 'SFN', 'ARI', 6, 2),
         ('20230512', 'SFN', 'ARI', 5, 7),
         ('20230513', 'SFN', 'ARI', 2, 7),
         ('20230514', 'SFN', 'ARI', 1, 2),
         ('20230526', 'BOS', 'ARI', 7, 2),
         ('20230527', 'BOS', 'ARI', 2, 1),
         ('20230528', 'BOS', 'ARI', 2, 4),
         ('20230529', 'COL', 'ARI', 5, 7),
         ('20230530', 'COL', 'ARI', 1, 5),
         ('20230531', 'COL', 'ARI', 0, 6),
         ('20230601', 'COL', 'ARI', 4, 5),
         ('20230602', 'ATL', 'ARI', 2, 3),
         ('20230603', 'ATL', 'ARI', 5, 2),
         ('20230604', 'ATL', 'ARI', 8, 5),
         ('20230612', 'PHI', 'ARI', 8, 9),
         ('20230613', 'PHI', 'ARI', 15, 3),
         ('20230614', 'PHI', 'ARI', 4, 3),
         ('20230615', 'PHI', 'ARI', 5, 4),
         ('20230616', 'CLE', 'ARI', 1, 5),
         ('20230617', 'CLE', 'ARI', 3, 6),
         ('20230618', 'CLE', 'ARI', 12, 3),
         ('20230627', 'TBA', 'ARI', 4, 8),
         ('20230628', 'TBA', 'ARI', 3, 2),
         ('20230629', 'TBA', 'ARI', 6, 1),
         ('20230704', 'NYN', 'ARI', 8, 5),
         ('20230705', 'NYN', 'ARI', 2, 1),
         ('20230706', 'NYN', 'ARI', 9, 0),
         ('20230707', 'PIT', 'ARI', 3, 7),
         ('20230708', 'PIT', 'ARI', 2, 3),
         ('20230709', 'PIT', 'ARI', 4, 2),
         ('20230724', 'SLN', 'ARI', 10, 6),
         ('20230725', 'SLN', 'ARI', 2, 3),
         ('20230726', 'SLN', 'ARI', 11, 7),
         ('20230728', 'SEA', 'ARI', 5, 2),
         ('20230729', 'SEA', 'ARI', 3, 4),
         ('20230730', 'SEA', 'ARI', 4, 0),
         ('20230808', 'LAN', 'ARI', 5, 4),
         ('20230809', 'LAN', 'ARI', 2, 0),
         ('20230811', 'SDN', 'ARI', 10, 5),
         ('20230812', 'SDN', 'ARI', 0, 3),
         ('20230813', 'SDN', 'ARI', 4, 5),
         ('20230821', 'TEX', 'ARI', 3, 4),
         ('20230822', 'TEX', 'ARI', 3, 6),
         ('20230824', 'CIN', 'ARI', 2, 3),
         ('20230825', 'CIN', 'ARI', 8, 10),
         ('20230826', 'CIN', 'ARI', 8, 7),
         ('20230827', 'CIN', 'ARI', 2, 5),
         ('20230901', 'BAL', 'ARI', 2, 4),
         ('20230902', 'BAL', 'ARI', 7, 3),
         ('20230903', 'BAL', 'ARI', 8, 5),
         ('20230904', 'COL', 'ARI', 2, 4),
         ('20230905', 'COL', 'ARI', 3, 2),
         ('20230906', 'COL', 'ARI', 5, 12),
         ('20230915', 'CHN', 'ARI', 4, 6),
         ('20230916', 'CHN', 'ARI', 6, 7),
         ('20230917', 'CHN', 'ARI', 2, 6),
         ('20230919', 'SFN', 'ARI', 4, 8),
         ('20230920', 'SFN', 'ARI', 1, 7),
         ('20230929', 'HOU', 'ARI', 2, 1),
         ('20230930', 'HOU', 'ARI', 1, 0),
         ('20231001', 'HOU', 'ARI', 8, 1)]


    """
    L = retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl"+str(season)+".txt")  ## this txt file is a csv file
    L0 = sorted_filenames(retrosheet_directory + team + "-home_" + str(season) + "/", master_dir = team + "-home_" + str(season) + "/")
    ####### using above instead of <gamefiles> #########################
    L_data = []
    for f in L0:
        if not(".DS" in f):
            L1 = event_file_to_game_states(f)
            final_vt_score = L1[-1][1][-3]
            final_ht_score = L1[-1][1][-2]
            vt_name = f[14:][:3]
            ht_name = f[18:][:3]
            rdate = f[22:][:10]
            sdate = rdate.split("-")
            fdate = sdate[0] + sdate[1] + sdate[2]
            data = (fdate, vt_name, ht_name, final_vt_score, final_ht_score)
            L_data = L_data + [data]
            #if not(scores_match(data, L)):
            #    print("The scores don't match in game ",f)
    #print("Done checking scores")
    return L_data

def scores_in_gamefiles(gamefiles, team = "BAL", season = 2022):
    """
    ###########################################################################
    ######## warning: this file has hard-coded directories #########
    ###########################################################################
    Returns the list of all (date, vt name, ht name, vs, hs)
    from the list of games in gamefiles.

    EXAMPLES:
        sage: gamefiles = ""
        sage: scores_in_gamefiles(gamefiles, team = "ARI", season = 2023)
        Check for  ('20230406', 'LAN', 'NL', 'ARI', 'NL', 5, 2, 18)
        Check for  ('20230407', 'LAN', 'NL', 'ARI', 'NL', 3, 6, 17)
        Check for  ('20230408', 'LAN', 'NL', 'ARI', 'NL', 8, 12, 17)
        Check for  ('20230409', 'LAN', 'NL', 'ARI', 'NL', 6, 11, 17)
        Check for  ('20230410', 'MIL', 'NL', 'ARI', 'NL', 0, 3, 17)
        Check for  ('20230411', 'MIL', 'NL', 'ARI', 'NL', 7, 1, 18)
        Check for  ('20230412', 'MIL', 'NL', 'ARI', 'NL', 3, 7, 17)
        Check for  ('20230420', 'SDN', 'NL', 'ARI', 'NL', 7, 5, 18)
        Check for  ('20230421', 'SDN', 'NL', 'ARI', 'NL', 0, 9, 17)
        Check for  ('20230422', 'SDN', 'NL', 'ARI', 'NL', 5, 3, 18)
        Check for  ('20230423', 'SDN', 'NL', 'ARI', 'NL', 7, 5, 18)
        Check for  ('20230424', 'KCA', 'AL', 'ARI', 'NL', 4, 5, 17)
        Check for  ('20230425', 'KCA', 'AL', 'ARI', 'NL', 5, 4, 18)
        Check for  ('20230426', 'KCA', 'AL', 'ARI', 'NL', 0, 2, 17)
        Check for  ('20230505', 'WAS', 'NL', 'ARI', 'NL', 1, 3, 17)
        Check for  ('20230506', 'WAS', 'NL', 'ARI', 'NL', 7, 8, 52/3)
        Check for  ('20230507', 'WAS', 'NL', 'ARI', 'NL', 9, 8, 18)
        Check for  ('20230508', 'MIA', 'NL', 'ARI', 'NL', 2, 5, 17)
        Check for  ('20230509', 'MIA', 'NL', 'ARI', 'NL', 6, 2, 18)
        Check for  ('20230510', 'MIA', 'NL', 'ARI', 'NL', 5, 4, 18)
        Check for  ('20230511', 'SFN', 'NL', 'ARI', 'NL', 6, 2, 18)
        Check for  ('20230512', 'SFN', 'NL', 'ARI', 'NL', 5, 7, 17)
        Check for  ('20230513', 'SFN', 'NL', 'ARI', 'NL', 2, 7, 17)
        Check for  ('20230514', 'SFN', 'NL', 'ARI', 'NL', 1, 2, 17)
        Check for  ('20230526', 'BOS', 'AL', 'ARI', 'NL', 7, 2, 18)
        Check for  ('20230527', 'BOS', 'AL', 'ARI', 'NL', 2, 1, 18)
        Check for  ('20230528', 'BOS', 'AL', 'ARI', 'NL', 2, 4, 17)
        Check for  ('20230529', 'COL', 'NL', 'ARI', 'NL', 5, 7, 17)
        Check for  ('20230530', 'COL', 'NL', 'ARI', 'NL', 1, 5, 17)
        Check for  ('20230531', 'COL', 'NL', 'ARI', 'NL', 0, 6, 17)
        Check for  ('20230601', 'COL', 'NL', 'ARI', 'NL', 4, 5, 53/3)
        Check for  ('20230602', 'ATL', 'NL', 'ARI', 'NL', 2, 3, 17)
        Check for  ('20230603', 'ATL', 'NL', 'ARI', 'NL', 5, 2, 18)
        Check for  ('20230604', 'ATL', 'NL', 'ARI', 'NL', 8, 5, 18)
        Check for  ('20230612', 'PHI', 'NL', 'ARI', 'NL', 8, 9, 17)
        Check for  ('20230613', 'PHI', 'NL', 'ARI', 'NL', 15, 3, 18)
        Check for  ('20230614', 'PHI', 'NL', 'ARI', 'NL', 4, 3, 20)
        Check for  ('20230615', 'PHI', 'NL', 'ARI', 'NL', 5, 4, 18)
        Check for  ('20230616', 'CLE', 'AL', 'ARI', 'NL', 1, 5, 17)
        Check for  ('20230617', 'CLE', 'AL', 'ARI', 'NL', 3, 6, 17)
        Check for  ('20230618', 'CLE', 'AL', 'ARI', 'NL', 12, 3, 18)
        Check for  ('20230627', 'TBA', 'AL', 'ARI', 'NL', 4, 8, 17)
        Check for  ('20230628', 'TBA', 'AL', 'ARI', 'NL', 3, 2, 18)
        Check for  ('20230629', 'TBA', 'AL', 'ARI', 'NL', 6, 1, 18)
        Check for  ('20230704', 'NYN', 'NL', 'ARI', 'NL', 8, 5, 18)
        Check for  ('20230705', 'NYN', 'NL', 'ARI', 'NL', 2, 1, 18)
        Check for  ('20230706', 'NYN', 'NL', 'ARI', 'NL', 9, 0, 18)
        Check for  ('20230707', 'PIT', 'NL', 'ARI', 'NL', 3, 7, 17)
        Check for  ('20230708', 'PIT', 'NL', 'ARI', 'NL', 2, 3, 58/3)
        Check for  ('20230709', 'PIT', 'NL', 'ARI', 'NL', 4, 2, 18)
        Check for  ('20230724', 'SLN', 'NL', 'ARI', 'NL', 10, 6, 18)
        Check for  ('20230725', 'SLN', 'NL', 'ARI', 'NL', 1, 3, 17)
        Check for  ('20230726', 'SLN', 'NL', 'ARI', 'NL', 11, 7, 18)
        Check for  ('20230728', 'SEA', 'AL', 'ARI', 'NL', 5, 2, 18)
        Check for  ('20230729', 'SEA', 'AL', 'ARI', 'NL', 3, 4, 17)
        Check for  ('20230730', 'SEA', 'AL', 'ARI', 'NL', 4, 0, 18)
        Check for  ('20230808', 'LAN', 'NL', 'ARI', 'NL', 5, 4, 18)
        Check for  ('20230809', 'LAN', 'NL', 'ARI', 'NL', 2, 0, 18)
        Check for  ('20230811', 'SDN', 'NL', 'ARI', 'NL', 10, 5, 18)
        Check for  ('20230812', 'SDN', 'NL', 'ARI', 'NL', 0, 3, 17)
        Check for  ('20230813', 'SDN', 'NL', 'ARI', 'NL', 4, 5, 17)
        Check for  ('20230821', 'TEX', 'AL', 'ARI', 'NL', 3, 4, 65/3)
        Check for  ('20230822', 'TEX', 'AL', 'ARI', 'NL', 3, 6, 17)
        Check for  ('20230824', 'CIN', 'NL', 'ARI', 'NL', 2, 3, 17)
        Check for  ('20230825', 'CIN', 'NL', 'ARI', 'NL', 8, 10, 17)
        Check for  ('20230826', 'CIN', 'NL', 'ARI', 'NL', 8, 7, 22)
        Check for  ('20230827', 'CIN', 'NL', 'ARI', 'NL', 2, 5, 17)
        Check for  ('20230901', 'BAL', 'AL', 'ARI', 'NL', 2, 4, 17)
        Check for  ('20230902', 'BAL', 'AL', 'ARI', 'NL', 7, 3, 18)
        Check for  ('20230903', 'BAL', 'AL', 'ARI', 'NL', 8, 5, 18)
        Check for  ('20230904', 'COL', 'NL', 'ARI', 'NL', 2, 4, 17)
        Check for  ('20230905', 'COL', 'NL', 'ARI', 'NL', 3, 2, 18)
        Check for  ('20230906', 'COL', 'NL', 'ARI', 'NL', 5, 12, 17)
        Check for  ('20230915', 'CHN', 'NL', 'ARI', 'NL', 4, 6, 17)
        Check for  ('20230916', 'CHN', 'NL', 'ARI', 'NL', 6, 7, 77/3)
        Check for  ('20230917', 'CHN', 'NL', 'ARI', 'NL', 2, 6, 17)
        Check for  ('20230919', 'SFN', 'NL', 'ARI', 'NL', 4, 8, 17)
        Check for  ('20230920', 'SFN', 'NL', 'ARI', 'NL', 1, 7, 17)
        Check for  ('20230929', 'HOU', 'AL', 'ARI', 'NL', 2, 1, 18)
        Check for  ('20230930', 'HOU', 'AL', 'ARI', 'NL', 1, 0, 18)
        Check for  ('20231001', 'HOU', 'AL', 'ARI', 'NL', 8, 1, 18)
        'Done checking scores'

    """
    L = retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl"+str(season)+".txt")  ## this txt file is a csv file
    L0 = sorted_filenames(retrosheet_directory + team + "-home_" + str(season) + "/", master_dir = team + "-home_" + str(season) + "/")
    ####### using above instead of <gamefiles> #########################
    L_data = []
    for f in L0:
        if not(".DS" in f):
            L1 = event_file_to_game_states(f)
            final_vt_score = L1[-1][1][-3]
            final_ht_score = L1[-1][1][-2]
            vt_name = f[14:][:3]
            ht_name = f[18:][:3]
            rdate = f[22:][:10]
            sdate = rdate.split("-")
            fdate = sdate[0] + sdate[1] + sdate[2]
            data = (fdate, vt_name, ht_name, final_vt_score, final_ht_score)
            L_data = L_data + [data]
            if not(scores_match(data, L)):
                print("The scores don't match in game ",f)
    print("Done checking scores")
    return L_data

def scores_match(data, L):
    """
    L1 is a list of retrosheet plays and the associated game state,
    while L is the list of all game scores from a retrosheet gamelog.
    This function is called in scores_in_gamefiles(gamefiles).

    """
    fdate = data[0]
    vt_name = data[1]
    ht_name = data[2]          # often "BAL"
    final_vt_score = data[3]
    final_ht_score = data[4]
    for v in L:
        if (fdate == v[0]):
            vt_name1 = v[1]
            ht_name1 = v[3]
            final_score = (v[-3],v[-2])
        if (vt_name == v[1]) and (v[3]==ht_name) and (fdate == v[0]) and (final_ht_score == v[-2]):
            print("Check for ",v)
            return True
    print("no match for game ", data, " with scores in gamelog. Final score: ", final_score)
    return False

def innings_pitched_in_game(game_file, ptchr, verbose=False):
    """
    Returns the list of innings pitched. If verbose = True then it also returns the
    name of the reliever.
    
    OUTPUT: A triple (a,b,c) of numbers,
    where a<b and each a,b belongs to {1, 4/3, 5/3, 2, 7/3, ...},
                      if ptchr plays in game,
	  a = b = -1, if ptchr doesn't occur in game_file,
    and where c = 0 if ptchr is with the visiting team,
                = 1 if ptchr is with home team,
		= -1 if ptchr does not play in game.
    INPUT:
    * game_file - a file of a game (named as a string, while the file itself
                  is a series of records from a single game in Retrosheet 
                  event game notation) that should include ptchr as either
		  a start record or a sub record,
                  and the string name should be of the form
		            VVV-HHH-YYYY-MM-DD-G.txt
		  where VVV = visiting team name abbreviation,
		        HHH = home team name abbreviation,
			YYYY = season (year) game was played
			MM = month game was played,
			DD = date game was played
			G = 0 if only game of 1st game of double header,
			    1 if 2nd game of double header,
			    and so on.
    * ptchr = retrosheet player ID of pitcher

    The first example below shows that "Brito, Jhony" was the starting
    pitcher for the visiting team (NYA) and was relieved in the 6th inning.
    
    EXAMPLES:
        sage: game_file = "NYA-BAL-2023-04-08-0.txt"
        sage: ptchr = "britj003"
        sage: innings_pitched_in_game(game_file, ptchr)
         [1, 6, 0]
        sage: game_file = "NYA-BAL-2023-04-07-0.txt"
        sage: ptchr = "kremd001"
        sage: innings_pitched_in_game(game_file, ptchr)
         [1, 6, 1]
        sage: innings_pitched_in_game(game_file, ptchr, verbose=True)
         Starting pitcher kremd001 {Kremer, Dean} relieved by gilll001 (Gillaspie, Logan)
         [1, 6, 1]
        sage: game_file = "NYA-BAL-2023-04-07-0.txt"
        sage: ptchr = "gilll001"
        sage: innings_pitched_in_game(game_file, ptchr, verbose=True)
         Starting pitcher gilll001 {Gillaspie, Logan} relieved by could001 (Coulombe, Daniel)
         [6, 6, 1]


    """
    innings = [-1, -1, -1]
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    #L = event_file_to_game_states(game_dir+game_file)
    game_file0 = retrosheet_directory + game_dir + game_file
    #print("2",game_dir, game_file, game_file0)
    f = open(game_file0)
    lines = f.readlines()
    N0 = len(lines)
    ptchrID = retrosheet_playerID(ptchr, player_id_csv_file = "retrosheet_playerID_biofile.csv")
    for i in range(N0):
        line_i = lines[i]
        sline_i = line_i.split(",")
        if (ptchr in line_i) and ("start" in line_i):
            ## so ptchr is a starter
            innings[0] = 1 ## a = 1
            if (len(sline_i)>3) and (sline_i[3]=="0"): ## ptchr is visitor
                innings[2] = 0               
                #print("visitor "+ptchrID, innings[2], "i = ", i)
            if (len(sline_i)>3) and (sline_i[3]=="1"): ## ptchr on home teamr
                innings[2] = 1
                #print("home "+ptchrID, innings[2], "i = ", i)
            for j in range(i,N0):
                line_j = lines[j]
                sline_j = line_j.split(",")
                #if ("sub" in line_j):
                #    print(1, sline_j, "i = ", i, "j = ", j, lines[j-1], ("0" == sline_j[3]))
                if ("sub" in line_j) and (innings[2] == int(sline_j[3])) and (1 == int(sline_j[5])):
                    ####                         sline_j[3] is vt/ht,    sline_j[5] is field position
                    ## sub for pitcher
                    #print(2, line_j, j)
                    if ("play" in lines[j-1]) and not("replay" in lines[j-1]):
                        innings[1] = int(lines[j-1][5]) ## b = inning from play record
                        ####             lines[j-1][5] is inning number just before sub
                        #print(3, line_j, j, lines[j-1])
                        if verbose:
                            subptchr =  sline_j[1]
                            subptchrID = retrosheet_playerID(subptchr, player_id_csv_file = "retrosheet_playerID_biofile.csv")
                            print("Starting pitcher "+ptchr + " {" + ptchrID +"} relieved by " + subptchr + " (" + subptchrID + ")")
                        return innings
        #print(ptchr, ptchrID, (ptchr in line_i), ("sub" in line_i), i)
        if (ptchr in line_i) and ("sub" in line_i):
            ## so ptchr is a reliever
            #print("reliever "+ptchrID, innings[2], "i = ", i)
            if (len(sline_i)>3) and (int(sline_i[3]) == 0): ## ptchr is visitor
                innings[2] = 0               
                #print("visitor "+ptchrID, innings[2], "i = ", i)
            if (len(sline_i)>3) and (int(sline_i[3]) == 1): ## ptchr on home teamr
                innings[2] = 1
                #print("home "+ptchrID, innings[2], "i = ", i, lines[i-1])
            if ("play" in lines[i-1]) and not("replay" in lines[i-1]):
                innings[0] = int(lines[i-1][5]) ## a = inning from play record
            for j in range(i+1,N0):
                line_j = lines[j]
                sline_j = line_j.split(",")
                if ("sub" in line_j) and (innings[2] == int(sline_j[3])) and (1 == int(sline_j[5])):
                    if ("play" in lines[j-1]) and not("replay" in lines[j-1]):
                        innings[1] = int(lines[j-1][5]) ## b = inning from play record
                        if verbose:
                            subptchr =  sline_j[1]
                            subptchrID = retrosheet_playerID(subptchr, player_id_csv_file = "retrosheet_playerID_biofile.csv")
                            print("Starting pitcher "+ptchr + " {" + ptchrID +"} relieved by " + subptchr + " (" + subptchrID + ")")
                        return innings
    f.close()
    return innings

def starting_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9,10], verbose=False):
    """
    Returns the list of retrosheet IDs of the *starting* players, on both teams, in the position pos_list.
    If verbose=True then it prints their names as well.
    
    OUTPUT: A pair of lists of retrosheet IDs. 

    INPUT:
    * game_file - a file of a game (named as a string, while the file itself
                  is a series of records from a single game in Retrosheet 
                  event game notation) that should include ptchr as either
		  a start record or a sub record,
                  and the string name should be of the form
		            VVV-HHH-YYYY-MM-DD-G.txt
		  where VVV = visiting team name abbreviation,
		        HHH = home team name abbreviation,
			YYYY = season (year) game was played
			MM = month game was played,
			DD = date game was played
			G = 0 if only game of 1st game of double header,
			    1 if 2nd game of double header,
			    and so on.
    * pos_list = list of integers taken from 1 (for the pitcher) to 9 (for the right fielder) and
                 even 10 (for the DH).
    
    EXAMPLES:
        sage: game_file = "NYA-BAL-2023-04-07-0.txt"
        sage: starting_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9,10], verbose=False)
        ([('lemad001', 5),
          ('judga001', 8),
          ('rizza001', 3),
          ('stanm004', 10),
          ('torrg001', 4),
          ('cabro002', 7),
          ('trevj001', 2),
          ('cordf003', 9),
          ('volpa001', 6),
          ('schmc002', 1)],
         [('mullc002', 8),
          ('rutsa001', 2),
          ('santa003', 9),
          ('mounr001', 3),
          ('hendg002', 10),
          ('uriar001', 5),
          ('fraza001', 4),
          ('haysa001', 7),
          ('matej003', 6),
          ('kremd001', 1)])
    sage: starting_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9,10], verbose=True)

     Visiting team roster:

     "DJ LeMahieu"            3rd baseman
     "Aaron Judge"            center fielder
     "Anthony Rizzo"          1st baseman
     "Giancarlo Stanton"      designated hitter
     "Gleyber Torres"         2nd baseman
     "Oswaldo Cabrera"        left fielder
     "Jose Trevino"           catcher
     "Franchy Cordero"        right fielder
     "Anthony Volpe"          shortstop
     "Clarke Schmidt"         pitcher

     Home team roster:

     "Cedric Mullins"         center fielder
     "Adley Rutschman"        catcher
     "Anthony Santander"      right fielder
     "Ryan Mountcastle"       1st baseman
     "Gunnar Henderson"       designated hitter
     "Ramon Urias"            3rd baseman
     "Adam Frazier"           2nd baseman
     "Austin Hays"            left fielder
     "Jorge Mateo"            shortstop
     "Dean Kremer"            pitcher

     ([('lemad001', 5),
       ('judga001', 8),
       ('rizza001', 3),
       ('stanm004', 10),
       ('torrg001', 4),
       ('cabro002', 7),
       ('trevj001', 2),
       ('cordf003', 9),
       ('volpa001', 6),
       ('schmc002', 1)],
      [('mullc002', 8),
       ('rutsa001', 2),
       ('santa003', 9),
       ('mounr001', 3),
       ('hendg002', 10),
       ('uriar001', 5),
       ('fraza001', 4),
       ('haysa001', 7),
       ('matej003', 6),
       ('kremd001', 1)])

    """
    roster_vt = []
    roster_ht = []
    roster_vt_name = []
    roster_ht_name = []
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    game_file0 = retrosheet_directory + game_dir + game_file
    f = open(game_file0)
    lines = f.readlines()
    N0 = len(lines)
    for i in range(N0):
        line_i = lines[i]
        sline_i = line_i.split(",")
        if "start" in sline_i:
            if (int(sline_i[3]) == 0) and (int(sline_i[5]) in pos_list): 
                roster_vt = roster_vt + [(sline_i[1], int(sline_i[5]))]
                roster_vt_name = roster_vt_name + [(sline_i[2], int(sline_i[5]))]
            if (int(sline_i[3]) == 1) and (int(sline_i[5]) in pos_list):
                roster_ht = roster_ht + [(sline_i[1], int(sline_i[5]))]
                roster_ht_name = roster_ht_name + [(sline_i[2], int(sline_i[5]))]
    if verbose:
        print("\n")
        print("Visiting team roster:\n")
        for x in roster_vt_name:
            if x[1] == 1:
                pos = "pitcher"
                print(f"{x[0]:<25}{pos}")
                #print(x[0] + " - pitcher")
            if x[1] == 2:
                pos = "catcher"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 3:
                pos = "1st baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 4:
                pos = "2nd baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 5:
                pos = "3rd baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 6:
                pos = "shortstop"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 7:
                pos = "left fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 8:
                pos = "center fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 9:
                pos = "right fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 10:
                pos = "designated hitter"
                print(f"{x[0]:<25}{pos}")
        print("\n")
        print("Home team roster:\n")
        for x in roster_ht_name:
            if x[1] == 1:
                pos = "pitcher"
                print(f"{x[0]:<25}{pos}")
                #print(x[0] + " - pitcher")
            if x[1] == 2:
                pos = "catcher"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 3:
                pos = "1st baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 4:
                pos = "2nd baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 5:
                pos = "3rd baseman"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 6:
                pos = "shortstop"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 7:
                pos = "left fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 8:
                pos = "center fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 9:
                pos = "right fielder"
                print(f"{x[0]:<25}{pos}")
            if x[1] == 10:
                pos = "designated hitter"
                print(f"{x[0]:<25}{pos}")
    print("\n")
    f.close()
    return roster_vt, roster_ht


def team_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9], verbose=False):
    """
    Returns the list of retrosheet IDs of *all* players, on both teams, in the position 
    pos_list. (A player can play more than one position, just not at the same time.)
    Note: DH (10) is *not* included.

    If verbose=True then it prints their names and latex tabular formatted in as well.
    
    OUTPUT: A pair of lists of retrosheet IDs. 

    INPUT:
    * game_file - a file of a game (named as a string, while the file itself
                  is a series of records from a single game in Retrosheet 
                  event game notation) that should include ptchr as either
		  a start record or a sub record,
                  and the string name should be of the form
		            VVV-HHH-YYYY-MM-DD-G.txt
		  where VVV = visiting team name abbreviation,
		        HHH = home team name abbreviation,
			YYYY = season (year) game was played
			MM = month game was played,
			DD = date game was played
			G = 0 if only game of 1st game of double header,
			    1 if 2nd game of double header,
			    and so on.
    * pos_list = list of integers taken from 1 (for the pitcher) to 9 (for the right fielder) 
                 but *not* 10 (for the DH).
    
    EXAMPLES:
        sage: game_file = "NYA-BAL-2023-04-07-0.txt"
        sage: team_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9], verbose=False)
         Visiting team, Home team rosters for game: NYA vs BAL on 2023-04-07
         ([(1, '1', 'schmc002'),
           (1, '4', 'hamii001'),
           (1, '6', 'marir001'),
           (1, '7', 'cordj001'),
           (1, '8', 'peraw002'),
           (2, '1', 'trevj001'),
           (3, '1', 'rizza001'),
           (4, '1', 'torrg001'),
           (5, '1', 'lemad001'),
           (6, '1', 'volpa001'),
           (7, '1', 'cabro002'),
           (8, '1', 'judga001'),
           (8, '6', 'kinei001'),
           (9, '1', 'cordf003'),
           (9, '6', 'judga001')],
          [(1, '1', 'kremd001'),
           (1, '6', 'could001'),
           (1, '6', 'gilll001'),
           (1, '7', 'perec004'),
           (1, '8', 'bakeb001'),
           (1, '9', 'bautf001'),
           (2, '1', 'rutsa001'),
           (3, '1', 'mounr001'),
           (4, '1', 'fraza001'),
           (5, '1', 'uriar001'),
           (6, '1', 'matej003'),
           (7, '1', 'haysa001'),
           (8, '1', 'mullc002'),
           (9, '1', 'santa003'),
           (9, '9', 'mcker001')])
        sage: team_rosters(game_file, pos_list = [0,1,2,3,4,5,6,7,8,9], verbose=True)
         Visiting team, Home team rosters for game: NYA vs BAL on 2023-04-07
         ([(1, '1', '"Clarke Schmidt"'),
           (1, '4', '"Ian Hamilton"'),
           (1, '6', '"Ron Marinaccio"'),
           (1, '7', '"Jimmy Cordero"'),
           (1, '8', '"Wandy Peralta"'),
           (2, '1', '"Jose Trevino"'),
           (3, '1', '"Anthony Rizzo"'),
           (4, '1', '"Gleyber Torres"'),
           (5, '1', '"DJ LeMahieu"'),
           (6, '1', '"Anthony Volpe"'),
           (7, '1', '"Oswaldo Cabrera"'),
           (8, '1', '"Aaron Judge"'),
           (8, '6', '"Isiah Kiner-Falefa"'),
           (9, '1', '"Franchy Cordero"'),
           (9, '6', '"Aaron Judge"')],
          [(1, '1', '"Dean Kremer"'),
           (1, '6', '"Danny Coulombe"'),
           (1, '6', '"Logan Gillaspie"'),
           (1, '7', '"Cionel Perez"'),
           (1, '8', '"Bryan Baker"'),
           (1, '9', '"Felix Bautista"'),
           (2, '1', '"Adley Rutschman"'),
           (3, '1', '"Ryan Mountcastle"'),
           (4, '1', '"Adam Frazier"'),
           (5, '1', '"Ramon Urias"'),
           (6, '1', '"Jorge Mateo"'),
           (7, '1', '"Austin Hays"'),
           (8, '1', '"Cedric Mullins"'),
           (9, '1', '"Anthony Santander"'),
           (9, '9', '"Ryan McKenna"')])

    """
    roster_vt = []
    roster_ht = []
    roster_vt_name = []
    roster_ht_name = []
    vt_name = game_file[:3]
    ht_name = game_file[4:7]
    game_date = game_file[8:18]
    game_data = "game: " + vt_name + " vs " + ht_name + " on " + game_date
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    game_file0 = retrosheet_directory + game_dir + game_file
    f = open(game_file0)
    lines = f.readlines()
    N0 = len(lines)
    for i in range(N0):
        line_i = lines[i]
        sline_i = line_i.split(",")
        if "start" in sline_i: ### starters only
            inning = "1"
            if (int(sline_i[3]) == 0) and (int(sline_i[5]) in pos_list):
                plyr_pair1 = [(int(sline_i[5]), inning, sline_i[1])]
                plyr_pair2 = [(int(sline_i[5]), inning, sline_i[2])]
                roster_vt = roster_vt + plyr_pair1
                roster_vt_name = roster_vt_name + plyr_pair2
            if (int(sline_i[3]) == 1) and (int(sline_i[5]) in pos_list):
                plyr_pair1 = [(int(sline_i[5]), inning, sline_i[1])]
                plyr_pair2 = [(int(sline_i[5]), inning, sline_i[2])]
                roster_ht = roster_ht + plyr_pair1
                roster_ht_name = roster_ht_name + plyr_pair2
        if "sub" in sline_i: ### non-starters only                   ###   to keep track of innings, use the preceding "play" record...
            line_im1 = lines[i-1]
            sline_im1 = line_im1.split(",")
            if ("play" in line_im1) and not("replay" in line_im1):
                inning = sline_im1[1]
            else:
                inning = "-1"
            if (int(sline_i[3]) == 0) and (int(sline_i[5]) in pos_list): 
                plyr_trpl1 = [(int(sline_i[5]), inning, sline_i[1])]
                plyr_trpl2 = [(int(sline_i[5]), inning, sline_i[2])]
                roster_vt = roster_vt + plyr_trpl1
                roster_vt_name = roster_vt_name + plyr_trpl2
            if (int(sline_i[3]) == 1) and (int(sline_i[5]) in pos_list):
                plyr_trpl1 = [(int(sline_i[5]), inning, sline_i[1])]
                plyr_trpl2 = [(int(sline_i[5]), inning, sline_i[2])]
                roster_ht = roster_ht + plyr_trpl1
                roster_ht_name = roster_ht_name + plyr_trpl2
    roster_vt.sort()
    roster_ht.sort()
    print("Visiting team, Home team rosters for " + game_data)
    if verbose:
        roster_vt_name.sort()
        roster_ht_name.sort()
        mn = min(len(roster_vt_name), len(roster_ht_name))
        mx = max(len(roster_vt_name), len(roster_ht_name))
        print("{\\small{ \\n")
        print("\\begin{tabular}{ccl|ccl} \\n")
        print("position & innings & player       & position & innings & player       \\ \\hline")
        for i in range(mn):
            vt_data = str(roster_vt_name[i][0]) + " & " + str(roster_vt_name[i][1]) + " & " + roster_vt_name[i][2] + " & " 
            ht_data = str(roster_ht_name[i][0]) + " & " + str(roster_ht_name[i][1]) + " & " + roster_ht_name[i][2] 
            print(vt_data+ht_data)
        for i in range(mn, mx):
            #print("unequal rosters ", len(roster_vt_name), len(roster_ht_name))
            if len(roster_vt_name)> len(roster_ht_name):
                vt_data = str(roster_vt_name[i][0]) + " & " + str(roster_vt_name[i][1]) + " & " + roster_vt_name[i][2] + " & " 
                ht_data = " " + " & " + " " + " & " + " " 
                print(vt_data+ht_data)
            if len(roster_vt_name)< len(roster_ht_name):
                ht_data = str(roster_ht_name[i][0]) + " & " + str(roster_ht_name[i][1]) + " & " + roster_ht_name[i][2] ## + " & " 
                vt_data = " " + " & " + " " + " &             & " + " " 
                print(vt_data+ht_data)
        print("\\end{tabular} \\n")
        print("}} \\n")
        return roster_vt_name, roster_ht_name
    return roster_vt, roster_ht


def errors_in_homegames(season = 2023, team = "BAL", verbose = False, verbose_tabular = False):
    """
    This function will parse the retrosheet game files
    for all homegames in <season> by <team> and extract:
    a) a triple (Err, ErrV, ErrH), where Err is the list of all errors, 
       ErrV is those due to a visiting fielder, 
       ErrH is those due to a fielder on the home team ("BAL" is the default),
    b) a pair of the errors by position, broken down into visiting
       team totals and home team totals.
    c) the state before the error and the state after the error,
    d) if verbose, identifies the player credited with the error,
       prints the number of runs resulting from the error,
    e) prints the retrosheet record for the play in which the error
       occurred (as a string),
    f) visiting team name,
    g) date of the game (and name of home team), derived from 
    the associated id record (also in retrosheet notation),
    h) if verbose, identifies the player credited with the error

    Example usage: For the Tigers 2019 regular season
       1) add subdirectory DET-home_2019 to events
       2) run 
          sage: frequency_transitions_team_season(season = 2019, team="DET", post_season = False, save_game_files = True)
          sage: Errors_DET_2019 = errors_in_homegames(season = 2019, team = "DET", verbose=True) 

    NOTE: In the very rare case of a play which results in two (or more) errors,
    the function also prints out the warning string "******** double error".

    #########3 Does verbose_tabular = True have a bug in extra innings (such as translating 6 into right field)?

    EXAMPLES:
        sage: Errors_BAL_2023 = errors_in_homegames(season = 2023, team = "BAL", verbose=True)
         play with error: play,2,1,haysa001,00,X,FC4/G34.3-H;1-2(E4);B-1
         during the game: NYA vs BAL on 20230407
         state before error:  (1, 1, 0, 1, 2, 0, 1, 1)
         error assigned to: 4 (2nd baseman on the visiting team)
          state after error:  (1, 1, 1, 0, 2, 0, 2, 1) 

         play with error: play,4,1,fraza001,11,1BF>B,SB2.1-3(E2/TH)
         during the game: NYA vs BAL on 20230408
         state before error:  (2, 1, 0, 0, 4, 1, 1, 1)
         error assigned to: 2 (catcher on the visiting team)
          state after error:  (2, 0, 0, 1, 4, 1, 1, 1) 
         
         <and so on, about 60 more times, then ...>
         Errors by vt:  30
         Runs by ht because of errors by vt:  11
         Errors by ht:  32
         Runs by vt because of errors by ht:  11
         Errors by position:    vt         ht
         errors due to pitcher:  4         1
                    to catcher:  5         8
                to 1st baseman:  2         2
                to 2nd baseman:  2         8
                to 3rd baseman:  4         5
                  to shortstop:  9         4
               to left fielder:  0         2
             to center fielder:  2         1
              to right fielder:  2         1

        sage: len(Errors_BAL_2023)    ## the function always returns a triple and a pair,
         5                            ## as described above
        sage: len(Errors_BAL_2023[0]) ## this is the total number of errors 
         62                           ## during a homegame that year
        sage: Errors_BAL_2023[0][0]                                 ## this component lists pairs: the play and
         ('play,2,1,haysa001,00,X,FC4/G34.3-H;1-2(E4);B-1',         ## the before and after states
          ((1, 1, 0, 1, 2, 0, 1, 1), (1, 1, 1, 0, 2, 0, 2, 1)))
        sage: len(Errors_BAL_2023[1])                               ## this component lists vt errors
         30
        sage: len(Errors_BAL_2023[2])                             ## this component lists ht errors
         32
        sage: len(Errors_BAL_2023[3])          ## there are 9 positions on the vt, one list of errors per position
         9
        sage: len(Errors_BAL_2023[4])          ## there are 9 positions on the ht, one list of errors per position
         9
        sage: Errors_BAL_2023[4][0]            ## the only ht error by a pitcher
         ['play,9,1,fraza001,10,B>S,CS2(E1/TH)']

    """
    errs = []
    vt_errs = []  ## errors by vt
    ht_errs = []  ## errors by ht
    vt_err_runs = 0  ## ht runs created by errors by vt
    ht_err_runs = 0  ## vt runs created by errors by ht
    errorsv1 = []  ## errors by vt pitcher
    errorsv2 = []  ## errors by vt catcher
    errorsv3 = []  ## errors by vt 1st baseman
    errorsv4 = []  ## errors by vt 2nd baseman
    errorsv5 = []  ## errors by vt 3rd baseman
    errorsv6 = []  ## errors by vt shortstop
    errorsv7 = []  ## errors by vt left fielder
    errorsv8 = []  ## errors by vt center fielder
    errorsv9 = []  ## errors by vt right fielder
    errorsh1 = []  ## errors by ht pitcher
    errorsh2 = []  ## errors by ht catcher
    errorsh3 = []  ## errors by ht 1st baseman
    errorsh4 = []  ## errors by ht 2nd baseman
    errorsh5 = []  ## errors by ht 3rd baseman
    errorsh6 = []  ## errors by ht shortstop
    errorsh7 = []  ## errors by ht left fielder
    errorsh8 = []  ## errors by ht center fielder
    errorsh9 = []  ## errors by ht right fielder
    post_season = False
    if team in NL_team_names:
        master_file = str(season)+team+".EVN"
    else:
        master_file = str(season)+team+".EVA"
    if not(post_season):
        master_file0 = retrosheet_directory+master_file
    else:
        master_file0 = retrosheet_directory+"postseason/"+master_file
    bdcl = batter_during_call_list(master_file, play_call = "E")
    #('andre001', 'play,3,0,andre001,00,X,S8/L89D+.2-H;B-2(E8)',
    # ('CHA', 'BAL202308300'), ((2, 0, 1, 0, 3, 6, 4, 0), (2, 0, 1, 0, 3, 7, 4, 0)))
    #errs = [(-1,"E-player",b[3],b[1],b[2]) for b in bdcl] 
    for ply in bdcl:
        if (len(ply)<4) or (len(ply)>4):
            print(ply,"errors_in_homegames")
        ply0 = ply[1]
        if "E" in ply0 and not("EV" in ply0):
            if ply0.count("E")>1:
                print(" ******** double error: " + ply0 + "\n ********")
            if verbose and not(verbose_tabular):
                Eind = ply0.index("E")
                print("{\\bf Play} with error:\\verb#  " + ply0 + " #")
                print("\\newline")
                print("during the game:\\verb#  " + ply[2][0] + " vs " + ply[2][1][:3] + " on " + ply[2][1][3:11] + " #")
                print("\\newline")
                print("state before error:\\verb#  ", ply[3][0], " #")
                print("\\newline")
                if ply0[7]=="1":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the visiting team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!visiting team"
                    ht_errs = ht_errs + [ply0]
                    #print("errors_in_homegames4", len(ply), len(ply[0]), len(ply[1]), len(ply[2])) ########################### bugs????
                    ht_err_runs = ht_err_runs + ZZ(ply[3][1][6]) - ZZ(ply[3][0][6]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsh1 = errorsh1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsh2 = errorsh2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsh3 = errorsh3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsh4 = errorsh4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsh5 = errorsh5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsh6 = errorsh6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsh7 = errorsh7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsh8 = errorsh8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsh9 = errorsh9 + [ply0]
                if ply0[7]=="0":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the home team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!home team"
                    vt_errs = vt_errs + [ply0]
                    vt_err_runs = vt_err_runs + int(ply[3][1][5]) - int(ply[3][0][5]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsv1 = errorsv1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsv2 = errorsv2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsv3 = errorsv3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsv4 = errorsv4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsv5 = errorsv5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsv6 = errorsv6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsv7 = errorsv7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsv8 = errorsv8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsv9 = errorsv9 + [ply0]
                print("error assigned to:\\verb#  " + ply0[Eind+1] + whoE, " #") ## ply0[Eind:Eind+2])
                print("\\index{" + posE + "}")
                print("\\newline")
                print("state after error:\\verb# ", ply[3][1]," #")
                print("\n")
                print("\\begin{analysis}")
                print("\n")
                print("\\end{analysis}")
                print("\n")
                #print("(Suggestion: Use <team_rosters> to find the roster of the team in that game.)")
            elif not(verbose) and verbose_tabular:
                Eind = ply0.index("E")
                print("\\begin{tabular}{r|l} \\hline")
                print("game  &  \\verb#  " + ply[2][0] + " vs " + ply[2][1][:3] + " on " + ply[2][1][3:11] + " # \\ \\ ")
                print("state before  &  \\verb# ", ply[3][0], " # \\ \\ ")
                print("error  &  \\verb#  " + ply0 + " # \\ \\ ")
                print("state after  &  \\verb# ", ply[3][1]," # \\ \\ ")
                if ply0[7]=="1":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the visiting team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!visiting team"
                    ht_errs = ht_errs + [ply0]
                    print("errors_in_homegames3", len(ply), len(ply[0]), len(ply[1]), len(ply[2])) ########################### bugs????
                    ht_err_runs = ht_err_runs + int(ply[3][1][6]) - int(ply[3][0][6]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsh1 = errorsh1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsh2 = errorsh2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsh3 = errorsh3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsh4 = errorsh4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsh5 = errorsh5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsh6 = errorsh6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsh7 = errorsh7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsh8 = errorsh8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsh9 = errorsh9 + [ply0]
                if ply0[7]=="0":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the home team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!home team"
                    vt_errs = vt_errs + [ply0]
                    vt_err_runs = vt_err_runs + int(ply[3][1][5]) - int(ply[3][0][5]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsv1 = errorsv1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsv2 = errorsv2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsv3 = errorsv3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsv4 = errorsv4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsv5 = errorsv5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsv6 = errorsv6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsv7 = errorsv7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsv8 = errorsv8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsv9 = errorsv9 + [ply0]
                print("fielder  &  \\verb#  " + ply0[Eind+1] + whoE, " # \\ \\ ") ## ply0[Eind:Eind+2])
                print("\\end{tabular}")
                print("\\index{" + posE + "}")
                if ",FC" in ply0:
                    print("\\index{fielder's choice}")
                print("\\vskip -0.2in  ")
                print("\\begin{analysis}")
                print("\n")
                print("\\end{analysis}")
                #print(ply[3][0][1], ply[3][0][2], ply[3][0][3])
                if (ZZ(ply[3][0][1])==0) and (ZZ(ply[3][0][2])==0) and (ZZ(ply[3][0][3])==0):
                    print("\\index{bases!empty}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==0) and (ply[3][0][3]==0):
                    print("\\index{runner!on 1st}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==1) and (ply[3][0][3]==0):
                    print("\\index{runner!on 2nd}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==0) and (ply[3][0][3]==1):
                    print("\\index{runner!on 3rd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==1) and (ply[3][0][3]==0):
                    print("\\index{runner!on 1st\\&2nd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==0) and (ply[3][0][3]==1):
                    print("\\index{runner!on 1st\\&3rd}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==1) and (ply[3][0][3]==1):
                    print("\\index{runner!on 2nd\\&3rd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==1) and (ply[3][0][3]==1):
                    print("\\index{bases!loaded}")
                print("\n")
                #print("(Suggestion: Use <team_rosters> to find the roster of the team in that game.)")
            elif verbose and verbose_tabular:
                Eind = ply0.index("E")
                print("\\begin{tabular}{r|l} \\hline")
                print("game  &  \\verb#  " + ply[2][0] + " vs " + ply[2][1][:3] + " on " + ply[2][1][3:11] + " # \\ \\ ")
                print("state before  &  \\verb# ", ply[3][0], " # \\ \\ ")
                print("error  &  \\verb#  " + ply0 + " # \\ \\ ")
                print("state after  &  \\verb# ", ply[3][1]," # \\ \\ ")
                if ply0[7]=="1":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the visiting team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!visiting team"
                    ht_errs = ht_errs + [ply0]
                    #if (len(ply[3])==2):
                    #print("errors_in_homegames2b", ply,len(ply[3])) ########################### bugs????
                    ht_err_runs = ht_err_runs + ZZ((ply[3][1])[6]) - int((ply[3][0])[6]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsh1 = errorsh1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsh2 = errorsh2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsh3 = errorsh3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsh4 = errorsh4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsh5 = errorsh5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsh6 = errorsh6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsh7 = errorsh7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsh8 = errorsh8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsh9 = errorsh9 + [ply0]
                if ply0[7]=="0":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the home team) "
                    posE = numeral_to_position(ply0[Eind+1]) + "!home team"
                    vt_errs = vt_errs + [ply0]
                    vt_err_runs = vt_err_runs + int(ply[3][1][5]) - int(ply[3][0][5]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsv1 = errorsv1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsv2 = errorsv2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsv3 = errorsv3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsv4 = errorsv4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsv5 = errorsv5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsv6 = errorsv6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsv7 = errorsv7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsv8 = errorsv8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsv9 = errorsv9 + [ply0]
                print("fielder  &  \\verb#  " + ply0[Eind+1] + whoE, " # \\ \\ ") ## ply0[Eind:Eind+2])
                print("\\end{tabular}")
                print("\\index{" + posE + "}")
                if ",FC" in ply0:
                    print("\\index{fielder's choice}")
                print("\\vskip -0.2in  ")
                print("\\begin{analysis}")
                print("\n")
                state_before = ply[3][0]
                state_after = ply[3][1]
                game_name = ply[2][0] + "-" + ply[2][1][:3] + "-" + ply[2][1][3:11] + "-0"
                play_record = ply0
                #print("verbose+verbose: ",play_record, state_before, state_after, game_name)
                summ = play_summary_generator(play_record, state_before, state_after, game_name)
                print(summ)
                print("\\end{analysis}")
                #print(ply[3][0][1], ply[3][0][2], ply[3][0][3])
                if (ZZ(ply[3][0][1])==0) and (ZZ(ply[3][0][2])==0) and (ZZ(ply[3][0][3])==0):
                    print("\\index{bases!empty}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==0) and (ply[3][0][3]==0):
                    print("\\index{runner!on 1st}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==1) and (ply[3][0][3]==0):
                    print("\\index{runner!on 2nd}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==0) and (ply[3][0][3]==1):
                    print("\\index{runner!on 3rd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==1) and (ply[3][0][3]==0):
                    print("\\index{runner!on 1st\\&2nd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==0) and (ply[3][0][3]==1):
                    print("\\index{runner!on 1st\\&3rd}")
                if (ply[3][0][1]==0) and (ply[3][0][2]==1) and (ply[3][0][3]==1):
                    print("\\index{runner!on 2nd\\&3rd}")
                if (ply[3][0][1]==1) and (ply[3][0][2]==1) and (ply[3][0][3]==1):
                    print("\\index{bases!loaded}")
                print("\n")
                #print("(Suggestion: Use <team_rosters> to find the roster of the team in that game.)")
            else:
                Eind = ply0.index("E")
                if ply0[7]=="0":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the visiting team) "
                    ht_errs = ht_errs + [ply0]
                    #print("errors_in_homegames1", len(ply), len(ply[0]), len(ply[1]), len(ply[2])) ########################### bugs????
                    ht_err_runs = ht_err_runs + int(ply[3][1][5]) - int(ply[3][0][5]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsh1 = errorsh1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsh2 = errorsh2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsh3 = errorsh3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsh4 = errorsh4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsh5 = errorsh5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsh6 = errorsh6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsh7 = errorsh7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsh8 = errorsh8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsh9 = errorsh9 + [ply0]
                if ply0[7]=="1":
                    whoE = " (" + numeral_to_position(ply0[Eind+1]) + " on the home team) "
                    vt_errs = vt_errs + [ply0]
                    vt_err_runs = vt_err_runs + int(ply[3][1][6]) - int(ply[3][0][6]) 
                    errs = errs + [(ply0, ply[3])]
                    if ply0[Eind+1] == "1":
                        errorsv1 = errorsv1 + [ply0]
                    if ply0[Eind+1] == "2":
                        errorsv2 = errorsv2 + [ply0]
                    if ply0[Eind+1] == "3":
                        errorsv3 = errorsv3 + [ply0]
                    if ply0[Eind+1] == "4":
                        errorsv4 = errorsv4 + [ply0]
                    if ply0[Eind+1] == "5":
                        errorsv5 = errorsv5 + [ply0]
                    if ply0[Eind+1] == "6":
                        errorsv6 = errorsv6 + [ply0]
                    if ply0[Eind+1] == "7":
                        errorsv7 = errorsv7 + [ply0]
                    if ply0[Eind+1] == "8":
                        errorsv8 = errorsv8 + [ply0]
                    if ply0[Eind+1] == "9":
                        errorsv9 = errorsv9 + [ply0]
    if verbose or verbose_tabular:
        print("Errors by vt: ", len(ht_errs))
        print("Runs by ht because of errors by vt: ", ht_err_runs)
        print("Errors by ht: ", len(vt_errs))
        print("Runs by vt because of errors by ht: ", vt_err_runs)
        print("Errors by position:    vt         ht")
        print("errors due to pitcher: ", len(errorsh1), "       ", len(errorsv1))
        print("           to catcher: ", len(errorsh2), "       ", len(errorsv2))
        print("       to 1st baseman: ", len(errorsh3), "       ", len(errorsv3))
        print("       to 2nd baseman: ", len(errorsh4), "       ", len(errorsv4))
        print("       to 3rd baseman: ", len(errorsh5), "       ", len(errorsv5))
        print("         to shortstop: ", len(errorsh6), "       ", len(errorsv6))
        print("      to left fielder: ", len(errorsh7), "       ", len(errorsv7))
        print("    to center fielder: ", len(errorsh8), "       ", len(errorsv8))
        print("     to right fielder: ", len(errorsh9), "       ", len(errorsv9))
    errorsv = [errorsv1, errorsv2, errorsv3, errorsv4, errorsv5, errorsv6, errorsv7, errorsv8, errorsv9]
    errorsh = [errorsh1, errorsh2, errorsh3, errorsh4, errorsh5, errorsh6, errorsh7, errorsh8, errorsh9]
    return errs, vt_errs, ht_errs, errorsv, errorsh
    
def runs_per_play_ht_all(season = 2023, team = "BAL", verbose = False):
    """
    Returns the number of runs by the ht = <team> divided by the number of plays while
    ht is at bat during a regular season game in the year <season>.

    EXAMPLES:
         sage: runs_per_play_ht_all(season = 2023, team = "NYN", verbose=True)
          Play-to-run conversion rate: 0.101
          ('runs per play by the NYN during the 2023 season: ', 175/1738)
         sage: runs_per_play_ht_all(season = 2021, team = "BAL", verbose=True)
          Play-to-run conversion rate: 0.104
          ('runs per play by the BAL during the 2021 season: ', 181/1738)
        sage: for tm in NL_team_names:
         ....:     print(tm, " percent of runs per play: ", RR10(runs_per_play_ht_all(season = 2023, team = tm)[-1]*100.0))
         ....: 
         ARI  percent of runs per play:  10.4
         ATL  percent of runs per play:  13.5
         CHN  percent of runs per play:  12.2
         CIN  percent of runs per play:  10.3
         COL  percent of runs per play:  11.7
         LAN  percent of runs per play:  12.1
         SDN  percent of runs per play:  10.4
         MIA  percent of runs per play:  10.3
         MIL  percent of runs per play:  10.8
         NYN  percent of runs per play:  10.1
         PHI  percent of runs per play:  11.7
         PIT  percent of runs per play:  9.69
         SFN  percent of runs per play:  9.19
         SLN  percent of runs per play:  10.4
         WAS  percent of runs per play:  10.1
sage: for tm in AL_team_names:
....:     print(tm, " percent of runs per play: ", RR10(runs_per_play_ht_all(season = 2023, team = tm)[-1]*100.0))
....: 
         ANA  percent of runs per play:  10.5
         BAL  percent of runs per play:  10.6
         BOS  percent of runs per play:  11.3
         CHA  percent of runs per play:  8.98
         CLE  percent of runs per play:  8.87
         DET  percent of runs per play:  9.40
         HOU  percent of runs per play:  10.5
         KCA  percent of runs per play:  10.9
         MIN  percent of runs per play:  11.1
         NYA  percent of runs per play:  9.85
         OAK  percent of runs per play:  7.77
         SEA  percent of runs per play:  10.4
         TBA  percent of runs per play:  12.1
         TEX  percent of runs per play:  13.4
         TOR  percent of runs per play:  9.85
        sage: AL0 = [(tm, RR10(runs_per_play_ht_all(season = 2023, team = tm)[-1]*100.0)) for tm in AL_team_names]
        sage: sum([x[-1] for x in AL0])/15   ## AL average 
         10.4
        sage: median([x[-1] for x in AL0])
         10.5
        sage: NL0 = [(tm, RR10(runs_per_play_ht_all(season = 2023, team = tm)[-1]*100.0)) for tm in NL_team_names]
        sage: sum([x[-1] for x in NL0])/15   ## NL average 
         10.9
        sage: median([x[-1] for x in NL0])
         10.4

    """
    score_team = 0
    ## read the gsl<season>.csv file
    L = retrosheet_game_scores(game_log_csv_file = "../gamelogs/gl" + str(season) +".txt")
    for x in L:
        if x[3] == team:
            score_team = score_team + x[-2]
    GSL_team_season = game_states_list(season, team,verbose=True)
    rpp = score_team/GSL_team_season[1]
    if verbose:
        print("Play-to-run conversion rate: " + str(RR10(rpp)))
    return "runs per play by the " + team + " during the " + str(season) + " season: ", rpp
    
def count_states_in_game_file(game_file, team = "home", verbose=False):
    """
    Returns the number of game states with/without error by <team> in <game_file>.
    Options are team = "home" and team = "visiting"

    If verbose=True then it prints the total number of at-bats for <team>
    in <game_file> and the frequencies (countabcd/total_atbat).

    EXAMPLES:
        sage: game_file = "SEA-BAL-2021-04-15-1.txt"
        sage: count_states_in_game_file(game_file, team = "home")
        Table of frequency of error-states for home is:
         [[(0, 0, 0, 0), 7],
          [(1, 0, 0, 0), 5],
          [(2, 0, 0, 0), 7],
          [(0, 1, 0, 0), 2],
          [(1, 1, 0, 0), 1],
          [(2, 1, 0, 0), 3],
          [(0, 0, 1, 0), 0],
          [(1, 0, 1, 0), 0],
          [(2, 0, 1, 0), 0],
          [(0, 0, 0, 1), 0],
          [(1, 0, 0, 1), 0],
          [(2, 0, 0, 1), 0],
          [(0, 1, 1, 0), 0],
          [(1, 1, 1, 0), 0],
          [(2, 1, 1, 0), 1]]
        sage: game_file = "SEA-BAL-2021-04-15-2.txt"
        sage: count_states_in_game_file(game_file, team = "home")
         Table of frequency of error-states for home is:
         [[(0, 0, 0, 0), 8],
          [(1, 0, 0, 0), 5],
          [(2, 0, 0, 0), 6],
          [(0, 1, 0, 0), 2],
          [(1, 1, 0, 0), 1],
          [(2, 1, 0, 0), 4],
          [(0, 0, 1, 0), 1],
          [(1, 0, 1, 0), 0],
          [(2, 0, 1, 0), 0],
          [(0, 0, 0, 1), 0],
          [(1, 0, 0, 1), 0],
          [(2, 0, 0, 1), 0],
          [(0, 1, 1, 0), 0],
          [(1, 1, 1, 0), 0],
          [(2, 1, 1, 0), 0]]
         sage: game_file = "NYA-BAL-2023-04-07-0.txt"
         sage: count_states_in_game_file(game_file, team = "home", verbose=True)

          The total number of *all* plays with home in this game is: 45

          Table of frequency of (most) error-states for home is:
          [[(0, 0, 0, 0), 8, 0.178],
           [(1, 0, 0, 0), 5, 0.111],
           [(2, 0, 0, 0), 3, 0.0667],
           [(0, 1, 0, 0), 3, 0.0667],
           [(1, 1, 0, 0), 3, 0.0667],
           [(2, 1, 0, 0), 3, 0.0667],
           [(0, 0, 1, 0), 1, 0.0222],
           [(1, 0, 1, 0), 6, 0.133],
           [(2, 0, 1, 0), 2, 0.0444],
           [(0, 0, 0, 1), 0, 0.000],
           [(1, 0, 0, 1), 1, 0.0222],
           [(2, 0, 0, 1), 3, 0.0667],
           [(0, 1, 1, 0), 0, 0.000],
           [(1, 1, 1, 0), 2, 0.0444],
           [(2, 1, 1, 0), 3, 0.0667]]

    """
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    #game_file0 = retrosheet_directory + game_dir + game_file
    game_file0 = game_dir + game_file
    #print(game_file, game_dir, game_file0)
    L = event_file_to_game_states(game_file0)
    count0000 = 0
    if team == "visiting":
        count0000 = 1    ###### program ignores 1st at-bat
    count1000 = 0
    count2000 = 0
    count0100 = 0
    count1100 = 0
    count2100 = 0
    count0010 = 0
    count1010 = 0
    count2010 = 0
    count0001 = 0
    count1001 = 0
    count2001 = 0
    count0110 = 0
    count1110 = 0
    count2110 = 0
    count0101 = 0
    count1101 = 0
    count2101 = 0
    count0011 = 0
    count1011 = 0
    count2011 = 0
    count0111 = 0
    count1111 = 0
    count2111 = 0
    T = []
    N0 = len(L)
    if team == "home":
        team_num = "1"
    else:
        team_num = "0"
    total_atbat = 0
    for i in range(1,N0):
        linei = L[i]
        lineim1 = L[i-1]
        if (linei[0][7] == team_num):
            total_atbat = total_atbat + 1
        #print(i, linei, 0, lineim1[0], 1, lineim1[1], ("(0, 0, 0, 0" in str(lineim1[1])), (linei[0][8] == team_num))
        if ("(0, 0, 0, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0000 = count0000 + 1
        if ("(1, 0, 0, 0" in str(lineim1[1])) and (linei[0][7]==team_num):
            count1000 = count1000 + 1
        if ("(2, 0, 0, 0" in str(lineim1[1])) and (linei[0][7]==team_num):
            count2000 = count2000 + 1
        if ("(0, 1, 0, 0" in str(lineim1[1])) and (linei[0][7]==team_num):
            count0100 = count0100 + 1
        if ("(1, 1, 0, 0" in str(lineim1[1])) and (linei[0][7]==team_num):
            count1100 = count1100 + 1
        if ("(2, 1, 0, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2100 = count2100 + 1
        if ("(0, 0, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0010 = count0010 + 1
        if ("(1, 0, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1010 = count1010 + 1
        if ("(2, 0, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2010 = count2010 + 1
        if ("(0, 0, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0001 = count0001 + 1
        if ("(1, 0, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1001 = count1001 + 1
        if ("(2, 0, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2001 = count2001 + 1
        if ("(0, 1, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0110 = count0110 +1
        if ("(1, 1, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1110 = count1110 + 1
        if ("(2, 1, 1, 0" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2110 = count2110 + 1
        if ("(0, 1, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0101 = count0101 +1
        if ("(1, 1, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1101 = count1101 + 1
        if ("(2, 1, 0, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2101 = count2101 + 1
        if ("(0, 0, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0011 = count0011 +1
        if ("(1, 0, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1011 = count1011 + 1
        if ("(2, 0, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2011 = count2011 + 1
        if ("(0, 1, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count0111 = count0111 +1
        if ("(1, 1, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count1111 = count1111 + 1
        if ("(2, 1, 1, 1" in str(lineim1[1])) and (linei[0][7] == team_num):
            count2111 = count2111 + 1
    if not(verbose):
        T = T + [[(0,0,0,0), count0000]]
        T = T + [[(1,0,0,0), count1000]]
        T = T + [[(2,0,0,0), count2000]]
        T = T + [[(0,1,0,0), count0100]]
        T = T + [[(1,1,0,0), count1100]]
        T = T + [[(2,1,0,0), count2100]]
        T = T + [[(0,0,1,0), count0010]]
        T = T + [[(1,0,1,0), count1010]]
        T = T + [[(2,0,1,0), count2010]]
        T = T + [[(0,0,0,1), count0001]]
        T = T + [[(1,0,0,1), count1001]]
        T = T + [[(2,0,0,1), count2001]]
        T = T + [[(0,1,1,0), count0110]]
        T = T + [[(1,1,1,0), count1110]]
        T = T + [[(2,1,1,0), count2110]]
        T = T + [[(0,1,1,1), count0111]]
        T = T + [[(1,1,1,1), count1111]]
        T = T + [[(2,1,1,1), count2111]]
    #print(linei, lineip3)
    if verbose:
        print("\n" + "The total number of *all* plays with " + team + " in this game is: " + str(total_atbat) + "\n")
        T = T + [[(0,0,0,0), count0000, RR10(count0000/total_atbat)]]
        T = T + [[(1,0,0,0), count1000, RR10(count1000/total_atbat)]]
        T = T + [[(2,0,0,0), count2000, RR10(count2000/total_atbat)]]
        T = T + [[(0,1,0,0), count0100, RR10(count0100/total_atbat)]]
        T = T + [[(1,1,0,0), count1100, RR10(count1100/total_atbat)]]
        T = T + [[(2,1,0,0), count2100, RR10(count2100/total_atbat)]]
        T = T + [[(0,0,1,0), count0010, RR10(count0010/total_atbat)]]
        T = T + [[(1,0,1,0), count1010, RR10(count1010/total_atbat)]]
        T = T + [[(2,0,1,0), count2010, RR10(count2010/total_atbat)]]
        T = T + [[(0,0,0,1), count0001, RR10(count0001/total_atbat)]]
        T = T + [[(1,0,0,1), count1001, RR10(count1001/total_atbat)]]
        T = T + [[(2,0,0,1), count2001, RR10(count2001/total_atbat)]]
        T = T + [[(0,1,1,0), count0110, RR10(count0110/total_atbat)]]
        T = T + [[(1,1,1,0), count1110, RR10(count1110/total_atbat)]]
        T = T + [[(2,1,1,0), count2110, RR10(count2110/total_atbat)]]
        T = T + [[(0,1,1,1), count0111, RR10(count0111/total_atbat)]]
        T = T + [[(1,1,1,1), count1111, RR10(count1111/total_atbat)]]
        T = T + [[(2,1,1,1), count2111, RR10(count2111/total_atbat)]]
    print("Table of frequency of (most) error-states for " + team + " is:")
    return T

def count_states_in_homegames(season = 2023, team = "BAL"):
    """
    Returns the number of game states with ht at bat with/without error by <team> in <season>.
  
    EXAMPLES:
        sage: count_states_in_homegames(season = 2023, team = "BAL")
         ([[(0, 0, 0, 0), 760],
          [(1, 0, 0, 0), 520],
          [(2, 0, 0, 0), 437],
          [(0, 1, 0, 0), 171],
          [(1, 1, 0, 0), 206],
          [(2, 1, 0, 0), 228],
          [(0, 0, 1, 0), 55],
          [(1, 0, 1, 0), 81],
          [(2, 0, 1, 0), 109],
          [(0, 0, 0, 1), 10],
          [(1, 0, 0, 1), 38],
          [(2, 0, 0, 1), 48],
          [(0, 1, 1, 0), 51],
          [(1, 1, 1, 0), 69],
          [(2, 1, 1, 0), 75],
          [(0, 1, 1, 1), 8],
          [(1, 1, 1, 1), 19],
          [(2, 1, 1, 1), 24]],
         3056)

    """
    team_num = 1
    gfs = list_of_homegame_filenames(season, team)
    game_file = gfs[0]
    game_dir = game_file[4:7] + "-home_" + game_file[8:12] + "/"
    #game_file0 = retrosheet_directory + game_dir + game_file
    count0000 = 0
    count1000 = 0
    count2000 = 0
    count0100 = 0
    count1100 = 0
    count2100 = 0
    count0010 = 0
    count1010 = 0
    count2010 = 0
    count0001 = 0
    count1001 = 0
    count2001 = 0
    count0110 = 0
    count1110 = 0
    count2110 = 0
    count0101 = 0
    count1101 = 0
    count2101 = 0
    count0011 = 0
    count1011 = 0
    count2011 = 0
    count0111 = 0
    count1111 = 0
    count2111 = 0
    total_atbat = 0
    T = []
    for gf in gfs:
        game_file0 = game_dir + gf
        #print(game_file, game_dir, game_file0)
        L = event_file_to_game_states(game_file0)
        N0 = len(L)
        for i in range(1,N0):
            linei = L[i]
            #lineim1 = L[i-1]
            if (linei[1][7] == team_num):
                total_atbat = total_atbat + 1
            #print(gf, i, linei, "00", linei[0], 1, linei[1], ("(0, 0, 0, 0" in str(linei[1])), linei[1][7], (linei[1][7] == team_num))
            if ("(0, 0, 0, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count0000 = count0000 + 1
            if ("(1, 0, 0, 0" in str(linei[1])) and (linei[1][7]==team_num):
                count1000 = count1000 + 1
            if ("(2, 0, 0, 0" in str(linei[1])) and (linei[1][7]==team_num):
                count2000 = count2000 + 1
            if ("(0, 1, 0, 0" in str(linei[1])) and (linei[1][7]==team_num):
                count0100 = count0100 + 1
            if ("(1, 1, 0, 0" in str(linei[1])) and (linei[1][7]==team_num):
                count1100 = count1100 + 1
            if ("(2, 1, 0, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count2100 = count2100 + 1
            if ("(0, 0, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count0010 = count0010 + 1
            if ("(1, 0, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count1010 = count1010 + 1
            if ("(2, 0, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count2010 = count2010 + 1
            if ("(0, 0, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count0001 = count0001 + 1
            if ("(1, 0, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count1001 = count1001 + 1
            if ("(2, 0, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count2001 = count2001 + 1
            if ("(0, 1, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count0110 = count0110 +1
            if ("(1, 1, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count1110 = count1110 + 1
            if ("(2, 1, 1, 0" in str(linei[1])) and (linei[1][7] == team_num):
                count2110 = count2110 + 1
            if ("(0, 1, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count0101 = count0101 +1
            if ("(1, 1, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count1101 = count1101 + 1
            if ("(2, 1, 0, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count2101 = count2101 + 1
            if ("(0, 0, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count0011 = count0011 +1
            if ("(1, 0, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count1011 = count1011 + 1
            if ("(2, 0, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count2011 = count2011 + 1
            if ("(0, 1, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count0111 = count0111 +1
            if ("(1, 1, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count1111 = count1111 + 1
            if ("(2, 1, 1, 1" in str(linei[1])) and (linei[1][7] == team_num):
                count2111 = count2111 + 1
    T = T + [[(0,0,0,0), count0000]]
    T = T + [[(1,0,0,0), count1000]]
    T = T + [[(2,0,0,0), count2000]]
    T = T + [[(0,1,0,0), count0100]]
    T = T + [[(1,1,0,0), count1100]]
    T = T + [[(2,1,0,0), count2100]]
    T = T + [[(0,0,1,0), count0010]]
    T = T + [[(1,0,1,0), count1010]]
    T = T + [[(2,0,1,0), count2010]]
    T = T + [[(0,0,0,1), count0001]]
    T = T + [[(1,0,0,1), count1001]]
    T = T + [[(2,0,0,1), count2001]]
    T = T + [[(0,1,1,0), count0110]]
    T = T + [[(1,1,1,0), count1110]]
    T = T + [[(2,1,1,0), count2110]]
    T = T + [[(0,1,1,1), count0111]]
    T = T + [[(1,1,1,1), count1111]]
    T = T + [[(2,1,1,1), count2111]]
    return T, total_atbat

def count_states_in_error_log(log_file, team = "home", verbose=False):
    """
    Returns the number of game states with error by <team> in <log_file>.
    Options are team = "home" and team = "visiting"
    
    EXAMPLES:
        sage: log_file = "errors-in-BAL-2023-homegames_sage-log3.txt"
        sage: count_states_in_error_log(log_file, team = "home")
         Total errors by home team:  31
         Table of frequency of error-states for home is:
         [[(0, 0, 0, 0), 6],
          [(1, 0, 0, 0), 3],
          [(2, 0, 0, 0), 4],
          [(0, 1, 0, 0), 2],
          [(1, 1, 0, 0), 2],
          [(2, 1, 0, 0), 2],
          [(0, 0, 1, 0), 0],
          [(1, 0, 1, 0), 0],
          [(2, 0, 1, 0), 3],
          [(0, 0, 0, 1), 0],
          [(1, 0, 0, 1), 2],
          [(2, 0, 0, 1), 0],
          [(0, 1, 1, 0), 2],
          [(1, 1, 1, 0), 1],
          [(2, 1, 1, 0), 0],
          [(0, 1, 1, 1), 0],
          [(1, 1, 1, 1), 0],
          [(2, 1, 1, 1), 0]]

    """
    count0000 = 0
    count1000 = 0
    count2000 = 0
    count0100 = 0
    count1100 = 0
    count2100 = 0
    count0010 = 0
    count1010 = 0
    count2010 = 0
    count0001 = 0
    count1001 = 0
    count2001 = 0
    count0110 = 0
    count1110 = 0
    count2110 = 0
    count0101 = 0
    count1101 = 0
    count2101 = 0
    count0011 = 0
    count1011 = 0
    count2011 = 0
    count0111 = 0
    count1111 = 0
    count2111 = 0
    count_error = 0
    T = []
    #log_dir = log_file[4:7] + "-home_" + log_file[8:12] + "/"
    log_file0 = retrosheet_directory[:-7] + log_file
    #print(retrosheet_directory[:-7], log_file0)
    f = open(log_file0)
    lines = f.readlines()
    N0 = len(lines)
    for i in range(N0-3):
        linei = lines[i]
        lineip3 = lines[i+3]
        if (team in lineip3) and ("fielder" in lineip3):
            #print(team, lineip3, (team in lineip3))
            count_error = count_error + 1
        if ("before" in linei) and ("(0, 0, 0, 0" in linei) and (team in lineip3):
            count0000 = count0000 + 1
        if ("before" in linei) and ("(1, 0, 0, 0" in linei) and (team in lineip3):
            count1000 = count1000 + 1
        if ("before" in linei) and ("(2, 0, 0, 0" in linei) and (team in lineip3):
            count2000 = count2000 + 1
        if ("before" in linei) and ("(0, 1, 0, 0" in linei) and (team in lineip3):
            count0100 = count0100 + 1
        if ("before" in linei) and ("(1, 1, 0, 0" in linei) and (team in lineip3):
            count1100 = count1100 + 1
        if ("before" in linei) and ("(2, 1, 0, 0" in linei) and (team in lineip3):
            count2100 = count2100 + 1
        if ("before" in linei) and ("(0, 0, 1, 0" in linei) and (team in lineip3):
            count0010 = count0010 + 1
        if ("before" in linei) and ("(1, 0, 1, 0" in linei) and (team in lineip3):
            count1010 = count1010 +1
        if ("before" in linei) and ("(2, 0, 1, 0" in linei) and (team in lineip3):
            count2010 = count2010 +1
        if ("before" in linei) and ("(0, 0, 0, 1" in linei) and (team in lineip3):
            count0001 = count0001 + 1
        if ("before" in linei) and ("(1, 0, 0, 1" in linei) and (team in lineip3):
            count1001 = count1001 + 1
        if ("before" in linei) and ("(2, 0, 0, 1" in linei) and (team in lineip3):
            count2001 = count2001 + 1
        if ("before" in linei) and ("(0, 1, 1, 0" in linei) and (team in lineip3):
            count0110 = count0110 +1
        if ("before" in linei) and ("(1, 1, 1, 0" in linei) and (team in lineip3):
            count1110 = count1110 + 1
        if ("before" in linei) and ("(2, 1, 1, 0" in linei) and (team in lineip3):
            count2110 = count2110 + 1
        if ("before" in linei) and ("(0, 1, 0, 1" in linei) and (team in lineip3):
            count0101 = count0101 +1
        if ("before" in linei) and ("(1, 1, 0, 1" in linei) and (team in lineip3):
            count1101 = count1101 + 1
        if ("before" in linei) and ("(2, 1, 0, 1" in linei) and (team in lineip3):
            count2101 = count2101 + 1
        if ("before" in linei) and ("(0, 0, 1, 1" in linei) and (team in lineip3):
            count0011 = count0011 +1
        if ("before" in linei) and ("(1, 0, 1, 1" in linei) and (team in lineip3):
            count1011 = count1011 + 1
        if ("before" in linei) and ("(2, 0, 1, 1" in linei) and (team in lineip3):
            count2011 = count2011 + 1
        if ("before" in linei) and ("(0, 1, 1, 1" in linei) and (team in lineip3):
            count0111 = count0111 +1
        if ("before" in linei) and ("(1, 1, 1, 1" in linei) and (team in lineip3):
            count1111 = count1111 + 1
        if ("before" in linei) and ("(2, 1, 1, 1" in linei) and (team in lineip3):
            count2111 = count2111 + 1
    if not(verbose):
        T = T + [[(0,0,0,0), count0000]]
        T = T + [[(1,0,0,0), count1000]]
        T = T + [[(2,0,0,0), count2000]]
        T = T + [[(0,1,0,0), count0100]]
        T = T + [[(1,1,0,0), count1100]]
        T = T + [[(2,1,0,0), count2100]]
        T = T + [[(0,0,1,0), count0010]]
        T = T + [[(1,0,1,0), count1010]]
        T = T + [[(2,0,1,0), count2010]]
        T = T + [[(0,0,0,1), count0001]]
        T = T + [[(1,0,0,1), count1001]]
        T = T + [[(2,0,0,1), count2001]]
        T = T + [[(0,1,1,0), count0110]]
        T = T + [[(1,1,1,0), count1110]]
        T = T + [[(2,1,1,0), count2110]]
        T = T + [[(0,1,0,1), count0101]]
        T = T + [[(1,1,0,1), count1101]]
        T = T + [[(2,1,0,1), count2101]]
        T = T + [[(0,0,1,1), count0011]]
        T = T + [[(1,0,1,1), count1011]]
        T = T + [[(2,0,1,1), count2011]]
        T = T + [[(0,1,1,1), count0111]]
        T = T + [[(1,1,1,1), count1111]]
        T = T + [[(2,1,1,1), count2111]]
    if verbose:
        print("Total errors by " + team + " team: ", count_error)
        T = T + [[(0,0,0,0), count0000, RR10(count0000/count_error)]]
        T = T + [[(1,0,0,0), count1000, RR10(count1000/count_error)]]
        T = T + [[(2,0,0,0), count2000, RR10(count2000/count_error)]]
        T = T + [[(0,1,0,0), count0100, RR10(count0100/count_error)]]
        T = T + [[(1,1,0,0), count1100, RR10(count1100/count_error)]]
        T = T + [[(2,1,0,0), count2100, RR10(count2100/count_error)]]
        T = T + [[(0,0,1,0), count0010, RR10(count0010/count_error)]]
        T = T + [[(1,0,1,0), count1010, RR10(count1010/count_error)]]
        T = T + [[(2,0,1,0), count2010, RR10(count2010/count_error)]]
        T = T + [[(0,0,0,1), count0001, RR10(count0001/count_error)]]
        T = T + [[(1,0,0,1), count1001, RR10(count1001/count_error)]]
        T = T + [[(2,0,0,1), count2001, RR10(count2001/count_error)]]
        T = T + [[(0,1,1,0), count0110, RR10(count0110/count_error)]]
        T = T + [[(1,1,1,0), count1110, RR10(count1110/count_error)]]
        T = T + [[(2,1,1,0), count2110, RR10(count2110/count_error)]]
        T = T + [[(0,1,0,1), count0101, RR10(count0101/count_error)]]
        T = T + [[(1,1,0,1), count1101, RR10(count1101/count_error)]]
        T = T + [[(2,1,0,1), count2101, RR10(count2101/count_error)]]
        T = T + [[(0,0,1,1), count0011, RR10(count0011/count_error)]]
        T = T + [[(1,0,1,1), count1011, RR10(count1011/count_error)]]
        T = T + [[(2,0,1,1), count2011, RR10(count2011/count_error)]]
        T = T + [[(0,1,1,1), count0111, RR10(count0111/count_error)]]
        T = T + [[(1,1,1,1), count1111, RR10(count1111/count_error)]]
        T = T + [[(2,1,1,1), count2111, RR10(count2111/count_error)]]
    f.close()
    print("Table of frequency of error-states for " + team + " is:")
    return T


def count_fielders_in_error_log(log_file, team = "home", fielder = 1, verbose=False):
    """
    Returns the number of game states with error assigned to <team> <fielder> in <log_file>.
    Options are 
       team = "home" and team = "visiting"
       fielder = 1, 2, ..., 9

    EXAMPLES:
        sage: log_file = "errors-in-BAL-2023-homegames_sage-log3.txt"
        sage: count_fielders_in_error_log(log_file, team = "home", fielder = 1, verbose=True)
         Total errors by home team:  24
         Table of frequency of error-fielder for home is:
         [['pitcher', 24, 1.00]]
        sage: count_fielders_in_error_log(log_file, team = "home", fielder = 1, verbose=False)
         Table of frequency of error-fielder for home is:
         [['pitcher', 24]]
        sage: count_fielders_in_error_log(log_file, team = "home", fielder = 2, verbose=False)
         Table of frequency of error-fielder for home is:
         [['catcher', 15]]
        sage: count_fielders_in_error_log(log_file, team = "visiting", fielder = 1, verbose=False)
         Table of frequency of error-fielder for visiting is:
         [['pitcher', 10]]

    """
    count1 = 0
    count2 = 0
    count3 = 0
    count4 = 0
    count5 = 0
    count6 = 0
    count7 = 0
    count8 = 0
    count9 = 0
    count_error = 0
    T = []
    #log_dir = log_file[4:7] + "-home_" + log_file[8:12] + "/"
    log_file0 = retrosheet_directory[:-7] + log_file
    #print(retrosheet_directory[:-7], log_file0)
    f = open(log_file0)
    lines = f.readlines()
    N0 = len(lines)
    for i in range(N0):
        linei = lines[i]
        if ("fielder  &" in linei) and (team in linei):
                count_error = count_error + 1
                print(i, linei)
        if ("fielder  &" in linei) and (team in linei) and ((str(fielder)+" (") in linei):
            if fielder == 1:
                count1 = count1 + 1
            if fielder == 2:
                count2 = count2 + 1
            if fielder == 3:
                count3 = count3 + 1
            if fielder == 4:
                count4 = count4 + 1
            if fielder == 5:
                count5 = count5 + 1
            if fielder == 6:
                count6 = count6 + 1
            if fielder == 7:
                count7 = count7 + 1
            if fielder == 8:
                count8 = count8 + 1
            if fielder == 9:
                count9 = count9 + 1
    if not(verbose):
        if fielder == 1:
            T = T + [["pitcher", count1]]
        if fielder == 2:
            T = T + [["catcher", count2]]
        if fielder == 3:
            T = T + [["first baseman", count3]]
        if fielder == 4:
            T = T + [["second baseman", count4]]
        if fielder == 5:
            T = T + [["third baseman", count5]]
        if fielder == 6:
            T = T + [["shortstop", count6]]
        if fielder == 7:
            T = T + [["left fielder", count7]]
        if fielder == 8:
            T = T + [["center fielder", count8]]
        if fielder == 9:
            T = T + [["right fielder", count9]]
    if verbose:
        print("Total errors by " + team + " team: ", count_error)
        if fielder == 1:
            T = T + [["pitcher", count1, RR10(count1/count_error)]]
        if fielder == 2:
            T = T + [["catcher", count2, RR10(count2/count_error)]]
        if fielder == 3:
            T = T + [["first baseman", count3, RR10(count3/count_error)]]
        if fielder == 4:
            T = T + [["second baseman", count4, RR10(count4/count_error)]]
        if fielder == 5:
            T = T + [["third baseman", count5, RR10(count5/count_error)]]
        if fielder == 6:
            T = T + [["shortstop", count6, RR10(count6/count_error)]]
        if fielder == 7:
            T = T + [["left fielder", count7, RR10(count7/count_error)]]
        if fielder == 8:
            T = T + [["center fielder", count8, RR10(count8/count_error)]]
        if fielder == 9:
            T = T + [["right fielder", count9, RR10(count9/count_error)]]
    f.close()
    print("Table of frequency of error-fielder for " + team + " is:")
    return T
    
############################################################################################################
####################################### Utilities ##########################################################
############################################################################################################

def numeral_to_position(pos):
    """
    Simply converts 0 to "pitcher", 1 to "catcher", etc.

    EXAMPLE:
        sage: numeral_to_position(2)
         'catcher'

    """
    n = int(pos) # in case pos is presented as a string
    if n == 10:
        return "designated hitter"
    if n == 1:
        return "pitcher"
    if n == 2:
        return "catcher"
    if n == 3:
        return "1st baseman"
    if n == 4:
        return "2nd baseman"
    if n == 5:
        return "3rd baseman"
    if n == 6:
        return "shortstop"
    if n == 7:
        return "left field"
    if n == 8:
        return "center field"
    if n == 9:
        return "right field"
  
def retrosheet_scoring_diagram_unrotated(print_title=True):
    """
    Returns the retrosheet scoring diagram, drawn as a square in the 1st quadrant.
    There are about 67 or 68 codes total, including the foul ball codes.
    
    EXAMPLES:
        sage: P = retrosheet_scoring_diagram_unrotated()
        sage: P.show(axes=False, dpi=300, title="Location Code Diagram")

    """
    x = var("x")
    import matplotlib.pyplot as plt
    plt.rc('font', size=5) 
    home_plate_text = text("H", (0,-20), rgbcolor=(0,0,1)) # home plate
    home_plate = polygon2d([[-7.5,-7.5], [-7.5,7.5], [7.5,7.5], [7.5,-7.5]], color = "red")
    pitchers_mound_text = text("P", (55, 40), rgbcolor=(0,0,1)) # pitcher's mound
    pitchers_mound = parametric_plot((42.4+10*cos(x), 42.4+10*sin(x)), (x, 0, 2*pi), color = "red")    
    plate1_text = text("1", (90,-20), rgbcolor=(0,0,1)) # 1st base
    plate1 = polygon2d([[-7.5+90,-7.5+0], [-7.5+90,7.5+0], [7.5+90,7.5+0], [7.5+90,-7.5+0]], color = "red")
    plate2_text = text("2", (105,95), rgbcolor=(0,0,1)) # 2nd base
    plate2 = polygon2d([[-7.5+90,-7.5+90], [-7.5+90,7.5+90], [7.5+90,7.5+90], [7.5+90,-7.5+90]], color = "red")
    plate3_text = text("3", (-20,95), rgbcolor=(0,0,1)) # 3rd base
    plate3 = polygon2d([[-7.5,-7.5+90], [-7.5,7.5+90], [7.5,7.5+90], [7.5,-7.5+90]], color = "red")
    base1_line = parametric_plot((x, 0), (x, 0, 325), color="black")
    base1_line_thick = parametric_plot((x, 0), (x, 0, 90), color="black", thickness=3)
    base12_line = parametric_plot((90,0+x), (x, 0, 90), color="black")
    base23_line = parametric_plot((x, 90), (x, 0, 90), color="black")
    base3_line = parametric_plot((0, x), (x, 0, 325), color="black")
    base3_line_thick = parametric_plot((0, x), (x, 0, 90), color="black", thickness = 3)
    rad1 = lambda x: 50
    rad0 = lambda x: 35
    rad3 = lambda x: 20
    rad2 = lambda x: 150 + 30*x*(pi/2 - x)
    infield2_arc = parametric_plot((rad3(x)*cos(x), rad3(x)*sin(x)), (x, pi/2, 2*pi), color="black", linestyle=":")
    infield0_arc = parametric_plot((rad0(x)*cos(x), rad0(x)*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    infield1_arc = parametric_plot((rad1(x)*cos(x), rad1(x)*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    outfield1_arc = parametric_plot((rad2(x)*cos(x), rad2(x)*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    outfield2_arc = parametric_plot((210*cos(x), 210*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    outfield3_arc = parametric_plot((260*cos(x), 260*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    outfield4_arc = parametric_plot((310*cos(x), 310*sin(x)), (x, 0, pi/2), color="black", linestyle=":")
    a = 1*11.25*pi/180
    outfield1_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 50, 335), color="black", linestyle="--")
    a = 2*11.25*pi/180
    outfield2_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 35, 360), color="black", linestyle="--")
    a = 3*11.25*pi/180
    outfield3_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 50, 410), color="black", linestyle="--")
    a = 4*11.25*pi/180
    outfield4_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 70, 210), color="black", linestyle="--")
    a = 5*11.25*pi/180
    outfield5_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 50, 410), color="black", linestyle="--")
    a = 6*11.25*pi/180
    outfield6_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 35, 360), color="black", linestyle="--")
    a = 7*11.25*pi/180
    outfield7_ray = parametric_plot((x*cos(a), x*sin(a)), (x, 50, 335), color="black", linestyle="--")
    V = SR^2
    lf_line = lambda x : x*V((0,325))+(1-x)*410*V((cos(5*11.25*pi/180), sin(5*11.25*pi/180)))
    leftfield_fence = parametric_plot(lf_line(x), (x, 0, 1), color="black", linestyle="-")
    rf_line = lambda x : x*V((325,0))+(1-x)*410*V((cos(3*11.25*pi/180), sin(3*11.25*pi/180)))
    rightfield_fence = parametric_plot(rf_line(x), (x, 0, 1), color="black", linestyle="-")
    cf_line = lambda x : x*410*V((cos(3*11.25*pi/180), sin(3*11.25*pi/180)))+(1-x)*410*V((cos(5*11.25*pi/180), sin(5*11.25*pi/180)))
    centerfield_fence = parametric_plot(cf_line(x), (x, 0, 1), color="black", linestyle="-")
    player1 = text("1", (42, 42), rgbcolor=(0,0,1)) # pitcher
    player2 = text("2", (15, 15), rgbcolor=(0,0,1)) # catcher
    player3 = text("3", (110, 10), rgbcolor=(0,0,1)) # 1st base
    player4 = text("4", (110, 60), rgbcolor=(0,0,1)) # 2nd base
    player5 = text("5", (10, 110), rgbcolor=(0,0,1)) # 3rd base
    player6 = text("6", (60, 110), rgbcolor=(0,0,1)) # shortstop
    player7 = text("7", (85, 270), rgbcolor=(0,0,1)) # left outfield
    player8 = text("8", (200, 200), rgbcolor=(0,0,1)) # center field
    player9 = text("9", (275, 85), rgbcolor=(0,0,1)) # right outfield
    position1S = text("1S", (30, 30), rgbcolor=(0,0,1), fontsize="x-small") # pitcher
    position2F = text("2F", (0, -15), rgbcolor=(0,0,1), fontsize="x-small") # catcher, foul
    position3S = text("3S", (70, 7), rgbcolor=(0,0,1), fontsize="xx-small") # 1st base
    position3SF = text("3SF", (70, -10), rgbcolor=(0,0,1), fontsize="x-small") # 1st base, foul
    position3F = text("3F", (110, -10), rgbcolor=(0,0,1), fontsize="x-small") # 1st base, foul
    position4S = text("4S", (75, 40), rgbcolor=(0,0,1), fontsize="xx-small") # 2nd base
    position5S = text("5S", (7, 70), rgbcolor=(0,0,1), fontsize="xx-small") # 3rd base
    position5SF = text("5SF", (-10, 70), rgbcolor=(0,0,1), fontsize="x-small") # 3rd base, foul
    position5F = text("5F", (-10, 110), rgbcolor=(0,0,1), fontsize="x-small") # 3rd base, foul
    position6S = text("6S", (40, 75), rgbcolor=(0,0,1), fontsize="xx-small") # short stop
    position7S = text("7S", (70, 225), rgbcolor=(0,0,1), fontsize="x-small") # left outfield
    position8S = text("8S", (170, 170), rgbcolor=(0,0,1), fontsize="x-small") # center outfield
    position9S = text("9S", (230, 70), rgbcolor=(0,0,1), fontsize="x-small") # right outfield
    position78 = text("78", (135, 255), rgbcolor=(0,0,1), fontsize="x-small") # lf-cf
    position89 = text("89", (255, 135), rgbcolor=(0,0,1), fontsize="x-small") # rf-cf
    position34 = text("34", (130, 35), rgbcolor=(0,0,1), fontsize="xx-small") # 1st-2nd base
    position56 = text("56", (35, 110), rgbcolor=(0,0,1), fontsize="x-small") # SS-3rd base
    position3D = text("3D", (180, 15), rgbcolor=(0,0,1), fontsize="xx-small") # 1st base
    position3DF = text("3DF", (180, -10), rgbcolor=(0,0,1), fontsize="x-small") # 1st base, deep foul
    position4D = text("4D", (165, 85), rgbcolor=(0,0,1), fontsize="x-small") # 2nd base
    position5D = text("5D", (15, 180), rgbcolor=(0,0,1), fontsize="xx-small") # 3rd base
    position5DF = text("5DF", (-10, 180), rgbcolor=(0,0,1), fontsize="x-small") # 3rd base, deep foul
    position6D = text("6D", (85, 165), rgbcolor=(0,0,1), fontsize="x-small") # short stop
    position7D = text("7D", (95, 315), rgbcolor=(0,0,1), fontsize="x-small") # left outfield
    position8D = text("8D", (235, 235), rgbcolor=(0,0,1), fontsize="x-small") # center outfield
    position8XD = text("8XD", (270, 270), rgbcolor=(0,0,1), fontsize="x-small") # center outfield
    position9D = text("9D", (315, 95), rgbcolor=(0,0,1), fontsize="x-small") # right outfield
    position13 = text("13", (55, 28), rgbcolor=(0,0,1), fontsize="xx-small") # pitcher
    position15 = text("15", (29, 55), rgbcolor=(0,0,1), fontsize="xx-small") # pitcher
    position23 = text("23", (42, 8), rgbcolor=(0,0,1), fontsize="xx-small") # catcher-1st base
    position23F = text("23F", (42, -10), rgbcolor=(0,0,1), fontsize="x-small") # catcher-1st base
    position25 = text("25", (8, 42), rgbcolor=(0,0,1), fontsize="xx-small") # catcher-3rd base
    position25F = text("25F", (-10, 42), rgbcolor=(0,0,1), fontsize="x-small") # catcher-3rd base, foul
    position34S = text("34S", (72, 20), rgbcolor=(0,0,1), fontsize="xx-small") # 1-2 base, short
    position34D = text("34D", (172, 50), rgbcolor=(0,0,1), fontsize="xx-small") # 1-2 base
    position56S = text("56S", (24, 79), rgbcolor=(0,0,1), fontsize="xx-small") # 3-SS base, short
    position56D = text("56D", (50, 172), rgbcolor=(0,0,1), fontsize="xx-small") # 3-SS base
    position78S = text("78S", (110, 210), rgbcolor=(0,0,1), fontsize="x-small") # lf-cf
    position78D = text("78D", (155, 300), rgbcolor=(0,0,1), fontsize="x-small") # lf-cf
    position89D = text("89D", (300, 155), rgbcolor=(0,0,1), fontsize="x-small") # rf-cf
    position89S = text("89S", (210, 110), rgbcolor=(0,0,1), fontsize="x-small") # rf-cf
    position7L = text("7L", (25, 280), rgbcolor=(0,0,1), fontsize="x-small") # lf near-fence
    position7LS = text("7LS", (20, 230), rgbcolor=(0,0,1), fontsize="x-small") # lf near-fence
    position7LF = text("7LF", (-10, 280), rgbcolor=(0,0,1), fontsize="x-small") # lf near-fence
    position7LSF = text("7LSF", (-10, 230), rgbcolor=(0,0,1), fontsize="x-small") # lf near-fence, foul
    position7LD = text("7LD", (30, 317), rgbcolor=(0,0,1), fontsize="xx-small") # left outfield
    position9L = text("9L", (280, 25), rgbcolor=(0,0,1), fontsize="x-small") # rf near-fence
    position9LF = text("9LF", (280, -10), rgbcolor=(0,0,1), fontsize="x-small") # rf near-fence
    position9LS = text("9LS", (230, 20), rgbcolor=(0,0,1), fontsize="x-small") # rf near-fence
    position9LSF = text("9LS", (230, -10), rgbcolor=(0,0,1), fontsize="x-small") # rf near-fence, foul
    position9LD = text("9LD", (317, 33), rgbcolor=(0,0,1), fontsize="xx-small") # rf near-fence
    position4M = text("4M", (110, 90), rgbcolor=(0,0,1), fontsize="x-small") # 2nd base, midfield
    position4MS = text("4MS", (77, 62), rgbcolor=(0,0,1), fontsize="xx-small") # 2nd base, midfield short
    position4MD = text("4MD", (142, 117), rgbcolor=(0,0,1), fontsize="xx-small") # 2nd base, midfield deep
    position6M = text("6M", (90, 110), rgbcolor=(0,0,1), fontsize="x-small") # SS, midfield
    position6MD = text("6MD", (117, 142), rgbcolor=(0,0,1), fontsize="xx-small") # SS, midfield deep
    position6MS = text("6MS", (63, 75), rgbcolor=(0,0,1), fontsize="xx-small") # SS, midfield short
    base_lines = base1_line + base1_line_thick + base12_line + base23_line + base3_line + base3_line_thick
    plates_only = home_plate + plate1 + plate2 + plate3 
    plates = plates_only + home_plate_text + plate1_text + plate2_text + plate3_text
    title0 = text("Location codes diagram", (120, -50), fontsize="small", fontweight="bold", color="black")
    title00 = text(" (used by retrosheet)", (120, -70), fontsize="x-small", color="black")
    title1 = text("Dimensions: about 325 ft down", (120, 450), fontsize="x-small", color="black")
    title2 = text(" the 1st and 3rd base lines, ", (120, 430), fontsize="x-small", color="black")
    title3 = text("and 400 ft to deep center.", (120, 410), fontsize="x-small", color="black")
    title4 = text("The usual 90 ft from home to 1st", (120, 390), fontsize="x-small", color="black")
    title5 = text("(or 3rd) base, and 60.5 ft to the pitcher.", (120, 370), fontsize="x-small", color="black")
    title = title00 +title0 +  title1 + title2 + title3 + title4+ title5
    arcs = infield0_arc + infield1_arc + infield2_arc + pitchers_mound + outfield1_arc + outfield2_arc + outfield3_arc + outfield4_arc
    rays = outfield1_ray + outfield2_ray + outfield3_ray + outfield4_ray + outfield5_ray + outfield6_ray + outfield7_ray
    fences = leftfield_fence + rightfield_fence + centerfield_fence
    players = player1 + player2 + player3 + player4 + player5 + player6 + player7 + player8 + player9
    positionsA = position1S + position3S + position4S + position5S + position6S + position7S + position8S + position9S
    positionsB = position13 + position15 + position23 + position25 + position34S + position34 + position34D + position56S + position56 + position56D + position78S + position78 + position78D + position89S + position89 + position89D
    positionsC = position3D + position4D + position5D + position6D + position7D + position8D  + position8XD + position9D
    positionsD = position9LS + position9L + position9LD + position7LS + position7L + position7LD + position4MS + position4M + position4MD + position6MS + position6M + position6MD
    if print_title:
        positions = positionsA + positionsB + positionsC + positionsD + title
    else:
        positions = positionsA + positionsB + positionsC + positionsD 
    fouls = position2F + position23F + position25F + position3SF + position3F + position3DF + position5SF + position5F + position5DF + position7LSF + position7LF + position9LSF + position9LF  
    #title_text = "About 400 ft to deep center and about 325 ft down 1st and 3rd base lines."
    title_text = ""
    return (base_lines+plates_only+arcs+rays+fences+players+positions+fouls)

def print_ascii_baseball_diamond():
    """
    Prints a simple baseball diamond, with the positions numbered as usual.

    EXAMPLE:
        sage: print_ascii_baseball_diamond()
          7           8
             6       
         5      4      
             1       9 
         2      3     
        'A small baseball diamond (ascii)'


    """
    pos = " 7           8\n     6       \n 5      4      \n     1       9 \n 2      3     "
    print(pos)
    return "A small baseball diamond (ascii)"


def plot_baseball_diamond(current_game_state = [0,0,0,0,1,0,0,0], print_title=True, game_state = False):
    """
    Prints a simple baseball diamond, with the positions numbered as usual.
    A game state is entered (the usual 8-tuple of integers) and
    the number of runners on base is returned as the function value. 

    EXAMPLE:
        sage: plot_baseball_diamond(current_game_state = [1,1,0,1,4,3,2,0])
    """
    P = retrosheet_scoring_diagram_unrotated(print_title)
    cgs = current_game_state
    plate1 = polygon2d([[-7.5+90,-7.5+0], [-7.5+90,7.5+0], [7.5+90,7.5+0], [7.5+90,-7.5+0]], color = "green")
    plate2 = polygon2d([[-7.5+90,-7.5+90], [-7.5+90,7.5+90], [7.5+90,7.5+90], [7.5+90,-7.5+90]], color = "green")
    plate3 = polygon2d([[-7.5,-7.5+90], [-7.5,7.5+90], [7.5,7.5+90], [7.5,-7.5+90]], color = "green")
    box_score0 = text("Outs: "+ str(cgs[0]), (245, 415), color="blue") #, fontsize="small")
    box_score1 = text("Inning: "+ str(cgs[4]), (240, 400), color="blue") #, fontsize="small")
    box_score2 = text("visitor score: "+ str(cgs[5]), (220, 385), color="blue") #, fontsize="small")
    box_score3 = text("home team score: "+ str(cgs[6]), (202, 370), color="blue") #, fontsize="small")
    if cgs[-1]==0:
        box_score4 = text("At-bat: visiting team", (240, 440), color="green")
    if cgs[-1]==1:
        box_score4 = text("At-bat: home team", (240, 440), color="green")
    box_score5 = text("game state: "+ str(cgs), (210, 355), color="blue") #, fontsize="small"")
    if game_state:
        bbd = P + box_score0 + box_score1 + box_score2 + box_score3 + box_score4 + box_score5
    else:
        bbd = P + box_score0 + box_score1 + box_score2 + box_score3 + box_score4
    bases = (cgs[1],cgs[2],cgs[3])
    if bases == (0,0,0):
        return bbd
    if bases == (1,0,0):
        return bbd+plate1
    if bases == (0,1,0):
        return bbd+plate2
    if bases == (0,0,1):
        return bbd+plate3
    if bases == (1,1,0):
        return bbd+plate1+plate2
    if bases == (1,0,1):
        return bbd+plate1+plate3
    if bases == (0,1,1):
        return bbd+plate2+plate3
    if bases == (1,1,1):
        return bbd+plate1+plate2+plate3
    return bbd

def print_baseball_diamond(current_game_state = [0,0,0,0,1,0,0,0]):
    """
    Prints a simple baseball diamond, with the positions numbered as usual.
    A game state is entered (the usual 8-tuple of integers) and
    the number of runners on base is returned as the function value. 

    EXAMPLE:
        sage: print_baseball_diamond()
         7            8
            6       
         5       4       
            1         9 
         2       3      
       'A small baseball diamond (ascii).'
       sage: print_baseball_diamond([0,1,1,1,1,0,0,0])
       A small baseball diamond (ascii). - is batter, * is runner.

         7            8
            6       
         5*      4*      
            1         9 
        -2       3*

        visiting team score: 0
        home team score: 0
        outs: 0
        inning: 1 
        Number of runners on base:
       3


    """
    cgs = current_game_state
    if cgs[1]==1:
        b1 = "*"
    else:
        b1 = " "
    if cgs[2]==1:
        b2 = "*"
    else:
        b2 = " "
    if cgs[3]==1:
        b3 = "*"
    else:
        b3 = " "
    pos =  "  7            8\n     6       \n  5" + b3 + "      4" + b2 + "      \n     1         9 \n -2       3" + b1 +"\n"
    info = "\n visiting team score: " + str(cgs[5])+ "\n home team score: " + str(cgs[6]) + "\n outs: " + str(cgs[0]) + "\n inning: " + str(cgs[4])
    print("A small baseball diamond (ascii). - is batter, * is runner.\n")
    print(pos+info)
    num_onbase = 0
    onbase = []
    if not(b1==" "):
        num_onbase = num_onbase + 1
        onbase = onbase+["r1"]
    if not(b2==" "):
        num_onbase = num_onbase + 1
        onbase = onbase+["r2"]
    if not(b3==" "):
        num_onbase = num_onbase + 1
        onbase = onbase+["r3"]
    print(" Number of runners on base:")
    return num_onbase
    
def plot_comparison(X,Y, N = 20, leg_lab = " ", X_axis_lab = " ", Y_axis_lab = " "):
    """
    Returns a plot with the linear regression line of the lists of numbers X and Y
    (having the same length). Think of X, Y as being taken from G, PA, and so on.
    Provide legend_label and axis_label as strings, if desired.
    This is a utility function.
    
    EXAMPLES:
        sage: plot_comparison(BA, OPS, 18, "BA = batting average, OPS = on-base plus slugging ", "BA axis ", "OPS axis ")
        Launched png viewer for Graphics object consisting of 2 graphics primitives
    
    """
    X_N = [X[i] for i in range(N)]
    Y_N = [Y[i] for i in range(N)]
    data = list(zip(X_N,Y_N))
    a,b = var('a,b')
    f(x)=a*x+b
    ans=find_fit(data,f)
    g(x)=ans[0].rhs()*x+ans[1].rhs()
    P = plot(g(x),(x,min(X_N),max(X_N)),color="red")+list_plot(data, legend_label=leg_lab, axes_labels=[X_axis_lab,Y_axis_lab])
    return P
    
def csv_lines_with_match(input_csv_file, search_txt):
    """
    Returns line numbers in csv file which contain a match with the string search_txt
    This is a utility function.

    EXAMPLES:
        sage: gamelog_csv = "/Users/davidjoyner/baseball/retrosheet-data/gamelogs/gamelog1998.csv"
        sage: L = csv_lines_with_match(gamelog_csv, search_txt="Sosa"); len(L)
        159
    """
    import csv
    f = open(input_csv_file)
    lines = f.readlines()
    N0 = len(lines)
    L = []
    for j in range(1,N0):
        line = lines[j]
        if search_txt in line:
           L = L+[j]
    return L

def retrosheet_playerID(player_id = "mullc002", player_id_csv_file = "retrosheet_playerID_biofile.csv", verbose=False):
    """
    Returns the "nickname" of the player, the real name and POB if verbose=True.

    EXAMPLES:
        sage: retrosheet_playerID(player_id = "mullc002", player_id_csv_file = "retrosheet_playerID_biofile.csv", verbose=True)
         Full name: Boyce Cedric Mullins
         Born: 10/01/1994 in Greensboro, North Carolina, USA
         'Mullins, Cedric'
        sage: retrosheet_playerID(player_id = "mullc002", player_id_csv_file = "retrosheet_playerID_biofile.csv")
         'Mullins, Cedric'
        sage: retrosheet_playerID(player_id = "santa003", player_id_csv_file = "retrosheet_playerID_biofile.csv", verbose=True)
         Full name: Anthony Roger Santander
         Born: 10/19/1994 in Margarita, Nueva Esparta, Venezuela
         'Santander, Anthony'

    """
    sfl = strip_list_last_char
    picf = retrosheet_directory + player_id_csv_file
    import csv
    f = open(picf, "r")
    lines = f.readlines()
    N0 = len(lines)
    L = []
    for j in range(1,N0):
        linej = lines[j].split(",")
        if player_id in linej[0]:
            if verbose:
                print("Full name: "+ sfl(linej[2]) + " " + sfl(linej[1]))
                print("Born: " + sfl(linej[4]) + " in " + sfl(linej[5]) + ", " + sfl(linej[6]) + ", " + sfl(linej[7]))
            #print(linej)
            fn = strip_list_last_char(linej[3])
            ln = strip_list_last_char(linej[1])
            return ln + ", " + fn
        #break
    f.close()

def strip_list_last_char(word_with_quotes):
    """
    Returns all the characters but the first and last (which could be
    quotes but don't have to).

    EXAMPLES:
        sage: word_with_quotes = '"hello world"'
        sage: strip_list_last_char(word_with_quotes)
         'hello world'

    """
    fn0 = word_with_quotes
    fn1 = fn0[:-1]
    word_without_quotes = fn1[1:]
    return word_without_quotes

# Function to extract date from string
def extract_date(s):
    """
    Regular expression to match a date in the format YYYY-MM-DD

    EXAMPLES:
        # Sort the list by the extracted dates
        sorted_gamefiles = sorted(game_files, key=extract_date)
        # Print the sorted list
        for string in sorted_gamefiles:
            print(string)

    """
    import re
    from datetime import datetime
    match = re.search(r'\d{4}-\d{2}-\d{2}', s)
    if match:
        # Convert the found date string into a datetime object
        return datetime.strptime(match.group(), '%Y-%m-%d')
    else:
        # Return a default datetime if no date is found
        return datetime.min


def sorted_filenames(dir, master_dir = "BAL-home_2023/"):
    """
    Returns the elements of the directory dir as a list of strings.

    EXAMPLES:
        sage: sorted_filenames(retrosheet_directory+"BAL-home_2023/")
         ['/Users/davidjoyner/baseball/retrosheet-data/events/BAL-home_2023/NYA-BAL-2023-04-07-0.txt',
          '/Users/davidjoyner/baseball/retrosheet-data/events/BAL-home_2023/NYA-BAL-2023-04-08-0.txt',
          '/Users/davidjoyner/baseball/retrosheet-data/events/BAL-home_2023/NYA-BAL-2023-04-09-0.txt',
          '/Users/davidjoyner/baseball/retrosheet-data/events/BAL-home_2023/OAK-BAL-2023-04-10-0.txt',
          '/Users/davidjoyner/baseball/retrosheet-data/events/BAL-home_2023/OAK-BAL-2023-04-11-0.txt',
         ...
         ]

    # Note: retrosheet_directory = '/Users/davidjoyner/baseball/retrosheet-data/events/'

    """
    import os
    game_files = os.listdir(dir)
    sorted_gamefiles = sorted(game_files, key=extract_date)
    #master_dir = "BAL-home_2023/"
    game_files_sorted = [master_dir + x for x in sorted_gamefiles]
    return game_files_sorted

def list_indices(x, L):
    """
    Returns the list if indices i for which x==L[i]

    EXAMPLES:
        sage: list_indices(1, U)
         [5, 11]
        sage: U[5]; U[11]
         1
         1
        sage: list_indices(-11, U)
         []
        sage: list_indices(2, U)
         [0, 4, 9]

    """
    if not(x in L):
        return []
    Is = []
    for i in range(len(L)):
        if L[i]==x:
            Is = Is+[i]
    return Is

def list_as_function(x, L):
    """
    This assumes that L is a list of pairs, where
    x occurs once and only once as the first coordinate
    (so is a function). 
    Returns the corresponding 2nd coordinate.

    EXAMPLES:
        sage: V = [(1,[1,3,5]), (3,[2,4,6]), (4,[-1,0,2])]
        sage: list_as_function(3, V)
         [2, 4, 6]

    """
    L0 = [y[0] for y in L] 
    L1 = [y[1] for y in L]
    if not(x in L0):
        return []
    i = L0.index(x)
    return L1[i]


def is_p_num_p_in_string(s):
    """
    If the string s contains a substring of the form
    "(ab...c)", where a, b, c ... are 0, ..., 9,
    then return True. Otherwise, return False.

    Assume that there is at most one "(" in s and,
    if so, one ")" to the right of it.

    1) list all parenthesis pairs in a string
    2) test if any of them as the form (num)
    
    Used in the convert_to_state_FC function given above,
    for example, to help determine which outs are negated
    first by an E and then negated again from a "(<num>)" 
    substring.

    EXAMPLES:
        sage: is_p_num_p_in_string("1X2(4E6)(6)")
         True
        sage: is_p_num_p_in_string("1X24E6)6)")
         False

    """
    stack = []
    pairs = []
    for i, char in enumerate(s):
        if char == '(':
            stack.append(i)
        elif char == ')':
            if stack:
                start_index = stack.pop()
                pairs.append((start_index, i))
    #print(pairs)
    if len(pairs)>0:
        for pr in pairs:
            s_lp_rp = s[pr[0]+1:pr[1]]
            #print(s_lp_rp, s_lp_rp.isnumeric())
            if s_lp_rp.isnumeric():
                return True
    return False

def game_with_play(games_file, play):
    """
    Returns the list of all games in the games_file for which that play
    occurred.

    EXAMPLES:
	sage: games_file = "1994NYA.EVA"
        sage: play = "play,8,1,boggw001,10,B>B,DI.1-2"
        sage: game_with_play(games_file, play)
         [2703, 'info,date,1994/05/11\n', 'info,visteam,CLE\n']

    """
    gfile = retrosheet_directory + games_file
    L = []
    f = open(gfile, "r")
    lines = f.readlines()
    N0 = len(lines)
    for i in range(N0-1):
        if play in lines[i]:
            L = L+[i]
            for j in range(min(i,200)):
                if ",date," in lines[i-j]:
                    L = L + [lines[i-j],lines[i-j-3]]
                    return L
    f.close()
    return L




################ from matrix-ranking-utilities.sage (c) wdj, 2018 BSD license

def matrix_team_ranking(M, confidence="False"):
    r"""
    ### REWRITE so r is derived from M and M is not +-1,0 valued.###

    M is a comparison integer matrix (derived form a sport/game tournament of some kind)
    with exactly 2 non-zero entries per row,
    n columns (indexing the items we want to rank) and 
    m = n(n-1)/2 rows (indexing the comparisons between these items).
    From M we derive:
        * M0 = a comparison integer matrix with entries in
          {0, -1, +1}, regarded as an edge flow. +1 if M_{ij}>M_{i,j+e},
          -1 if M_{ij}<M_{i,j+e}, 0 otherwise.
        * r = a positive-integer "score" vector, r_k = M_{ij}-M_{i,j+e},
          where k is the index of the row in M where M_{ij}  !=  0 and
          M_{i,j+e}  !=  0. 
    Returns the Hodge ranking of the column indices. 
    #Returns the "size" of the curl component if confidence="True".

    Suppose A>B, C>A, A>D, C>B, D>B, C>D. Should have B<D<A<C.

    EXAMPLES:
        sage: M = matrix(QQ,[[1,-1,0,0],
        [-1,0,1,0],
        [1,0,0,-1],
        [0,-1,1,0],
        [0,-1,0,1],
        [0,0,1,-1]])
        sage: ranking(M)
        (-1, 2, -3, 1, 2, -1)

    """
    rM = M.rows()
    m = len(rM)
    r = [0]*m
    for i in range(m):
        L = rM[i].nonzero_positions()
        print(i, L)
        r[i] = rM[i][L[1]]-rM[i][L[0]]
    P = M*(M.transpose()*M).pseudoinverse()*M.transpose()
    return P*vector(QQ,r)

def remove_all_zero_rows_and_columns(A):
    m = len(A.rows())
    n = len(A.columns())
    zerom = A.columns()[0]*0
    zeron = A.rows()[0]*0
    z_cols = [i for i in range(n) if A.row(i)==zerom]
    z_rows = [i for i in range(m) if A.column(i)==zeron]
    A1 = A.delete_rows(z_cols)
    A2 = A1.delete_columns(z_rows)
    return A2


def runs_rank_homegames(team = "BAL", season = 2022):
    """
    Returns total runs ranking of all the visiting teams who played <team> in the <season> home games of <team>.

    EXAMPLES:
       sage: rrh = runs_rank_homegames(team = "ARI", season = 2023)
       sage: L = [(rrh[i], MLB_team_names[i]) for i in range(30)]
       sage: L.sort()
       sage: print(L)
        [(-13, 'NYN'), (-13, 'PHI'), (-9, 'HOU'), (-7, 'SLN'), (-6, 'SEA'), (-5, 'ATL'),
         (-5, 'BAL'), (-4, 'BOS'), (-2, 'CLE'), (-2, 'MIA'), (-2, 'TBA'), (0, 'ANA'),
         (0, 'ARI'), (0, 'CHA'), (0, 'DET'), (0, 'MIN'), (0, 'NYA'), (0, 'OAK'), (0, 'TOR'),
         (1, 'MIL'), (2, 'KCA'), (2, 'SDN'), (2, 'WAS'), (3, 'PIT'), (4, 'TEX'), (5, 'CIN'),
         (6, 'LAN'), (7, 'CHN'), (14, 'SFN'), (21, 'COL')]
       sage: 

    """
    v00 = [0*i  for i in range(30)]
    S = scores_in_homegames(team, season)
    j0 = MLB_team_names.index(team)
    #print(j0, team)
    for i in range(30):
        tn = MLB_team_names[i]
        S_tn_ht = [(x[3],x[4]) for x in S if x[1]==tn]
        tn_score_vs_team = sum([y[0] for y in S_tn_ht])
        team_score_vs_tn = sum([y[1] for y in S_tn_ht])
        #print(i, tn, tn_score_vs_team, team, team_score_vs_tn)
        if (tn_score_vs_team > 0) and (team_score_vs_tn > 0):
            v00[i] = team_score_vs_tn - tn_score_vs_team 
    return v00


def wins_rank_homegames(team = "BAL", season = 2022, verbose = False):
    """
    Returns total runs ranking of all the visiting teams who played <team> in the <season> home games of <team>.
    It also returns, for each visiting team VT, the pair (W-L, W+L), where W is the
    total score by VT at <team> and L is the total score by the (home) <team> (playing against VT).
    
    EXAMPLES:
        sage: wrh = wins_rank_homegames(team='CHA', season=2023)[1]
        sage: L = [((x[0]+x[1])/2, x[1], x[2]) for x in wrh]  ###### to sort by VT wins
        sage: L.sort()
        sage: print(L)
         [(0, 0, 'ATL'), (0, 0, 'CHA'), (0, 0, 'CIN'), (0, 0, 'COL'), (0, 0, 'LAN'), (0, 0, 'NYN'), (0, 0, 'PIT'), (0, 0, 'WAS'),
          (1, 3, 'BOS'), (1, 3, 'NYA'), (2, 2, 'CHN'),
          (2, 3, 'ANA'), (2, 3, 'ARI'), (2, 3, 'BAL'), (2, 3, 'HOU'), (2, 3, 'MIA'), (2, 3, 'PHI'), (2, 3, 'SEA'), (2, 3, 'SFN'), (2, 3, 'SLN'), (2, 3, 'TEX'),
          (2, 4, 'OAK'), (2, 6, 'KCA'), (3, 3, 'MIL'), (3, 3, 'SDN'), (3, 3, 'TOR'), (3, 4, 'TBA'), (3, 6, 'DET'), (3, 7, 'CLE'), (4, 7, 'MIN')]

    """
    v00 = [0*i  for i in range(30)]
    S = scores_in_homegames(team, season)
    j0 = MLB_team_names.index(team)
    wl = []
    for i in range(30):
        tn = MLB_team_names[i]
        S_tn_ht = [(x[3],x[4]) for x in S if x[1]==tn]
        win_vt_vs_ht = [sgn(y[0]-y[1]) for y in S_tn_ht]
        if verbose:
            print(i, tn, win_vt_vs_ht, sum(win_vt_vs_ht))
        v00[i] = sum(win_vt_vs_ht)
        wl = wl+[(v00[i], len(S_tn_ht), tn)]
    return v00, wl
