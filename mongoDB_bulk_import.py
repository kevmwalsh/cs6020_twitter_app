# this script automates importing individual json files into a mongodb
import os
directory = os.listdir("/Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/association_json/")
for file in directory:
    try:
        if file.endswith(".json"):
            cmd = "mongoimport --db test --collection word_associations --port 27000 --file /Users/KMWalsh/Desktop/science/collect_store/twitter_app/poll_job/association_json/%s" % file
            os.system(cmd)
    except Exception as e:
        print e

