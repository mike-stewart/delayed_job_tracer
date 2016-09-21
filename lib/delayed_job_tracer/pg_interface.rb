require 'pg'

class PgInterface

  # Connects to the db and submits a query
  def self.query(sql)
    c = DelayedJobTracer.database_config[ENV['RAILS_ENV']]
    conn = PG.connect(:host => c['host'], :dbname => c['database'], :user => c['username'], :password => c['password'], :sslmode => :require)
    conn.exec(sql)
  end

  # Returns true if there are no stale records
  def self.delayed_job_queue_ok?
    query(delayed_job_stale_records).count.zero?
  end

  # Inserts a delayed_job record
  def self.queue_delayed_job
    query(delayed_job_record).to_s
  end

  # SQL for selecting stale delayed_job records
  def self.delayed_job_stale_records
    c = DelayedJobTracer.config['delayed_job']
    "SELECT * FROM delayed_jobs WHERE created_at < '#{(Time.now-c['stale']).utc.strftime("%Y-%m-%d %H:%M:%S")}'"
  end

  # SQL for inserting a delayed_job record
  def self.delayed_job_record
    "INSERT INTO delayed_jobs (handler, run_at, created_at, updated_at) VALUES
      ('#{delayed_job_handler}', '#{pg_timestamp}', '#{pg_timestamp}', '#{pg_timestamp}')"
  end

  # SQL helper method for inserting a delayed_job record
  def self.delayed_job_handler
    "--- !ruby/object:Delayed::PerformableMailer \nargs: []\n\nmethod_name: :delayed_job_tracer_test_message\nobject: !ruby/class DelayedJobTracerMailer\n"
  end

  # Timestamp in the format that e-mails expect
  def self.email_timestamp
    Time.now.strftime("%a, %e %b %Y %H:%M:%S %z")
  end

  # Timestamp in the format that MySQL expects
  def self.pg_timestamp
    Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
  end

end
