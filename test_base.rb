require "rubygems"
require "test/unit"
require "date"

require './marqeta_api'
include Marqeta_APIS
require './defaults'

# Base class to be used by Test Cases so we get common logging, etc.
class TestBase < Test::Unit::TestCase
  def setup
    $log.info "EXECUTING TEST: #{self.method_name}"
  end

  def teardown
    $log.info "RESULT: #{self.passed? ? "PASSED" : "FAILED"}"
  end
end