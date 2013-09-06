web: bundle exec thin start -p 5000 -e development
redis: redis-server /usr/local/etc/redis.conf
sidekiq-worker: bundle exec sidekiq -C sidekiq.yml
