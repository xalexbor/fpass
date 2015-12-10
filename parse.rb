#!/usr/bin/env ruby

class Parser
  def initialize
    @new = ['n','-n','new']                             # Create
    @get = ['g','-g','get']                             # Read
    @upd = ['u','-u','upd','edit','e','-e','update']    # Update
    @del = ['d','-d','del','delete','r','-r','remove']  # Delete

    # Set options, like a -p - password
    @pass = ['-p','p'] 
    @help = ['-h','h','help']
    @opts = {}
  end

  def getcmd
    # return (ARGV & @new + @get + @upd + @del)[0]
    c = (ARGV & @new + @get + @upd + @del)[0]
    case c
      when /(get)|(-g)|(g)/
        return 'get'
      when /(new)|(-n)|(n)/
        return 'new'
      when /\b(upd|-u|u|edit|-e|e)\b/
        return 'upd'
      when /\b(del|-d|d|delete|r|-r|remove)\b/
        return 'del'
    end
  end

  def getdata
    h={}
    others=[]
    (ARGV-(ARGV & @new+@get+@upd+@del+@help+@pass)-(self.getprms.values)).each do |d|
      begin
        h.merge!(Hash[*d.split(":")])
      rescue ArgumentError => e
        others.push(d)
      end
    end

    return {others[0] => h},others
  end

  def getprms
    ARGV.each do |i|
      @opts[:help] = true if @help.include?(i)
      @opts[:pass] = ARGV[ARGV.index(i)+1] if @pass.include?(i)
    end
    return @opts
  end

end

class Controller
  def initialize(data,path)
    @data = data
    @path = path
  end

  def new(data)
    write(data)
  end

  def update(data)
    write(data)
  end

  def delete
    puts "delete"
  end

  def get
    return self.read
  end

  def check
    if File.exist?(@path)
      return 1
    else
      File.open(@path,'w')
      return 1
    end
  end

  def write(data)
    begin
      if check
        f = File.open(@path,'w')
        f.write data
        f.close
      end
    rescue => error
      puts "WRITE: "+error.backtrace.join("\n")
    end
  end

  def read
    if check
      f = File.open(@path,'r')
      return f.read
    end
  end
end
