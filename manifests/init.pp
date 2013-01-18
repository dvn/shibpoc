stage { 'repos':    before => Stage['packages'] }

stage { 'packages': before => Stage['users'] }

stage { 'users':    before => Stage['main'] }

stage { 'last':
  require => Stage['main']
}

class {
    'repos':    stage => repos;
    'packages': stage => packages;
    'users':    stage => users;
    'shibpoc':  stage => main;
    'last':     stage => last;
}
