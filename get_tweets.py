import tweepy
import datetime
import codecs
import simplejson as json

consumer_key	= 
access_token	= 
consumer_secret = 
access_token_secret = 

now = datetime.datetime.now()
input_file = "latest_tweets"
output_file = "all_senators_tweets" 
with open(input_file, 'r') as fin:
    senator_list = json.loads(fin.read())

# necessary to convert created_at (datetime object) to json
date_handler = lambda obj: (
                obj.isoformat()
                if isinstance(obj, datetime.datetime)
                or isinstance(obj, datetime.date)
                else None
            )

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
api = tweepy.API(auth)

with open(output_file, 'a') as fout:
    for sen in senator_list:
        try:
            #senator_tweets = tweepy.Cursor(api.user_timeline, id = sen['senatorId'], max_id = sen['first'], count = 200).items(200)
            tweet_cursor = int(sen.get('last',100))
            print "Current user ID is %s, current tweet id is %s" % (sen['senatorId'], tweet_cursor)
            senator_tweets = api.user_timeline(user_id=sen['senatorId'],since_id=tweet_cursor,count=200)
            for tweet in senator_tweets:
                tweet_obj = json.dumps({'id':tweet.id,'text':tweet.text.encode('utf-8'),'author_id':tweet.author.id,'tweet_time':tweet.created_at}, default=date_handler)
                print >> fout, tweet_obj
                #print "New tweets for %s, latest is %s" % (tweet.author.screen_name, tweet.id)
        except Exception as e:
            print "Request failed for %s, %s" % (sen['senatorId'], e)


end_timestamp = datetime.datetime.now()
with open('run_log', 'a') as fout:
    print >> fout, end_timestamp
