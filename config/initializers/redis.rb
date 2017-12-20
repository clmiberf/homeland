require 'redis'
require 'redis-namespace'
require 'redis/objects'

redis_config = Rails.application.config_for(:redis)

$redis = Redis.new(host: redis_config['host'], port: redis_config['port'], password: redis_config['password'])
$redis.select(15)
Redis::Objects.redis = $redis

sidekiq_url = "redis://:#{redis_config['password']}@#{redis_config['host']}:#{redis_config['port']}/15"
Sidekiq.configure_server do |config|
  config.redis = { namespace: 'sidekiq', url: sidekiq_url }
end
Sidekiq.configure_client do |config|
  config.redis = { namespace: 'sidekiq', url: sidekiq_url }
end