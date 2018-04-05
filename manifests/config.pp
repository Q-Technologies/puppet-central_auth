
class central_auth::config (
  # Class parameters are populated from External(hiera)/Defaults/Fail
  String $default_domain,
  String $admin_server               = hiera( 'central_auth::config::default_domain' ),
  String $default_realm              = hiera( 'central_auth::config::default_domain' ),
  Boolean $dns_lookup_kdc            = true,
  Boolean $dns_lookup_realm          = true,
  Boolean $forwardable               = true,
  String $directory_type             = 'ad',
  String $ticket_lifetime            = '2d',
  String $renew_lifetime             = '30d',

  Integer $ldap_idmap_range_size     = 200000,
  Boolean $ldap_id_mapping           = false,
  Boolean $cache_credentials         = true,
  Boolean $case_sensitive            = false,
  String $override_shell             = '/bin/bash',
  String $override_homedir           = '/home/%u',

  Integer $sssd_debug_level          = 0,
  String $ldap_uri                   = '',
  String $user_ou_path               = '',
  String $group_ou_path              = '',
  String $bind_user                  = '',
  String $bind_pass                  = hiera( 'central_auth::join_ad::domain_pass','' ),

  String $smb_template               = 'central_auth/smb.conf',
) {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  if ( $::osfamily == "Suse" and ($::operatingsystemmajrelease + 0) < 12 )
    or ( $facts['os']['name'] == 'Ubuntu' and ($::operatingsystemmajrelease + 0) < 13 ) {
    if $directory_type == "ad" {
      $sssd_template = 'central_auth/sssd.conf.AD_LDAP'
    } elsif $directory_type == "openldap" {
      $sssd_template = 'central_auth/sssd.conf.OPENLDAP'
    } else{
        fail("Unknown directory type: ${directory_type}")
    }
    #$krb5_template = 'central_auth/krb5.conf.LDAP'
    $krb5_template = 'central_auth/krb5.conf.AD'
  } else {
    $sssd_template = 'central_auth/sssd.conf.AD'
    $krb5_template = 'central_auth/krb5.conf.AD'
  }


  if $central_auth::enable_sssd {

    if $directory_type == "ad" {
      # When connecting to AD, utilise Kerberos and set up Samba client
      file { '/etc/krb5.conf':
        ensure  => file,
        content => epp($krb5_template, {
                                         admin_server     => $admin_server,
                                         default_domain   => $default_domain,
                                         default_realm    => $default_realm,
                                         dns_lookup_realm => $dns_lookup_realm,
                                         dns_lookup_kdc   => $dns_lookup_kdc,
                                         ticket_lifetime  => $ticket_lifetime,
                                         renew_lifetime   => $renew_lifetime,
                                         forwardable      => $forwardable,
                                       } ),
        notify  => Service['sssd'],
      }

      file { '/etc/samba':
        ensure  => directory,
      }

      $dr_arr = split($default_realm, '\.')
      $addomain = $dr_arr[0]
      file { '/etc/samba/smb.conf':
        ensure  => file,
        content => epp($smb_template, { default_realm => $default_realm, addomain => $addomain }),
      }

    }

    file { '/etc/sssd':
      ensure => directory,
      mode   => '0700',
    }
    
    $dc1 = split($default_domain, '\.')
    $dc2 = join($dc1,",DC=")
    $dc = "DC=$dc2"

    exec { "clean_sssd_cache.sh":
       command => "clean_sssd_cache.sh",
       path => "/usr/local/sbin/:/bin",
       subscribe => File[$clean_sssd_cache_script],
       refreshonly => true,
    }

    file { '/etc/sssd/sssd.conf':
      ensure  => file,
      content => epp($sssd_template, {
                                       default_domain        => $default_domain,
                                       admin_server          => $admin_server,
                                       ldap_idmap_range_size => $ldap_idmap_range_size,
                                       ldap_id_mapping       => $ldap_id_mapping,
                                       cache_credentials     => $cache_credentials,
                                       case_sensitive        => $case_sensitive,
                                       override_shell        => $override_shell,
                                       override_homedir      => $override_homedir,
                                       debug_level           => $sssd_debug_level,
                                       ldap_uri              => $ldap_uri,
                                       user_ou_path          => $user_ou_path,
                                       group_ou_path         => $group_ou_path,
                                       bind_user             => $bind_user,
                                       bind_pass             => $bind_pass,
                                       dc                    => $dc,
                                     } ),
      mode    => '0600',
      notify  => Exec['clean_sssd_cache.sh'],
    }

    if $::osfamily == "RedHat" {
      file { '/etc/oddjobd.conf.d/oddjobd-mkhomedir.conf':
        ensure => file,
        source => 'puppet:///modules/central_auth/oddjobd-mkhomedir.conf',
        notify => Service['oddjobd'],
      }
    }

    file { '/etc/nsswitch.conf':
      ensure  => file,
      content  => epp('central_auth/nsswitch.conf'),
      require => File['/etc/sssd/sssd.conf'],
    }

    # Set the authconfig settings to reflect what we are setting - even though authconfig is not being used
    if $::osfamily == "RedHat" {
      augeas { "sysconfig-authconfig-sssd":
        context => "/files/etc/sysconfig/authconfig",
        changes => [
          "set USEMKHOMEDIR yes",
          "set USESSSDAUTH yes",
          "set USESSSD yes",
        ],
      }
    }
  }

}
