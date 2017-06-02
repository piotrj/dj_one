# DjOne

[![Build Status](https://travis-ci.org/piotrj/dj_one.svg?branch=master)](https://travis-ci.org/piotrj/dj_one)

## What is DjOne

DjOne ensures that you don't have duplicate jobs scheduled or running. When you schedule a job as a reaction to some event you may end up with multiple jobs that will be basically doing the same thing.
Moreover, if you have more than 1 worker you may end up with more than 1 exactly same job being processed at a time. This means you may need to ensure that those jobs don't corrupt each others computations.
With DjOne you can ensure that only 1 job is scheduled and processed so you don't need to do synchronization and your workers don't waste time on doing the same thing multiple times.

### Example

Let's say that your application is integrated with Google Calendar. And you listen on push notifications from Google that will let you know that something has changed.
When you get the notification you schedule a Delayed::Job that will fetch all new calendar events for the calendar you got notification for.

Now let's consider following scenario:
1. You receive a push notification for calendar calendarA.
2. You schedule a job to fetch everything new for this calendar. (Let's call it JobA1)
3. The job does not start yet cause workers are processing other jobs.
4. Something else changed in calendar calendarA. You get another notification.
5. At this point you would normally schedule another job. But do you really need to? You already have one job for that calendar that is still pending. So we are using DjOne's functionality and we don't schedule another job.
6. Worker picks up the job for calendarA
7. New change in calendarA. You get another push for that calendar.
8. So now should you schedule a job? In step #5 we didn't want to schedule new one. So probably we don't want to schedule another one now as well, right? All in all we have a job running for that calendar.
Well, so here is the thing. You don't know at which point of operation JobA1 is. It may have just started, but it may have already finished fetching the events. And if you don't schedule new one you won't have the newest data.
9. Ok so we schedule new job for that calendar, let's call it JobA2.
10. Worker is about to pick up JobA2. But, we already have a job for that calendar running. If we start another one maybe they would start interfering on each other's data. So maybe let's not start JobA2 yet. Let's let JobA1 finish.
11. So using DjOne's functionality we are moving JobA2 start time to be a little bit in the future.
12. JobA1 gets finished
13. JobA2 gets picked up by worker again. This time it can run cause there is no other conflicting job.
14. JobA2 finished. We get the freshest data for calendarA.

## Installation

1. Add `dj_one` to your Gemfile.

```
  gem 'dj_one'
```

2. Run `bundle install`.
3. Generate a migration that will add a column and unique index that will help us ensure uniqueness of jobs.
4. Run `rake db:migrate`
5. Add DjOne as a plugin in your DelayedJob initializer
```
# config/initializers/delayed_job_config.rb (or other file where you initialize DelayedJob)

Delayed::Worker.plugins << DjOne::Plugin

```

6. You are all set.


## Usage

Now that we have the gem installed let's add this functionality to our job.

```
FetchCalendarEventsJob = Struct.new(:calendar_name)
  # This is the id that we will try to set when enqueueing the job.
  def enqueue_id
    "fetch_calendar_events_enqueued_#{calendar_name}"
  end

  # This is the id that we will set when we start performing given job
  def perform_id
    "fetch_calendar_events_processing_#{calendar_name}"
  end

  # Used when the worker wants to start the job, but there is already one being performed at the moment.
  # At such case we need to reschedule the job to some point in the future.
  # This method defines how far in the future.
  # If not defined it will use the default 30 seconds.
  def duplicate_delay
    # Here if we try to run the job but we are already currently fetching events for given
    # calendar then we want to try running this job again in 5 minutes.
    5.minutes
  end
end
```

If you add those 2 methos then you will be sure that only 1 job for given calendar_name would be enqueued and processed at any given time.
If you don't care how many same jobs are enqueued then you don't need to specify `enqueue_id` method.
If you don't care how many same jobs are processed at a time then you don't need to specify `perform_id` method.
If you don't specify any methods it will just work without any restrictions.

## License
The gem is available as open source under the terms of the MIT License.

