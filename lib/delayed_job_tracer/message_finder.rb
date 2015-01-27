require 'rubygems'
require 'net/imap'
require 'mail'
require 'yaml'

class MessageFinder

  def self.found_recent_message?
    c = DelayedJobTracer.config['monitor']

    server   = c['server']
    port     = c['port'] || 143
    ssl      = c['ssl'] || false
    username = c['username']
    password = c['password']
    folder   = c['folder']

    imap = Net::IMAP.new server, port, ssl
    imap.login username, password
    imap.select folder
    uids = imap.search(["UNSEEN"])

    emails = []
    times = []

    uids.each do |uid|
      mdata = imap.fetch(uid, 'RFC822')[0].attr['RFC822']
      mail = Mail.new mdata
      emails << {:mdata => mdata, :mail => mail, :uid => uid}
    end

    emails.each do |email|
      # Collects the dates of unread messages
      times << email[:mail].date
      # Marks unread messages as read
      imap.store email[:uid], "+FLAGS", [:Seen]
    end

    imap.disconnect

    # Just checks to see if there was at least one recent unread message
    return true unless times.blank?
  end

end
