# == Class: cobbler
#
# Class manages cobbler installation and configuraiton
#
# === Parameters
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
# [*ensure*]
#   The state of puppet resources within the module.
#
#   Type: String
#   Values: 'present', 'absent'
#   Default: 'present'
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
# [*service*]
#   Name of the service this modules is responsible to manage.
#
#   Type: String
#   Default: cobblerd
#
# [*service_ensure*]
#   The state of the serivce in the system
#
#   Type: String
#   Values: stopped, running
#   Default: running
#
# [*service_enable*]
#   Whether a service should be enabled to start at boot
#
#   Type: boolean or string
#   Values: true, false, manual, mask
#   Default: true
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
# [*default_cobbler_config*]
#   Hash that contains default configuration options for cobbler. No checks are
#   performed to validate these configuration options. This is a left side hash
#   to be merged with cobbler_config hash to build config_file for cobbler
#
#   Type: Hash
#   Default: check cobbler::params::default_cobbler_config
#
# [*default_modules_config*]
#   Hash that contains default configuration options for cobbler modules.
#   This is a left side hash  to be merged with cobbler_modules_config hash to
#   build config_modules file  for cobbler
#
#   Type: Hash
#   Default: check cobbler::params::default_modules_config
#
# === Authors
#
# Anton Baranov <abaranov@linuxfoundation.org>
class cobbler (
  $cobbler_config         = {},
  $cobbler_modules_config = {},
  $config_file            = $::cobbler::params::config_file,
  String $config_modules  = $::cobbler::params::config_modules,
  $config_path            = $::cobbler::params::config_path,
  Boolean $manage_selinux = false,
  Boolean $manage_python  = true,
  Hash $default_cobbler_config = $::cobbler::params::default_cobbler_config,
  $default_modules_config = $::cobbler::params::default_modules_config,
  Array $dhcp_dns         = [],
  Optional[String] $dhcp_netmask = undef,
  Optional[String] $dhcp_network = undef,
  Optional[String] $dhcp_range_end = undef,
  Optional[String] $dhcp_range_init = undef,
  Optional[String] $dhcp_router = undef,
  $ensure                 = $::cobbler::params::ensure,
  Boolean $install_cobbler_web = true,
  String $cobbler_web_package_ensure = 'installed',
  $package_ensure         = 'installed',
  $service                = $::cobbler::params::service,
  $service_enable         = $::cobbler::params::service_enable,
  $service_ensure         = $::cobbler::params::service_ensure,
) inherits ::cobbler::params {

  # Validation
  validate_re($ensure, ['^present$','^absent$'])
  validate_re($service_ensure,['^stopped$', '^running$'])
  validate_re($package_ensure,[
    '^present$',
    '^installed$',
    '^absent$',
    '^purged$',
    '^held$',
    '^latest$',
  ])

  validate_string(
    $config_file,
  )

  validate_absolute_path(
    $config_path,
  )
  validate_hash(
    $cobbler_config,
    $cobbler_modules_config,
  )

  if is_string($service_enable) {
    validate_re($service_enable, [
      '^manual$',
      '^mask$'
    ])
  } else {
    validate_bool($service_enable)
  }

  anchor{'cobbler::begin':}
  anchor{'cobbler::end':}

  # Merging default cobbler config and cobbler config and pass to
  # cobbler::config class
  $_cobbler_config         = merge(
    $default_cobbler_config,
    $cobbler_config
  )
  $_cobbler_modules_config = merge(
    $default_modules_config,
    $cobbler_modules_config
  )

  $manage_dhcp = Boolean($_cobbler_config['manage_dhcp'])

  if $manage_dhcp and
    !(
      $dhcp_network and
      $dhcp_netmask and
      $dhcp_range_init and
      $dhcp_range_end and
      $dhcp_router and
      !(size($dhcp_dns) == 0)
    ) {
    fail('When the manage_dhcp is enabled, dhcp parameters must to be configured!')
  }

  class { 'cobbler::install':
    manage_dhcp    => $manage_dhcp,
    package_ensure => $package_ensure,
  }

  if $install_cobbler_web {
    class { 'cobbler::install::cobbler_web':
      manage_python              => $manage_python,
      cobbler_web_package_ensure => $cobbler_web_package_ensure,
    }
  }

  class { 'cobbler::config':
    cobbler_config         => $_cobbler_config,
    cobbler_modules_config => $_cobbler_modules_config,
    config_file            => $config_file,
    config_modules         => $config_modules,
    config_path            => $config_path,
    dhcp_dns               => $dhcp_dns,
    dhcp_netmask           => $dhcp_netmask,
    dhcp_network           => $dhcp_network,
    dhcp_range_end         => $dhcp_range_end,
    dhcp_range_init        => $dhcp_range_init,
    dhcp_router            => $dhcp_router,
    ensure                 => $ensure,
    manage_dhcp            => $manage_dhcp,
    manage_selinux         => $manage_selinux,
  }

  class { 'cobbler::service':
    manage_dhcp    => $manage_dhcp,
    service        => $service,
    service_enable => $service_enable,
    service_ensure => $service_ensure,
  }

  Anchor['cobbler::begin']
  -> Class['cobbler::install']
  -> Class['cobbler::config']
  ~> Class['cobbler::service']
  -> Anchor['cobbler::end']
}
