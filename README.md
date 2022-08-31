# espn-web-crawler
This is a web crawler designed to scrape the team stats table from ESPN (or similar websites with nested tables, text, etc.) This code works to map information from multiple pages containing similar data to a new dataframe. 

The approached used here is to reverse engineer links to nested data and then scrape that data from websites. While there are other methods to webcrawling/scraping, I have found this to be the most intuitive, reproducible approach. The ease with with this technique is that it can be applied to different websites with very little new code. 

To use this, I am assuming base knowledge of selector gadget and R. The majority of the code in this web crawler utilizes tidyverse syntax. 
Additional familiarity with the purrr package is preferable, as this utilizes purrr for mapping data to a dataframe from the scraped webpages. 

Using ESPN as the example, we are working through constructing urls like this "https://www.espn.com/nfl/matchup?gameId=401326626." This file walks through how to scrape game stats for every game for a season. To do that, we need to crawl through the list of teams, the schedules, and finally the pages where the actual data tables are.
