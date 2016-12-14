require 'test_helper'

class DjOneTest < Minitest::Test
  class TestJob < Struct.new(:user_id)
    def perform
    end

    def unique_id
      "test_job_#{user_id}"
    end
  end

  def setup
    clear_jobs
  end

  def test_without_dj_one_you_can_schedule_two_identical_jobs
    without_dj_one

    user_id = 14

    job1 = schedule_test_job(user_id)
    job2 = schedule_test_job(user_id)

    refute_nil job1.id
    refute_nil job2.id
    assert_equal Delayed::Job.count, 2
  end

  def test_with_dj_one_it_prevents_scheduling_same_job_twice
    with_dj_one

    user_id = 14

    job1 = schedule_test_job(user_id)
    job2 = schedule_test_job(user_id)

    refute_nil job1.id
    assert_nil job2.id
    assert_equal Delayed::Job.count, 1
  end

  def clear_jobs
    Delayed::Job.delete_all
  end

  def without_dj_one
    Delayed::Worker.plugins = []
    Delayed::Worker.setup_lifecycle
  end

  def with_dj_one
    Delayed::Worker.plugins = [DjOne::Plugin]
    Delayed::Worker.setup_lifecycle
  end

  def schedule_test_job(user_id)
    Delayed::Job.enqueue(TestJob.new(user_id))
  end
end
