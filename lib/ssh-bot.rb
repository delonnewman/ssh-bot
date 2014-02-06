require 'pty'

class SSHBot
  def initialize(user, host)
    @user   = user
    @host   = host
    @record = []
  end

  def eval(macro)
    PTY.getpty("ssh #{USER}@#{HOST}") do |input, output, pid|
      buffer = ''
      line   = ''
      while c = input.getc
        print c
        buffer << c
        line   << c

        if c == "\n"
          log(line)
          line = ''
          @record << line
        end
        
        macro.each do |exp|
          if eval_exp(exp, buffer, output, input, line)
            p exp
            log(exp.inspect)
            buffer = ''
          end
        end
      end
    end
  end

  private

  def log(line)
    File.open('ssh-bot.log', 'a') { |f| f.write("#{DateTime.now}: #{line}") }
  end

  def eval_exp(exp, buffer, out, input, line)
    pat    = exp[:expect] || raise("A pattern defined with 'expect' is required")
    resp   = exp[:send]
    file   = exp[:save_record_to]
    fn     = exp[:with_record]

    if m = buffer.match(pat)
      if resp.respond_to?(:call)
        out.write("#{resp.call(line, m)}\r")
      else
        out.write("#{resp}\r")
      end

      fn[@record] if fn

      File.open(file, 'w') { |f| f.write(@record.join('')) } if file

      true
    else
      false
    end
  end
end
