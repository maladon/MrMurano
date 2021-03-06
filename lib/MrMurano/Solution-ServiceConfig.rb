require 'terminal-table'

module MrMurano
  # …/serviceconfig
  class ServiceConfig < SolutionBase
    def initialize
      super
      @uriparts << 'serviceconfig'
    end

    def list
      get()[:items]
    end
    def fetch(id)
      get('/' + id.to_s)
    end

    def scid_for_name(name)
      name = name.to_s unless name.kind_of? String
      scr = list().select{|i| i[:service] == name}.first
      scid = scr[:id]
    end

    def scid
      return @scid unless @scid.nil?
      @scid = scid_for_name(@serviceName)
    end
  end

  class SC_Device < ServiceConfig
    def initialize
      super
      @serviceName = 'device'
    end

    def assignTriggers(products)
      details = fetch(scid)
      products = [products] unless products.kind_of? Array
      details[:triggers] = {:pid=>products, :vendor=>products}

      put('/'+scid, details)
    end

    def showTriggers
      details = fetch(scid)

      return [] if details[:triggers].nil?
      details[:triggers][:pid]
    end

  end
end

command 'assign list' do |c|
  c.syntax = 'mr assign list [options]'
  c.description = 'List the products that are assigned'
  c.option '--idonly', 'Only return the ids'
  c.action do |args, options|
    sol = MrMurano::SC_Device.new

    trigs = sol.showTriggers()
    if options.idonly or $cfg['business.id'].nil? then
      say trigs.join(' ')
    else
      acc = MrMurano::Account.new
      products = acc.products
      products.select!{|p| trigs.include? p[:modelId] }
      if products.empty? then
        say trigs.join(' ')
      else
        busy = products.map{|r| [r[:label], r[:type], r[:pid], r[:modelId]]}
        table = Terminal::Table.new :rows => busy, :headings => ['Label', 'Type', 'PID', 'ModelID']
        say table
      end
    end
  end
end
alias_command :assign, 'assign list'

command 'assign set' do |c|
  c.syntax = 'mr assign set [product]'
  c.description = 'Assign a product to a eventhandler'

  c.action do |args, options|
    sol = MrMurano::SC_Device.new

    prname = args.shift
    if prname.nil? then
      prid = $cfg['product.id']
    else
      acc = MrMurano::Account.new
      products = acc.products
      products.select!{|p|
        p[:label] == prname or p[:modelId] == prname or p[:pid] == prname
      }
      prid = products.map{|p| p[:modelId]}
    end
    raise "No product ID!" if prid.nil?
    say "Assigning #{prid} to solution" if $cfg['tool.verbose']
    sol.assignTriggers(prid) unless $cfg['tool.dry']
  end

end

#  vim: set ai et sw=2 ts=2 :
