web: bundle exec thin start -p 5000 -e development
worker: redis-server redis.conf
worker: bundle exec sidekiq -C sidekiq.yml
