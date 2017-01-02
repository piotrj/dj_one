require 'test_helper'

class DjOneTest < Minitest::Test
  class TestJob < Struct.new(:user_id)
    def perform
      puts "A"
    end

    def enqueue_id
      "test_job_#{user_id}_enqueued"
    end

    def perform_id
      "test_job_#{user_id}_performing"
    end

    def max_attempts
      2
    end

    def destroy_failed_jobs?
      false
    end
  end

  def setup
    clear_jobs
    clear_workers
  end

  def test_without_dj_one_you_can_schedule_two_identical_jobs
    without_dj_one

    user_id = 14

    job1 = schedule_test_job(user_id)
    job2 = schedule_test_job(user_id)

    refute_nil job1.id
    refute_nil job2.id
    assert_equal 2, Delayed::Job.count
  end

  def test_it_prevents_scheduling_same_job_twice
    with_dj_one

    user_id = 14

    job1 = schedule_test_job(user_id)
    job2 = schedule_test_job(user_id)

    refute_nil job1.id
    assert_nil job2.id
    assert_equal 1, Delayed::Job.count
  end

  def test_job_changes_unique_id_when_it_is_being_processed
    with_dj_one

    user_id = 16
    job1 = schedule_test_job(user_id)

    job1_scheduled_id = job1.unique_id
    job1_performing_id = nil
    stub_perform do
      job1_performing_id = job1.reload.unique_id
    end

    Delayed::Worker.new.work_off
    assert_match /enqueued$/, job1_scheduled_id
    assert_match /performing$/, job1_performing_id
  end

  def test_same_job_cannot_be_processed_at_the_same_time
    with_dj_one

    user_id = 16
    job1 = schedule_test_job(user_id)
    mark_as_processing(job1)

    job2 = schedule_test_job(user_id)

    job_processed = false
    stub_perform do
      job_processed = true
    end

    Delayed::Worker.new.work_off

    assert_equal false, job_processed
  end

  def test_when_job_fails_for_the_last_time_unique_id_is_removed
    with_dj_one

    user_id = 16
    job1 = schedule_test_job(user_id)

    stub_perform do
      raise StandardError.new
    end

    Delayed::Worker.new.work_off

    refute_nil job1.reload.unique_id
    job1.update_attributes(run_at: Time.now)

    Delayed::Worker.new.work_off

    assert_nil job1.reload.unique_id
  end

  def clear_jobs
    Delayed::Job.delete_all
  end

  def clear_workers
    @workers_count = 0
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

  def stub_perform(&block)
    TestJob.send(:define_method, :perform_stub, &block)
    TestJob.send(:alias_method, :perform_original, :perform)
    TestJob.send(:alias_method, :perform, :perform_stub)
  ensure

  end

  def clear_perform_stub
    if TestJob.new.respond_to?(:perform_original)
      TestJob.send(:undef_method, :perform_stub)
      TestJob.send(:alias_method, :perform, :perform_original)
      TestJob.send(:undef_method, :perform_original)
    end
  end

  def mark_as_processing(job)
    job.update_attributes(unique_id: job.payload_object.enqueue_id, locked_at: Time.now)
  end
end
