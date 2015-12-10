#!/usr/bin/env ruby

require './parse.rb'
require 'json'
require 'openssl'

prs = Parser.new

data,getting = prs.getdata
params = prs.getprms

help =  "Personal CLI passwords manager\n"+
        "\tapp.rb <COMMAND> [grand key] [parameters (key:value)] [options]\n"+
        "\t\tget, -g, g\tget info about Grand Key. Puts all keys if Grand Key not selected.\n"+
        "\t\tnew, -n, n\tcreate a new record into db file.\n"+
        "\t\tupd, -u, u\tupdate a selected record.\n"+
        "\t\tdel, -d, d\tdelete record.\n"

# Encrypting some 
def encrypt(data,pass) 
  salt = "8 octets"
  encrypter = OpenSSL::Cipher.new 'AES-256-CBC'
  encrypter.encrypt
  encrypter.pkcs5_keyivgen pass, salt
  encrypted = encrypter.update data
  encrypted << encrypter.final
  return encrypted
end

# Decrypting some
def decrypt(encrypted,pass)
  salt = "8 octets"
  decrypter = OpenSSL::Cipher.new 'AES-256-CBC'
  decrypter.decrypt
  decrypter.pkcs5_keyivgen pass, salt
  plain = decrypter.update encrypted
  plain << decrypter.final
  return plain
end

def getcfg                                                      # Read config file
  cfg = {}                                                      # config parse to hash 
  f = File.open('.fpassrc','r')                                 # Specify config file 
  f.read.split("\n").each do |l|            
    cfg.merge!(Hash[*l.split("=")])         
  end                                       
  return cfg                                
end                                                             # End of read config file

 controller = Controller.new(data.to_json,getcfg["data file"])  # Initialize main connection to file
                                                                # Convert inputed data to JSON format 
                                                                # Read configuration from file, read data from file, write data to file


def printf(hash)                                                # Just print for hash
  hash.each do |k,v|
    puts "#{k}".ljust(12) +":".ljust(2)+"#{v}"
  end
end

def gethash(pass,data)                                          # Getting thash from file and parse
  if pass                                                       # We crypting data if params enabled
    begin
      return thash = JSON.parse(decrypt(data,pass))             # Decrypting data
    rescue OpenSSL::Cipher::CipherError => e                    # Get CipherError if password wrong
      return "Wrong Password!"
    rescue ArgumentError => e                                   # Get ArgumentError if data file is empty
      return []
    end
  else
    begin
      return thash = JSON.parse(data)               
    rescue JSON::ParserError => e                               # Get ParserError if data file is empty
      return []
    end
  end
end                                         

def savehash(data,pass)                                         # Save hash
  if pass
    return encrypt(data.to_json,pass)                           # Saving with encrypt
  else
    return data.to_json                                         # Saving without encrypt
  end
end 


if getcfg["crypt"] == "yes"                                     # Check for config
  if params[:pass]
    thash = gethash(params[:pass],controller.get)               # Getting thash from file, decrypt/encrypt
  else
    puts "You need spicify a password!"
  end
else
  if getcfg["crypt"] == "no"
    thash = gethash(params[:pass],controller.get)               # Getting thash from file, without encrypting
  else
    puts "What you want?"
  end 
end


case prs.getcmd                                                 # Parse command from dictionary

    when 'get'
      if thash 
        gk = (thash.keys&getting)[0]
        getting.delete(gk)
        parameter = getting[0]
        if gk 
          if parameter
            if thash[gk].keys.include?(parameter)
              puts thash[gk][parameter]
            else
              puts "There is no parameter '#{parameter}'"
            end
          else
            printf thash[gk]
          end
        else
          printf thash
        end
      end

    when "new"
      if data[nil]
        puts "No data!"
      else
        begin
          thash[data.keys[0]]=data.values[0]
          controller.new(savehash(thash,params[:pass]))
        rescue TypeError => e
          controller.new(savehash(data,params[:pass]))
        end
      end

    when 'upd'
        gk = (thash.keys&getting)[0]
        sk = data[gk].keys[0]
        thash[gk][sk] = data[gk][sk]
        controller.update(encrypt(thash.to_json,params[:params]))

    when 'del'
        gk = (thash.keys&getting)[0]
        thash.delete(gk)
        controller.update(savehash(thash,params[:pass]))

    else
      if params[:help]
        print help
      else
        puts "Unknown command"
      end

end # End of case
