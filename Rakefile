desc 'compile html'

task :html do
  Dir['haml/*\.haml'].each do |file|
    name = File.basename(file, '.haml')
    sh "haml haml/#{name}.haml html/#{name}.html"
  end
end

desc 'compile css'
task :css do
  sh "compass compile" 
end

desc 'compile javascript'
task :js do
  sh "coffee -o javascripts/ -c coffeescripts/slide-js.coffee"
end

desc 'watch javascripts'
task :wjs do
  sh "coffee -o javascripts/ -w -c coffeescripts/slide-js.coffee"
end

desc 'watch css'
task :wcss do
  sh "compass watch"
end


task :default => [:html, :css, :js]