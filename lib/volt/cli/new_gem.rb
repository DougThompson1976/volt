# Creates a new "volt" gem, which can be used to easily repackage
# components.

class NewGem  
  def initialize(thor, name, options)
    @thor = thor
    @name = "volt-" + name.chomp("/") # remove trailing slash if present
    @options = options
    @namespaced_path = @name.tr('-', '/')
    @opts = gem_options
    @target = File.join(Dir.pwd, @name)
    
    copy_files
    copy_options
  end
  
  def copy_files
    @thor.directory("newgem/app", File.join("#{@target}", "app"))
    copy("newgem/Gemfile.tt", "Gemfile")
    copy("newgem/Rakefile.tt", "Rakefile")
    copy("newgem/README.md.tt", "README.md")
    copy("newgem/gitignore.tt", ".gitignore")
    copy("newgem/newgem.gemspec.tt", "#{@name}.gemspec")
    copy("newgem/lib/newgem.rb.tt", "lib/#{@namespaced_path}.rb")
    copy("newgem/lib/newgem/version.rb.tt", "lib/#{@namespaced_path}/version.rb")
  end
    
  def copy_options
    if @options[:bin]
      copy("newgem/bin/newgem.tt", "bin/#{@name}")
    end
    case @options[:test]
    when 'rspec'
      copy("newgem/rspec.tt", ".rspec")
      copy("newgem/spec/spec_helper.rb.tt", "spec/spec_helper.rb")
      copy("newgem/spec/newgem_spec.rb.tt", "spec/#{@namespaced_path}_spec.rb")
    when 'minitest'
      copy("newgem/test/minitest_helper.rb.tt", "test/minitest_helper.rb")
      copy("newgem/test/test_newgem.rb.tt", "test/test_#{@namespaced_path}.rb")
    end
    puts "Initializing git repo in #{@target}"
    Dir.chdir(@target) { `git init`; `git add .` }

    if @options[:edit]
      run("#{@options["edit"]} \"#{gemspec_dest}\"")  # Open gemspec in editor
    end
  end
  
  private
    def copy(from, to)
      @thor.template(File.join(from), File.join(@target, to), @opts)
    end
  
    def gem_options
      constant_name = get_constant_name
      constant_array = constant_name.split('::')
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp
  
      opts = {
        :name            => @name,
        :namespaced_path => @namespaced_path,
        :constant_name   => constant_name,
        :constant_array  => constant_array,
        :author          => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email           => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
        :test            => @options[:test],
        :volt_version_base => volt_version_base
      }
    
      return opts
    end
    
    def volt_version_base
      version_path = File.join(File.dirname(__FILE__), '../../../VERSION')
      File.read(version_path).split('.').tap {|v| v[v.size-1] = 0 }.join('.')
    end
    
    def get_constant_name
      constant_name = @name.split('_').map{|p| p[0..0].upcase + p[1..-1] }.join
      constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
      
      return constant_name
    end
  
end