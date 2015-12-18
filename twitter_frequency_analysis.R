#### Pre-Start ####
### set directory
setwd('/Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/')
### call necessary libraries
library(sqldf)
library(slam)
library(tm)
### define variables from data saved to disk
## Tweets returned by python script
rawTweets <- readLines('all_senators_tweets')
## define common words to filter out e.g. 'the','I','http','.com'
commonWords <- as.character(tolower(unlist(read.table('common_words'))))
## add details to about twitter authors including party affliation and geographic location
userDetails <- read.csv('senator_details.csv')
#### End Pre-start ####

#### Read tweets from python results ####
### Read individual tweets and convert to dataframe
tweets.json <- lapply(rawTweets, jsonlite::fromJSON, flatten = TRUE)
tweets.df <- data.frame(sapply(tweets.json, '[[',2))
## create data frame of senator ID, tweet ID, and text
names(tweets.df)[1] <- 'senatorId'
tweets.df$tweetId <- sapply(tweets.json, '[[',3)
tweets.df$text <- sapply(tweets.json, '[[',1)
# remove duplicate tweets -- there shouldn't be any, but for insurance
tweets.df.dedupe <- subset(tweets.df,!duplicated(tweets.df$tweetId))
## get words in tweet body
words <- unlist(strsplit(tolower(tweets.df.dedupe$text), '\\W+'))
## count of words in tweet body
wordCount <- data.frame(table(words))
## scrub: filter common words from all tweets to get most popular words
popularWords <- tail(wordCount[order(wordCount$Freq),],20000)
popularUncommonWords <- subset(popularWords,!(popularWords$words %in% commonWords))
#### End read tweets ####

#### add political party information to contrast Democratic and Republican tweets ####
### create subset to tweets based on Party (republicans)
elephants <- subset(userDetails,userDetails$party == 'Republican')
elephants.tweets <- subset(tweets.df.dedupe, tweets.df$senatorId %in% elephants$twitterId)
### repeat process to convert to dataframe and word counts
elephants.words <- unlist(strsplit(tolower(elephants.tweets$text), '\\W+'))
elephants.wordCount <- data.frame(table(elephants.words))
elephants.popularWords <- tail(elephants.wordCount[order(elephants.wordCount$Freq),],20000)
elephants.popularUncommonWords <- subset(elephants.popularWords,!(elephants.popularWords$elephants.words %in% commonWords))
tail(elephants.popularUncommonWords)
## most popular words for (democrats)
donkeys <- subset(userDetails,userDetails$party == 'Democratic')
donkeys.tweets <- subset(tweets.df.dedupe, tweets.df$senatorId %in% donkeys$twitterId)
### repeat process to convert to dataframe and word counts
donkeys.words <- unlist(strsplit(tolower(donkeys.tweets$text), '\\W+'))
donkeys.wordCount <- data.frame(table(donkeys.words))
donkeys.popularWords <- tail(donkeys.wordCount[order(donkeys.wordCount$Freq),],20000)
donkeys.popularUncommonWords <- subset(donkeys.popularWords,!(donkeys.popularWords$donkeys.words %in% commonWords))
tail(donkeys.popularUncommonWords)
#### End create subsets based on party lines ####

#### Calculate popular word associations and store as JSON ####
### Republicans
## get list of words to find associations of from Republican tweet subset and store as corpus object
elephant.tweets.corpus <- tm::Corpus(tm::VectorSource(elephants.tweets$text))
## scrub object for capitalization, common words and punctuation
elephant.tweets.corpus <- tm_map(elephant.tweets.corpus, content_transformer(tolower), lazy = TRUE)
elephant.tweets.corpus <- tm_map(elephant.tweets.corpus, removePunctuation, lazy = TRUE)
elephant.tweets.corpus <- tm_map(elephant.tweets.corpus, removeWords, commonWords, lazy = TRUE)
## create Term Document Matrix required for frequency analysis
elephant.tmdoc <- TermDocumentMatrix(elephant.tweets.corpus, control = list(wordLengths=c(1, Inf)))
# remove 'rare' words
elephant.tmdoc.moreSparse <- removeSparseTerms(elephant.tmdoc, 0.99)
## create vector to use as argument for correlation analysis and use findAssoc() to calculate associations
elephant.wordVector <- as.character(elephants.popularUncommonWords$elephants.words)
elephant.associations <- findAssocs(elephant.tmdoc.moreSparse, elephant.wordVector,.01)
## transform results into JSON dictionary
elephant.associations.list <- lapply(elephant.associations, function(z) mapply(c, unlist(z), lapply(z, names), SIMPLIFY = FALSE)) 
elephant.associations.json <- jsonlite::toJSON(elephant.associations.list)
## save results to disk
write(elephant.associations.json, file="/Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/association_json/elephants.json")

### Democrats
## get list of words to find associations of from Democratic tweet subset and store as corpus object
donkey.tweets.corpus <- tm::Corpus(tm::VectorSource(donkeys.tweets$text))
## scrub object for capitalization, common words and punctuation
donkey.tweets.corpus <- tm_map(donkey.tweets.corpus, content_transformer(tolower), lazy = TRUE)
donkey.tweets.corpus <- tm_map(donkey.tweets.corpus, removePunctuation, lazy = TRUE)
donkey.tweets.corpus <- tm_map(donkey.tweets.corpus, removeWords, commonWords, lazy = TRUE)
## create Term Document Matrix required for frequency analysis
donkey.tmdoc <- TermDocumentMatrix(donkey.tweets.corpus, control = list(wordLengths=c(1, Inf)))
# remove 'rare' words
donkey.tmdoc.moreSparse <- removeSparseTerms(donkey.tmdoc, 0.99)
## create vector to use as argument for correlation analysis and use findAssoc() to calculate associations
donkey.wordVector <- as.character(donkeys.popularUncommonWords$donkeys.words)
donkey.associations <- findAssocs(donkey.tmdoc.moreSparse, donkey.wordVector,.01)
## transform results into JSON dictionary
donkey.associations.list <- lapply(donkey.associations, function(z) mapply(c, unlist(z), lapply(z, names), SIMPLIFY = FALSE)) 
donkey.associations.json <- jsonlite::toJSON(donkey.associations.list)
## save results to disk
write(donkey.associations.json, file="/Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/association_json/donkeys.json")
#### End Calculate associations ####

#### Find associations for individual users and save to disk ####
### create function to find associations for individual users
get_senators_tweets <- function(senator.id){
    # subset tweets by author id
    senator.tweets <- subset(tweets.df.dedupe, tweets.df$senatorId == senator.id)
    # repeat process to convert to dataframe and word counts
    senator.words <- unlist(strsplit(tolower(senator.tweets$text), '\\W+'))
    senator.wordCount <- data.frame(table(senator.words))
    senator.popularWords <- tail(senator.wordCount[order(senator.wordCount$Freq),],20000)
    senator.popularUncommonWords <- subset(senator.popularWords,!(senator.popularWords$senator.words %in% commonWords))
    
    ## Calculate popular word associations and store as JSON
    # get list of words to find associations of from Republican tweet subset and store as corpus object
    senator.tweets.corpus <- tm::Corpus(tm::VectorSource(senator.tweets$text))
    # scrub object for capitalization, common words and punctuation
    senator.tweets.corpus <- tm_map(senator.tweets.corpus, content_transformer(tolower), lazy = TRUE)
    senator.tweets.corpus <- tm_map(senator.tweets.corpus, removePunctuation, lazy = TRUE)
    senator.tweets.corpus <- tm_map(senator.tweets.corpus, removeWords, commonWords, lazy = TRUE)
    # create Term Document Matrix required for frequency analysis
    senator.tmdoc <- TermDocumentMatrix(senator.tweets.corpus, control = list(wordLengths=c(1, Inf)))
    # remove 'rare' words
    senator.tmdoc.moreSparse <- removeSparseTerms(senator.tmdoc, 0.99)
    # create vector to use as argument for correlation analysis and use findAssoc() to calculate associations
    senator.wordVector <- as.character(senator.popularUncommonWords$senator.words)
    senator.associations <- findAssocs(senator.tmdoc.moreSparse, senator.wordVector,.01)
    # transform results into JSON dictionary
    senator.associations.list <- lapply(senator.associations, function(z) mapply(c, unlist(z), lapply(z, names), SIMPLIFY = FALSE)) 
    senator.associations.json <- jsonlite::toJSON(senator.associations.list)
    # save results to disk
    write(senator.associations.json, file=paste0("/Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/association_json/",senator.id,".json"))
}
### run function for each author ID in userDetails table to save individual associations to disk
for(id in userDetails$twitterId){get_senators_tweets(id)}
