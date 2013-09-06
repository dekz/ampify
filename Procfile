web: bundle exec thin start -p 5000 -e development
job: redis-server /usr/local/etc/redis.conf
job: bundle exec sidekiq -C sidekiq.yml
