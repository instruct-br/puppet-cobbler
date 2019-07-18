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
  Boolean $manage_dhcp,
  String $package_ensure,
) {

  $cobbler_dependencies = ['debmirror', 'fence-agents', 'pykickstart',
                            'syslinux-tftpboot', 'syslinux', ]

  package { $cobbler_dependencies:
    ensure => installed,
  }

  package { 'cobbler':
    ensure => $package_ensure,
  }

  if $manage_dhcp {

    package { 'dhcp':
      ensure => installed,
    }

  }

}
