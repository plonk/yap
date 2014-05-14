require 'shellwords'
require 'observer'

class ChildProcess
  include Observable

  attr_reader :pid, :status, :name

  def initialize(cmdline)
    @name = File.basename cmdline.split(/\s+/).first
    @pid = Kernel.spawn(*cmdline.shellsplit)
    @status = 'running'

    Thread.start do
      begin
        _, st = Process.wait2(@pid)
        @status = exit_status(st)
      rescue Errno::ECHILD
        @status = 'no child error'
      end
      changed
      notify_observers
    end
  end

  def finished?
    @status != 'running'
  end

  def kill(signum)
    Process.kill(signum, @pid)
  end

  def exit_status(st)
    case
    when st.signaled?
      "killed by signal #{st.termsig}"
    when st.exited?
      "exited. status=#{st.exitstatus}"
    else
      st.to_s
    end
  end
end
