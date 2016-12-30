Gem::Specification.new do |s|
  s.name        = 'lib2048'
  s.version     = '0.0.1'
  s.date        = '2010-04-28'
  s.summary     = 'board, player, strategies and AI for the 2048 game'
  s.description = ''
  s.authors     = ['Pablo Verges']
  s.email       = 'pablo.verges@gmail.com'
  s.files       = ['lib/lib2048.rb'] + ['array', 'game', 'ai', 'processes'].map { |f| "lib/lib2048/#{f}.rb" }
  s.homepage    = ''
  s.license     = 'Unlicense'
end
