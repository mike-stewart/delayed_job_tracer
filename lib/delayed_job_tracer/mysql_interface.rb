require 'mysql2'

class MySQLInterface
  
  # Connects to the db and submits a query
  def self.query(sql)
    c = DelayedJobTracer.config['database']
    d = Mysql2::Client.new(:host => c['ip'], :database => c['database'], :username => c['user'], :password => c['password'])
    d.query(sql)
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
    "INSERT INTO delayed_jobs (`handler`, `run_at`, `created_at`, `updated_at`) VALUES 
      ('#{delayed_job_handler}', '#{mysql_timestamp}', '#{mysql_timestamp}', '#{mysql_timestamp}')"
  end
  
  # SQL helper method for inserting a delayed_job record
  def self.delayed_job_handler
    "--- !ruby/struct:Delayed::PerformableMailer 
object: !ruby/class DelayedJobTracerMailer
method_name: :delayed_job_tracer_test_message
args: []"
  end
  
  # Timestamp in the format that e-mails expect
  def self.email_timestamp
    Time.now.strftime("%a, %e %b %Y %H:%M:%S %z")
  end
  
  # Timestamp in the format that MySQL expects
  def self.mysql_timestamp
    Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")
  end
  
end