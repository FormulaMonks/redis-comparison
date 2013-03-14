#! /usr/bin/env ruby

require "benchmark"
require "clap"
require "pry"

require "json"

require "redis"
require "cassandra"
require "couchdb"
require "mongo"
require "riak"

# Setup
host = "127.0.0.1"
iter = 1_000
data = { type: "Developer", age: 34, level: 0 }
$debug = false

Clap.run ARGV,
  "-n" => lambda { |n| iter = n.to_i },
  "-h" => lambda { |h| host = h },
  "-d" => lambda { $debug = true }

# Helpers
def bench title, &block
  puts
  puts title
  puts "-" * (11 + Benchmark::CAPTION.size)

  start = Time.now

  Benchmark.bm(10) do |bm|
    yield bm
  end
rescue => ex
  puts ex
  binding.pry if $debug
ensure
  puts "Total benchmark time for #{title}: #{Time.now - start}s"
end

# Gentlemen, start your engines!
puts "Running benchmarks against host #{host}"
puts "Each benchmark iterates #{iter} times for each operation"

bench("Redis") do |bm|
  redis = Redis.connect url: "redis://#{host}:6379"
  redis.flushdb

  bm.report(:write) do
    iter.times do |i|
      redis.mapped_hmset "player:#{i}", data.merge(name: "Player #{i}")
    end
  end

  bm.report(:read) do
    iter.times do |i|
      redis.hgetall "player:#{i}"
    end
  end

  bm.report(:update) do |i|
    iter.times do |i|
      redis.hincrby "player:#{i}", "level", i
    end
  end
end

bench("MongoDB") do |bm|
  conn = Mongo::Connection.new host, 27017
  coll = conn.db[:benchmarks]

  coll.remove

  bm.report(:write) do
    iter.times do |i|
      coll.save data.merge(id: "player:#{i}", name: "Player #{i}")
    end
  end

  bm.report(:read) do
    iter.times do |i|
      coll.find_one({ id: "player:#{i}" })
    end
  end

  bm.report(:update) do |i|
    iter.times do |i|
      coll.update({ id: "player:#{i}" }, { :$inc => { level: i } }, { upsert: true })
      coll.find_one({ id: "player:#{i}" })["level"]
    end
  end
end

bench("Cassandra") do |bm|
  cassandra = Cassandra.new("Benchmarks", "#{host}:9160")

  cassandra.drop_keyspace "Benchmarks"

  bm.report(:write) do
    iter.times do |i|
      cassandra.insert :Players, i, data
    end
  end

  bm.report(:read) do
    iter.times do |i|
      cassandra.get :Players, i
    end
  end

  bm.report(:update) do
    iter.times do |i|
      player = cassandra.get :Players, i
      player["level"] += i
      cassandra.insert :Players, i, player
    end
  end
end

bench("CouchDB") do |bm|
  server = CouchDB::Server.new host, 5984
  db     = CouchDB::Database.new server, "benchmarks"

  db.delete_if_exists!
  db.create_if_missing!

  bm.report(:write) do
    iter.times do |i|
      doc = CouchDB::Document.new db, data.merge(_id: "player:#{i}", name: "Player #{i}")
      doc.save
    end
  end

  bm.report(:read) do
    iter.times do |i|
      doc = CouchDB::Document.new db, _id: "player:#{i}"
      doc.load
    end
  end

  bm.report(:update) do
    iter.times do |i|
      doc = CouchDB::Document.new db, _id: "player:#{i}"
      doc.load
      doc["level"] += i
      doc.save
    end
  end
end

bench("Riak") do |bm|
  riak   = Riak::Client.new nodes: [{ host: host }]
  bucket = riak.bucket "benchmarks"

  bucket.delete "benchmarks"

  bm.report(:write) do
    iter.times do |i|
      doc = Riak::RObject.new bucket, "player:#{i}.js"
      doc.content_type = "application/javascript"
      doc.raw_data = JSON.dump(data.merge(name: "Player #{i}"))
      doc.store
    end
  end

  bm.report(:read) do
    iter.times do |i|
      bucket.get_or_new "player:#{i}.js"
    end
  end

  bm.report(:update) do
    iter.times do |i|
      doc = bucket.get_or_new "player:#{i}.js"
      js  = JSON.parse(doc.raw_data)
      js["level"] += i
      doc.raw_data = JSON.dump(js)
      doc.store
    end
  end
end
