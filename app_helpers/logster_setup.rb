require 'redis'
require 'logster'
require 'logster/middleware/reporter'
require 'logster/middleware/viewer'


$redis = Redis.new
$store = Logster.store = Logster::RedisStore.new($redis)
$log = Logster.logger = Logster::Logger.new($store)
