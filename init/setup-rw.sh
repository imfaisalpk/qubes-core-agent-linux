#!/bin/sh

dev=/dev/xvdb

if mountpoint -q /rw ; then
    # This means /rw is mounted now.
    echo "Checking /rw" >&2

    echo "Private device size management: enlarging $dev" >&2
    if content=$(resize2fs "$dev" 2>&1) ; then
        echo "Private device size management: resize2fs of $dev succeeded" >&2
    else
        echo "Private device size management: resize2fs $dev failed:" >&2
        echo "$content" >&2
    fi

    if ! [ -d /rw/config ] ; then
        echo "Virgin boot of the VM: populating /rw/config" >&2

        mkdir -p /rw/config
        touch /rw/config/rc.local
        cat > /rw/config/rc.local <<EOF
#!/bin/sh

# This script will be executed at every VM startup, you can place your own
# custom commands here. This include overriding some configuration in /etc,
# starting services etc.

# Example for overriding the whole CUPS configuration:
#  rm -rf /etc/cups
#  ln -s /rw/config/cups /etc/cups
#  systemctl --no-block restart cups
EOF
        chmod 755 /rw/config/rc.local

        touch /rw/config/qubes-firewall-user-script
        cat > /rw/config/qubes-firewall-user-script <<EOF
#!/bin/sh

# This script is called in AppVMs after every firewall update (configuration
# change, starting some VM etc). This is good place to write own custom
# firewall rules, in addition to autogenerated ones. Remember that in most cases
# you'll need to insert the rules at the beginning (iptables -I) for it to be
# efective.
EOF
        chmod 755 /rw/config/qubes-firewall-user-script

        touch /rw/config/suspend-module-blacklist
        cat > /rw/config/suspend-module-blacklist <<EOF
# You can list modules here that you want to be unloaded before going to sleep. This
# file is used only if the VM has any PCI device assigned. Modules will be
# automatically re-loaded after resume.
EOF
    fi

    if ! [ -d /rw/usrlocal ] ; then
        if [ -d /usr/local.orig ] ; then
            echo "Virgin boot of the VM: populating /rw/usrlocal from /usr/local.orig" >&2
            cp -af /usr/local.orig /rw/usrlocal
        else
            echo "Virgin boot of the VM: creating /rw/usrlocal" >&2
            mkdir -p /rw/usrlocal
        fi
    fi

    echo "Finished checking /rw" >&2
fi

# Old Qubes versions had symlink /home -> /rw/home; now we use mount --bind
if [ -L /home ]; then
    rm /home
    mkdir /home
fi

if [ ! -e /var/lib/qubes/first-boot-completed ]; then
    touch /var/lib/qubes/first-boot-completed
fi
