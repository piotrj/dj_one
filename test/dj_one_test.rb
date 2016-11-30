require 'test_helper'

class DjOneTest < Minitest::Test
  class TestJob
    def perform
    end
  end

  def test_it_is_possible_to_create_job
    Delayed::Job.enqueue(TestJob.new)
    assert_equal 1, Delayed::Job.count
  end
end
