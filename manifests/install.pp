# == Class cobbler::install
#
# Installs packages required to deploy cobbler
#
# === Parameters
#
# [*package*]
#   The package name or array of packages that provides cobbler.
#
#   Type: String or Array
#   Default: check cobbler::params::package
#
# [*package_ensure*]
#   The state of the package.
#
#   Type: String
#   Values: present, installed, absent, purged, held, latest
#   Default: installed
#
# == Authors
#
# Anton Baranov <abaranov@linuxfoundation.org>
class cobbler::install (
  $install_cobbler_web,
  $install_dhcp,
  $package_cobbler_web,
  $package_dhcp,
  $package_ensure,
  $package,
){
  # Validation
  validate_re($package_ensure,[
    '^present$',
    '^installed$',
    '^absent$',
    '^purged$',
    '^held$',
    '^latest$',
  ])

  if is_array($package) {
    validate_array($package)
  } else {
    validate_string($package)
  }

  package { $package:
    ensure => $package_ensure,
  }

  if $install_cobbler_web {
    package { $package_cobbler_web:
      ensure => $package_ensure,
    }

    # Force use of Django 1.9. New versions are not supported.
    class { 'python':
      version => 'system',
      pip     => 'present',
    }

    python::pip { 'django':
      ensure  => '1.9',
      require => Package[$package],
      notify  => [
        Service['cobblerd'],
        Service['httpd'],
      ]
    }
  }

  if $install_dhcp {
    package { $package_dhcp:
      ensure => $package_ensure,
    }
  }
}
