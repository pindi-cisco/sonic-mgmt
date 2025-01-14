#!/usr/bin/env bash
#
# config_service_acls.sh
#
#  Configure service ACLs in such a way that should prevent Ansible
#  server from connecting to running services. This should cause Ansible
#  playbook tasks which remotely connect to thses services to fail (timeout),
#  ensuring service ACLs are implemented correctly and actually dropping
#  unpermitted traffic.
#

# Generate an ACL config file which allows only IP address ranges which
# shouldn't contian the IP address of our Ansible server
cat << EOF > /tmp/testacl.json
{
    "acl": {
        "acl-sets": {
            "acl-set": {
                "SNMP-ACL": {
                    "acl-entries": {
                        "acl-entry": {
                            "1": {
                                "actions": {
                                    "config": {
                                        "forwarding-action": "ACCEPT"
                                    }
                                },
                                "config": {
                                    "sequence-id": 1
                                },
                                "ip": {
                                    "config": {
                                        "protocol": "IP_UDP",
                                        "source-ip-address": "1.1.1.1/32"
                                    }
                                }
                            }
                        }
                    },
                    "config": {
                        "name": "SNMP-ACL"
                    }
                },
                "ssh-only": {
                    "acl-entries": {
                        "acl-entry": {
                            "1": {
                                "actions": {
                                    "config": {
                                        "forwarding-action": "ACCEPT"
                                    }
                                },
                                "config": {
                                    "sequence-id": 1
                                },
                                "ip": {
                                    "config": {
                                        "protocol": "IP_TCP",
                                        "source-ip-address": "1.1.1.1/32"
                                    }
                                }
                            }
                        }
                    },
                    "config": {
                        "name": "ssh-only"
                    }
                },
                "ntp-acl": {
                    "acl-entries": {
                        "acl-entry": {
                            "1": {
                                "actions": {
                                    "config": {
                                        "forwarding-action": "ACCEPT"
                                    }
                                },
                                "config": {
                                    "sequence-id": 1
                                },
                                "ip": {
                                    "config": {
                                        "protocol": "IP_TCP",
                                        "source-ip-address": "1.1.1.1/32"
                                    }
                                }
                            }
                        }
                    },
                    "config": {
                        "name": "ntp-acl"
                    }
                }
            }
        }
    }
}
EOF

# Install the new service ACLs
acl-loader update full /tmp/testacl.json

# log control plane acl after install
logger -t cacltest "added cacl test rules"
iptables -nL | logger -t cacltest

# Sleep to allow Ansible playbook ample time to attempt to connect and timeout
sleep 180

# Delete the test ACL config file
rm -rf /tmp/testacl.json

# IMPORTANT! Delete the ACLs we just added in order to restore connectivity
acl-loader delete

# log control plane acl after deletion
logger -t cacltest "deleted cacl test rules"
iptables -nL | logger -t cacltest
