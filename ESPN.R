library(tidyverse)
library(purrr)
library(rvest)
library(janitor)

#this is a web crawler designed to reverse engineer links to nested data on websites
#it works to scrape similar data from multiple pages, like tables or text 
#with espn, we are working through constructing urls like this 
#https://www.espn.com/nfl/matchup?gameId=401326626
#we want to scrape game stats for every game, for every team for the season
#to get that, we need to crawl through the list of teams, the schedules,
#and finally the nested page where the data is 

#read base url
base_url <- read_html("https://www.espn.com/nfl/teams")

#grab team names from base url
teams <- base_url %>% 
  html_nodes(".h5") %>% 
  html_text()
teams <- teams[1:32]

#grab urls to each team schedule
url <- base.url %>% 
  html_nodes(".nowrap:nth-child(2) .AnchorLink") %>% 
  html_attr("href") %>% 
  paste("https://www.espn.com", ., sep = "") 
url <- url[1:32]

#bind teams and url
team_links <- tibble(teams, url) %>% 
  #select season to scrape schedule
  transmute(url = glue::glue("{url}/season/2021"))

################################################################################
#scrape schedules 
results_list <- tibble(
  html_results = map(team.links$url[1:32],#change to length of list 
                     ~ {
                       Sys.sleep(2)
                       # DO THIS!  sleep 2 will pause 2 seconds between server requests
                       #to avoid being identified and potentially blocked /
                       #assume crawling bot is a DNS attack.
                       #also, would recommend checking the /robots.txt to any website you intend to 
                       #scrape data from prior to crawling/scraping
                       #it is important to practice good internet etiquette when webscraping
                       #as you are essentially deploying a bot to the website
                       .x %>%
                         read_html()
                     }),
  summary_url = team.links$url[1:32]
)
################################################################################
#get game IDs from schedules
game_ids <- tibble(summary_url = results_list$summary_url, 
                   team = 
                     map(results_list$html_results,
                         ~ .x %>%
                           html_nodes("#fittPageContainer .db") %>%
                           html_text()),
                   game =
                     map(results_list$html_results,
                         ~ .x %>%
                           html_nodes(".ml4 .AnchorLink") %>%
                           html_attr("href")))

################################################################################
#disaggregate results and create df of game links 
game_links <- game_ids %>% 
  select(team, game) %>% 
  pivot_wider(., names_from = team, values_from = game) %>% 
  drop_na() %>% #just in case you accidentally scrape something partially/unwanted
  clean_names() %>% 
  pivot_longer(cols = everything()) %>% 
  unnest(cols = everything())
game_links$name <- sub("c_*", "", game_links$name)

#single out ids + build new links to game data table, 
game_links$id = substr(game_links$value,40,49)
game_links <- game.links %>% 
  transmute(url = glue::glue("https://www.espn.com/nfl/matchup?gameId={id}")) %>%
  unique()#remove duplicates that were scraped twice due to away + home teams

#get game stats
games_list <- tibble(
  html_results = map(game_links$url[1:3], ##change '3' to length of list 
                     #run test to make sure it scrapes what you want
                     ~ {
                       Sys.sleep(2)
                       .x %>%
                         read_html()
                     }),
  summary_url = game_links$url[1]#change x to length of list 
)
################################################################################
#create dataframe of game data
#this may seem like a lot of code, but to ensure the table scrapes to read as a
#team,game level data in rows, you need to scrape each element individually
game_data <- tibble(summary_url = games_list$summary_url, 
                    home = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".home .short-name") %>%
                      html_text()),
                    away = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".away .short-name") %>%
                      html_text()),
                    line = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".odds-lines-plus-logo li:nth-child(1)") %>%
                      html_text()),
                    over = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes("#gamepackage-game-information li+ li") %>%
                      html_text()),
                    home_score =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes("#gamepackage-matchup-wrap .icon-font-before") %>%
                      html_text()),
                    away_score = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes("#gamepackage-matchup-wrap .icon-font-after") %>%
                      html_text()),
                    home_first_downs =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes("#teamstats-wrap .highlight:nth-child(1) td~ td+ td") %>%
                      html_text()),
                    away_first_downs = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes("#teamstats-wrap .highlight:nth-child(1) td:nth-child(2)") %>%
                      html_text()),
                    home_plays =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(7) td~ td+ td") %>%
                      html_text()),
                    away_plays = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(7) td:nth-child(2)") %>%
                      html_text()),
                    home_yards =  map(
                      games_list$html_results, 
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(8) td~ td+ td") %>%
                      html_text()),
                    away_yards = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(8) td:nth-child(2)") %>%
                      html_text()),
                    home_drives =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(9) td~ td+ td") %>%
                      html_text()),
                    away_drives = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(9) td:nth-child(2)") %>%
                      html_text()),
                    home_yds_play =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(10) td~ td+ td") %>%
                      html_text()),
                    away_yds_play = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(10) td:nth-child(2)") %>%
                      html_text()),
                    home_pass_yds =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(11) td~ td+ td") %>%
                      html_text()),
                    away_pass_yds = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(11) td:nth-child(2)") %>%
                      html_text()),
                    home_pass_att = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(12) td~ td+ td") %>%
                      html_text()),
                    away_pass_att = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(12) td:nth-child(2)") %>%
                      html_text()),
                    home_int =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(14) td~ td+ td") %>%
                      html_text()),
                    away_int = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(14) td:nth-child(2)") %>%
                      html_text()),
                    home_sack =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(15) td~ td+ td") %>%
                      html_text()),
                    away_sack = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(15) td:nth-child(2)") %>%
                      html_text()),
                    home_rush_yds =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(16) td~ td+ td") %>%
                      html_text()),
                    away_rush_yds = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(16) td:nth-child(2)") %>%
                      html_text()),
                    home_red_zone =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(19) td~ td+ td") %>%
                      html_text()),
                    away_red_zone = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(19) td:nth-child(2)") %>%
                      html_text()),
                    home_pen =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(20) td~ td+ td") %>%
                      html_text()),
                    away_pen = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(20) td:nth-child(2)") %>%
                      html_text()), 
                    home_fumble =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(22) td~ td+ td") %>%
                      html_text()),
                    away_fumble = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".indent:nth-child(22) td:nth-child(2)") %>%
                      html_text()), 
                    home_def_td =  map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(24) td~ td+ td") %>%
                      html_text()),
                    away_def_td = map(
                      games_list$html_results,
                      ~ .x %>%
                      html_nodes(".highlight:nth-child(24) td:nth-child(2)") %>%
                      html_text()))
