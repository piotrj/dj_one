require 'test_helper'

class DjOneTest < Minitest::Test
  class TestJob < Struct.new(:user_id)
    def perform
    end

    def unique_id
      "test_job_#{user_id}"
    end
  end

  def test_it_prevents_scheduling_same_job_twice
    user_id = 14

    job1 = Delayed::Job.enqueue(TestJob.new(user_id))
    job2 = Delayed::Job.enqueue(TestJob.new(user_id))

    refute_nil job1.id
    assert_nil job2.id
    assert_equal Delayed::Job.count, 1
  end
end
