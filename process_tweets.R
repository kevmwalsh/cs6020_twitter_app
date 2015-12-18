# make sure we're where we need to be
setwd('/Users/KMWalsh/Desktop/science_bitch/collect_store/twitter_app/poll_job/')
# load libraries
library(plyr)
library(jsonlite)
## build 'fetchCursor' which is used to track which information to request from timeline endpoint. This function workds from the present toward the past
# load senators for base table used in 'fetchCursor'
senators <- data.frame(readLines('senators_twitter_ids.txt'))
names(senators)[1] <- "senatorId"
# load data from output of python -- this will eventually be the primary data table
tweets.json <- lapply(readLines('all_senators_tweets'),jsonlite::fromJSON, flatten = TRUE)
# format data
df <- data.frame(sapply(tweets.json, '[[',2))
df$v2 <- data.frame(sapply(tweets.json, '[[',3))
names(df)[1] <- 'senatorId'
senatorIds <- list(df$senatorId)
# find latest and earliers tweets
latestTweets <- aggregate(x = df, by = senatorIds, max)
earliestTweets <- aggregate(x = df, by = senatorIds, min)
# join latest and earliest tweets to one data frame containing first and last tweets on disk
fetchCursor <- join(earliestTweets,latestTweets,by="senatorId",match="first")
names(fetchCursor)[3] <- 'first'
names(fetchCursor)[5] <- 'last'
fetchCursor <- join(fetchCursor,senators,type="right",by="senatorId")
# write first and last table to disk to be used as input in python 
write(jsonlite::toJSON(fetchCursor),file='latest_tweets', ncolumns = 4)
# output sample of data to console
head(fetchCursor)
tail(fetchCursor)
## execute python script to retrieve new tweets
rPython::python.load('get_tweets.py')
