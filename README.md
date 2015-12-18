# cs6020_twitter_app

##Data flow: Script order of execution
1. com.r.senatorTweetsPollJob.plist: An OS X LaunchAgent Script to schedule the following processes
2. initialize_twitter_poll_job.sh: A simple shell script triggered by the LaunchAgent to initiate the following R script
3. process_tweets.R: Analyzes current database to inform following python script which information should be requested
4. get_tweets.py: Uses the tweepy python module to retrieve new information
5. twitter_frequency_analysis.R: Uses several functions from the 'tm' text mining R library to analyze the data and outputs the results to JSON
6. mongoDB_bulk_import.py: Imports JSON files to a mongodb database
