require 'rubygems'
require 'commander/import'
require 'MrMurano'
require 'tempfile'

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Some kludgery to work around commander.  Likely a better way to do this.
program :version, MrMurano::VERSION
program :description, %{Manage a Solution in Exosite's Murano}
command(:nop){ |c| c.action {|a,o|} }
default_command :nop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

RSpec.describe MrMurano::Passwords, "#pwd" do
  it "Creates a file " do
    tmpfile = Dir.tmpdir + '/pwtest' # This way because Tempfile.new creates.
    begin
      pwd = MrMurano::Passwords.new( tmpfile )
      pwd.save

      expect( FileTest.exists?(tmpfile) )
    ensure
      File.unlink(tmpfile) if File.exists? tmpfile
    end
  end

  it "Creates a file in a directory that doesn't exist." do
    tmpfile = Dir.tmpdir + '/deeper/pwtest' # This way because Tempfile.new creates.
    begin
      pwd = MrMurano::Passwords.new( tmpfile )
      pwd.save

      expect( FileTest.exists?(tmpfile) )
    ensure
      File.unlink(tmpfile) if File.exists? tmpfile
    end
  end

  it "Loads a file" do
    Tempfile.open('test') do |tf|
      tf << %{---
this.is.a.host:
  user: password
}
      tf.close

      pwd = MrMurano::Passwords.new( tf.path )
      pwd.load
      ps = pwd.get('this.is.a.host', 'user')
      expect(ps).to eq('password')
    end
  end

  it "Saves a file" do
    Tempfile.open('pstest') do |tf|
      tf.close

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.set('this.is.a.host', 'user3', 'passwords4')
      pwd.save

      File.open(tf.path) do |io|
        data = io.read
        expect(data).to eq(%{---
this.is.a.host:
  user3: passwords4
})
      end
    end
  end

  it "Writes multiple hosts" do
    Tempfile.open('pwtest') do |tf|
      tf.close

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.set('this.is.a.host', 'user3', 'passwords4')
      pwd.save
      pwd = nil

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.load
      ps = pwd.get('this.is.a.host', 'user3')
      expect(ps).to eq('passwords4')
      pwd = nil

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.load
      pwd.set('another.host', 'user9', 'passwords2')
      pwd.save
      pwd = nil

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.load
      ps = pwd.get('this.is.a.host', 'user3')
      expect(ps).to eq('passwords4')
      ps = pwd.get('another.host', 'user9')
      expect(ps).to eq('passwords2')
      pwd = nil

    end
  end

  it "Write multiple users to same host" do
    Tempfile.open('pwstest') do |tf|
      tf.close

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.set('this.is.a.host', 'user3', 'passwords4')
      pwd.save
      pwd = nil

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.load
      pwd.set('this.is.a.host', 'user9', 'passwords2')
      pwd.save
      pwd = nil

      pwd = MrMurano::Passwords.new(tf.path)
      pwd.load
      ps = pwd.get('this.is.a.host', 'user3')
      expect(ps).to eq('passwords4')
      ps = pwd.get('this.is.a.host', 'user9')
      expect(ps).to eq('passwords2')
      pwd = nil

    end
  end


end

#  vim: set ai et sw=2 ts=2 :
