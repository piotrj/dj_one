require "dj_one/version"

require "active_record"
require "delayed_job"
require "delayed_job_active_record"

require "dj_one/generator"

module DjOne
  class Plugin < Delayed::Plugin
    callbacks do |lifecycle|
      Handler.new(lifecycle)
    end

    class Handler
      def initialize(lifecycle)
        lifecycle.around(:enqueue, &method(:enqueue))
        lifecycle.around(:perform, &method(:perform))
        lifecycle.around(:failure, &method(:failure))
      end

      def enqueue(job, &proceed)
        job.unique_id = get_attribute(job, :enqueue_id)
        proceed.call
      rescue ActiveRecord::RecordNotUnique
      end

      def perform(worker, job, &proceed)
        job.unique_id = get_attribute(job, :perform_id)
        job.save! if job.changed?

        proceed.call
      rescue ActiveRecord::RecordNotUnique
        job.unique_id = job.unique_id_was
        job.run_at = calculate_run_at(job)
        job.save! if job.changed?
      end

      def failure(worker, job, &proceed)
        job.unique_id = nil
        proceed.call
      end

      def get_attribute(job, method_name)
        object = job.payload_object
        object.respond_to?(method_name) ? object.public_send(method_name) : nil
      rescue Delayed::DeserializationError
        nil
      end

      def calculate_run_at(job)
        delay = get_attribute(job, :duplicate_delay) || DEFAULT_DUPLICATE_DELAY
        Time.now + delay
      end
    end
  end
end
