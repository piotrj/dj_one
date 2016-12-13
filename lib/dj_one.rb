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
      end

      def enqueue(job, &proceed)
        job_handler = job.payload_object
        job.unique_id = job_handler.respond_to?(:unique_id) &&  job_handler.unique_id
        proceed.call
      rescue ActiveRecord::RecordNotUnique
      end
    end
  end
end
