
# Class cobbler::config::selinux 
class cobbler::config::selinux {

  selinux::boolean { 'cobbler_can_network_connect':
    ensure     => on,
    persistent => true,
  }

  selinux::boolean { 'cobbler_anon_write':
    ensure     => on,
    persistent => true,
  }

  selinux::boolean { 'cobbler_use_cifs':
    ensure     => on,
    persistent => true,
  }

  selinux::boolean { 'cobbler_use_nfs':
    ensure     => on,
    persistent => true,
  }

  selinux::fcontext { '/var/lib/tftpboot/boot(/.*)?':
    seltype => 'cobbler_var_lib_t',
  }

  selinux::fcontext { '/var/lib/tftpboot/.*':
    seltype => 'public_content_rw_t',
  }

  selinux::boolean { 'httpd_can_network_connect_cobbler':
    ensure     => on,
    persistent => true,
  }

  selinux::boolean { 'httpd_serve_cobbler_files':
    ensure     => on,
    persistent => true,
  }

  selinux::boolean { 'httpd_can_network_connect':
    ensure     => on,
    persistent => true,
  }

  selinux::fcontext { '/var/www/cobbler/images/.*':
    seltype => 'public_content_rw_t' ,
  }

}
