web: bundle exec thin start -p 5000 -e development
web: redis-server redis.conf
web: bundle exec sidekiq -C sidekiq.yml
