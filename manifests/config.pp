# == Class cobbler::config
#
# Manages configuration files for cobbler
#
# === Parameters
#
# [*ensure*]
#   The state of puppet resources within the module.
#
#   Type: String
#   Values: 'present', 'absent'
#   Default: 'present'
#
# [*cobbler_config*]
#   Hash of cobbler settings options. This hash is merged with the
#   default_cobbler_config hash from params class. All this options go to the
#   file defined with config_file parameter. There are no checks (yet?) done to
#   verify options passed with that hash
#
#   Type: Hash
#   Default: {}
#
# [*cobbler_modules_config*]
#   Hash of cobbler modules configuration. This hash is
#   merged with the default_modules_config hash from params class.
#   Exapmple:
#     cobbler_modules_config => {
#       section1            => {
#         option1 => value1,
#         option2 => [ value1, value2],
#       },
#       section2.subsection => {
#         option3 => value3,
#       }
#     }
#
#   Type: Hash
#   Default: {}
#
# [*config_path*]
#   The absolute path where cobbler configuration files reside. This to prepend
#   to config_file and config_modules options to build full paths to setttings
#   and modules.conf files.
#
#   Type: String
#   Default: /etc/cobbler
#
# [*config_file*]
#   The title of main cobbler configuration file. The full path to that file is
#   build by prepending config_file with config_path parameters
#
#   Type: String
#   Default: settings
#
# [*config_modules*]
#   The title of cobbler modules configuration file. The full path to that file
#   is build by prepending config_modules with config_path parameters
#
#   Type: String
#   Default: modules.conf
#
# === Authors
#
# Anton Baranov <abaranov@linuxfoundation.org>
class cobbler::config(
  $cobbler_config,
  $cobbler_modules_config,
  $config_file,
  $config_modules,
  $config_path,
  $dhcp_dns,
  $dhcp_netmask,
  $dhcp_network,
  $dhcp_range_end,
  $dhcp_range_init,
  $dhcp_router,
  $ensure,
  Boolean $manage_dhcp,
  Boolean $manage_selinux,
){
  # Validation
  validate_absolute_path(
    $config_path,
  )
  validate_hash(
    $cobbler_config,
    $cobbler_modules_config,
  )
  validate_re($ensure, ['^present$','^absent$'])

  validate_string(
    $config_file,
    $config_modules
  )

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  $_dir_ensure = $ensure ? {
    'present' => 'directory',
    default   => 'absent',
  }
  file {$config_path:
    ensure => $_dir_ensure,
  }
  # Just convert to yaml
  file {"${config_path}/${config_file}":
    ensure  => $ensure,
    content => template ('cobbler/yaml.erb')
  }

  cobbler::config::ini {'modules.conf':
    ensure      => $ensure,
    config_file => "${config_path}/${config_modules}",
    options     => $cobbler_modules_config,
  }

  # Configure SELinux
  if $manage_selinux {
    include cobbler::config::selinux

    Class['cobbler::config::selinux']
    -> Exec['sync_and_get_loaders']
  }

  # Configure files
  augeas { '/etc/xinetd.d/tftp':
    context => '/files/etc/xinetd.d/tftp/service',
    changes => [
      'set disable no',
    ],
    notify  => Service['cobblerd'],
  }

  file_line { 'Comment dists debmirror':
    ensure             => present,
    path               => '/etc/debmirror.conf',
    line               => '#@dists="sid";',
    match              => '^@dists="sid".*',
    append_on_no_match => false,
  }

  file_line { 'Comment arches debmirror':
    ensure             => present,
    path               => '/etc/debmirror.conf',
    line               => '#@arches="i386";',
    match              => '^@arches=.*',
    append_on_no_match => false,
  }

  if $manage_dhcp {
    file { '/etc/cobbler/dhcp.template':
      ensure  => file,
      content => epp('cobbler/dhcp.epp', {
        dhcp_dns        => $dhcp_dns,
        dhcp_netmask    => $dhcp_netmask,
        dhcp_network    => $dhcp_network,
        dhcp_range_end  => $dhcp_range_end,
        dhcp_range_init => $dhcp_range_init,
        dhcp_router     => $dhcp_router,
      })
    }
  }

}
