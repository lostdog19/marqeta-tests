require "test/unit"
require "test/unit/runner/junitxml"
require "logger"

$log = Logger.new(STDOUT)
$log.sev_threshold = Logger::INFO

# Load all tests 
Dir['./tests/tc*.rb'].each { |file| $log.info("Loading tests from: #{file}"); require file }
