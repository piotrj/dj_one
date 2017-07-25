require 'test_helper'

class OtherPlugin < Delayed::Plugin
  cattr_writer :callbacks_run

  callbacks do |lifecycle|
    lifecycle.around(:enqueue, &method(:handle_enqueue))
    lifecycle.around(:perform, &method(:handle_perform))
    lifecycle.around(:failure, &method(:handle_failure))
  end

  def self.handle_enqueue(job, &block)
    self.callbacks_run << :enqueue
    block.call(job)
  end

  def self.handle_perform(worker, job, &block)
    self.callbacks_run << :perform
    block.call(worker, job)
  end

  def self.handle_failure(worker, job, &block)
    self.callbacks_run << :failure
    block.call(worker, job)
  end

  def self.callbacks_run
    @@callbacks_run ||= []
  end
end

class DjPluginTest < Minitest::Test
  class TestJob
    def perform
    end
  end

  class FailingJob
    def perform
      raise "Some Error"
    end

    def max_attempts
      1
    end
  end

  def setup
    clear_jobs
    setup_plugins
  end

  def test_dj_one_properly_works_with_other_plugins_and_enqueue_callback
    clear_run_callbacks_list
    enqueue_job(TestJob.new)

    assert_equal [:enqueue], run_callbacks_list
  end

  def test_dj_one_properly_works_with_other_plugins_and_perform_callback
    enqueue_job(TestJob.new)
    clear_run_callbacks_list

    run_worker

    assert_equal [:perform], run_callbacks_list
  end

  def test_dj_one_properly_works_with_other_plugins_and_failure_callback
    enqueue_job(FailingJob.new)
    clear_run_callbacks_list

    run_worker

    assert_equal [:perform, :failure], run_callbacks_list
  end

  private
  def clear_jobs
    Delayed::Job.delete_all
  end

  def setup_plugins
    Delayed::Worker.plugins = [DjOne::Plugin, OtherPlugin]
    Delayed::Worker.setup_lifecycle
  end

  def clear_run_callbacks_list
    OtherPlugin.callbacks_run = []
  end

  def run_callbacks_list
    OtherPlugin.callbacks_run
  end

  def enqueue_job(job)
    Delayed::Job.enqueue(job)
  end

  def run_worker
    Delayed::Worker.new.work_off
  end
end
