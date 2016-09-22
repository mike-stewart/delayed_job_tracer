class DelayedJobTracerMailer < ActionMailer::Base

  def delayed_job_tracer_test_message
    config  = YAML.load(ERB.new(File.read(Rails.root.join('config', 'delayed_job_tracer_config.yml'))).result)
    to      = config['monitor']['username']
    from    = ActionMailer::Base.smtp_settings[:user_name]
    subject = "[#{config['monitor']['subject']}] Test message sent at: #{Time.zone.now}"
    message = 'This is a test message to ensure messages are being delivered successfully via delayed_job.'
    mail(:to => to, :from => from, :subject => subject) do |format|
      format.text { render :text => message }
    end
  end
  
  def self.enqueue_delayed_job_tracer_test_message
    delay.delayed_job_tracer_test_message
  end
  
end
