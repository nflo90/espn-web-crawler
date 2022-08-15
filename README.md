# espn-web-crawler
Scrape the team stats table from ESPN (or similar website with nested tables, text, etc.)

This is a web crawler designed to reverse engineer links to nested data on websites. While there are other methods to webcrawling/scraping, I have found this to be
the most intuitive, reproducible approach. The ease with which this technique can be applied to multiple websites requires very little new code. 

To use this, I am assuming base knowledge of selector gadget and R. This web crawler utilizes tidyverse in addition to the rvest package to handle scraping. 
Additional familiarity of the purrr package is preferable, as this utilizes purrr for mapping data from the scraped webpages. 

This approach works to scrape similar data from multiple pages, like tables or text. Using ESPN as the example, we are working through constructing urls like this 
https://www.espn.com/nfl/matchup?gameId=401326626. This file walks through how to scrape game stats for every game for a season. To do that, we need to crawl through
the list of teams, the schedules, and finally the nested page where the data is. 
