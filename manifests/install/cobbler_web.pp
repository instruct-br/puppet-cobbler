# Class cobbler::install::cobbler_web
class cobbler::install::cobbler_web (
  String $cobbler_web_package_ensure,
  Boolean $manage_python,
) {

  package { 'cobbler-web':
    ensure => $cobbler_web_package_ensure,
  }

  if $manage_python {

    class { 'python':
      version => 'system',
      pip     => 'present',
    }

  }

  # Force use of Django 1.9. New versions are not supported.
  python::pip { 'django':
    ensure  => '1.9',
  }

}
