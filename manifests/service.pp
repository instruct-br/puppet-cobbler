# == Class cobbler:service
#
# Manages cobbler service
#
# === Parameters
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
# == Authors
#
# Anton Baranov <abaranov@linuxfoundation.org>
class cobbler::service (
  $install_dhcp,
  $service_dhcp,
  $service_enable,
  $service_ensure,
  $service,
){
  # Validation
  if is_array($service) {
    validate_array($service)
  } else {
    validate_string($service)
  }

  validate_re($service_ensure,['^stopped$', '^running$'])

  if is_string($service_enable) {
    validate_re($service_enable, [
      '^manual$',
      '^mask$'
    ])
  } else {
    validate_bool($service_enable)
  }

  service {$service:
    ensure => $service_ensure,
    enable => $service_enable,
  }

  # TFTP is an indirect service
  service { 'tftp':
    ensure => 'running',
  }

  if $install_dhcp {
    service { $service_dhcp:
      ensure  => $service_ensure,
      enable  => $service_enable,
      require => Exec['sync_and_get_loaders'],
    }
  }

  # Run Cobbler sync and get-loaders every service restart
  exec { 'sync_and_get_loaders':
    command     => '/bin/sleep 5 && /bin/cobbler sync && /bin/cobbler get-loaders',
    refreshonly => true,
    subscribe   => Service['cobblerd'],
  }
}
