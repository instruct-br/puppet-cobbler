# Profile to install and manage Cobbler

require epel

$dhcp_netmask           = '255.255.255.0'
$dhcp_network           = '172.22.0.0'
$dhcp_range_end         = '172.22.0.200'
$dhcp_range_init        = '172.22.0.100'
$dhcp_router            = '172.22.0.114'

class { 'cobbler':
  cobbler_config  => {
    default_password_crypted => 'xuxu',
    manage_dhcp              => 1,
    next_server              => $dhcp_router,
    server                   => $dhcp_router,
  },
  dhcp_network    => $dhcp_network,
  dhcp_netmask    => $dhcp_netmask,
  dhcp_range_init => $dhcp_range_init,
  dhcp_range_end  => $dhcp_range_end,
  dhcp_router     => $dhcp_router,
  manage_selinux  => true,
}
