.. -*- coding: utf-8 -*-

.. _lxc-1-0-security-features:

*****************
Security features
*****************

When talking about container security most people either consider containers as inherently insecure or inherently secure. The reality isn’t so black and white and LXC supports a variety of technologies to mitigate most security concerns.

One thing to clarify right from the start is that you won’t hear any of the LXC maintainers tell you that LXC is secure so long as you use privileged containers. However, at least in Ubuntu, our default containers ship with what we think is a pretty good configuration of both the cgroup access and an extensive apparmor profile which prevents all attacks that we are aware of.

Below I’ll be covering the various technologies LXC supports to let you restrict what a container may do. Just keep in mind that unless you are using unprivileged containers, you shouldn’t give root access to a container to someone whom you’d mind having root access to your host.

Capabilities
============

The first security feature which was added to LXC was Linux capabilities support. With that feature you can set a list of capabilities that you want LXC to drop before starting the container or a full list of capabilities to retain (all others will be dropped).

The two relevant configurations options are:

- ``lxc.cap.drop``
- ``lxc.cap.keep``

Both are lists of capability names as listed in `capabilities(7)`_.

.. _capabilities(7): http://man7.org/linux/man-pages/man7/capabilities.7.html

This may sound like a great way to make containers safe and for very specific cases it may be, however if running a system container, you’ll soon notice that dropping sys_admin and net_admin isn’t very practical and short of dropping those, you won’t make your container much safer (as root in the container will be able to re-grant itself any dropped capability).

In Ubuntu we use ``lxc.cap.drop`` to drop ``sys_module``, ``mac_admin``, ``mac_override``, ``sys_time`` which prevent some known problems at container boot time.

Control groups
==============

Control groups are interesting because they achieve multiple things which while interconnected are still pretty different:

- Resource bean counting
- Resource quotas
- Access restrictions

The first two aren’t really security related, though resource quotas will let you avoid some obvious DoS of the host (by setting memory, cpu and I/O limits).

The last is mostly about the devices cgroup which lets you define which character and block devices a container may access and what it can do with them (you can restrict creation, read access and write access for each major/minor combination).

In LXC, configuring cgroups is done with the ``lxc.cgroup.*`` options which can roughly be defined as: 

.. code::

    lxc.cgroup.<controller>.<key> = <value>

For example to set a memory limit on ``p1`` you’d add the following to its configuration:

.. code::

    lxc.cgroup.memory.limit_in_bytes = 134217728

This will set a memory limit of 128MB (the value is in bytes) and will be the equivalent to writing that same value to ``/sys/fs/cgroup/memory/lxc/p1/memory.limit_in_bytes``

Most LXC templates only set a few devices controller entries by default:

.. code::

    # Default cgroup limits
    lxc.cgroup.devices.deny = a
    ## Allow any mknod (but not using the node)
    lxc.cgroup.devices.allow = c *:* m
    lxc.cgroup.devices.allow = b *:* m
    ## /dev/null and zero
    lxc.cgroup.devices.allow = c 1:3 rwm
    lxc.cgroup.devices.allow = c 1:5 rwm
    ## consoles
    lxc.cgroup.devices.allow = c 5:0 rwm
    lxc.cgroup.devices.allow = c 5:1 rwm
    ## /dev/{,u}random
    lxc.cgroup.devices.allow = c 1:8 rwm
    lxc.cgroup.devices.allow = c 1:9 rwm
    ## /dev/pts/*
    lxc.cgroup.devices.allow = c 5:2 rwm
    lxc.cgroup.devices.allow = c 136:* rwm
    ## rtc
    lxc.cgroup.devices.allow = c 254:0 rm
    ## fuse
    lxc.cgroup.devices.allow = c 10:229 rwm
    ## tun
    lxc.cgroup.devices.allow = c 10:200 rwm
    ## full
    lxc.cgroup.devices.allow = c 1:7 rwm
    ## hpet
    lxc.cgroup.devices.allow = c 10:228 rwm
    ## kvm
    lxc.cgroup.devices.allow = c 10:232 rwm

This configuration allows the container (usually ``udev``) to create any device it wishes (that’s the wildcard ``m`` above) but block everything else (the ``a`` deny entry) unless it’s listed in one of the allow entries below. This covers everything a container will typically need to function.

You will find reasonably up to date documentation about the available controllers, control files and supported values at:
https://www.kernel.org/doc/Documentation/cgroups/

Apparmor
========

A little while back we added Apparmor profiles support to LXC.

The Apparmor support is rather simple, there’s one configuration option ``lxc.aa_profile`` which sets what apparmor profile to use for the container.

LXC will then setup the container and ask apparmor to switch it to that profile right before starting the container. Ubuntu’s LXC profile is rather complex as it aims to prevent any of the known ways of escaping a container or cause harm to the host.

As things are today, Ubuntu ships with 3 apparmor profiles meaning that the supported values for ``lxc.aa_profile`` are:

- ``lxc-container-default`` (default value if ``lxc.aa_profile`` isn’t set)
- ``lxc-container-default-with-nesting`` (same as default but allows some needed bits for nested containers)
- ``lxc-container-default-with-mounting`` (same as default but allows mounting ext*, xfs and btrfs file systems).
- ``unconfined`` (a special value which will disable apparmor support for the container)

You can also define your own by copying one of the ones in ``/etc/apparmor.d/lxc/``, adding the bits you want, giving it a unique name, then reloading apparmor with ``sudo /etc/init.d/apparmor reload`` and finally setting ``lxc.aa_profile`` to the new profile’s name.

SELinux
=======

The SELinux support is very similar to Apparmor’s. An SELinux context can be set using ``lxc.se_context``.

An example would be:

.. code::

    lxc.se_context = unconfined_u:unconfined_r:lxc_t:s0-s0:c0.c1023

Similarly to Apparmor, LXC will switch to the new SELinux context right before starting init in the container. As far as I know, no distributions are setting a default SELinux context at this time, however most distributions build LXC with SELinux support (including Ubuntu, should someone choose to boot their host with SELinux rather than Apparmor).

Seccomp
=======

Seccomp is a fairly recent kernel mechanism which allows for filtering of system calls.

As a user you can write a seccomp policy file and set it using ``lxc.seccomp`` in the container’s configuration. As always, this policy will only be applied to the running container and will allow or reject syscalls with a pre-defined return value.

An example (though limited and useless) of a seccomp policy file would be:

.. code::

    1
    whitelist
    103

Which would only allow ``syscall #103`` (syslog) in the container and reject everything else.

Note that seccomp is a rather low level feature and only useful for some very specific use cases. All syscalls have to be referred by their ID instead of their name and those may change between architectures. Also, as things are today, if your host is 64bit and you load a seccomp policy file, all 32bit syscalls will be rejected. We’d need per-personality seccomp profiles to solve that but it’s not been a high priority so far.

User namespace
==============

And last but not least, what’s probably the only way of making a container actually safe. LXC now has support for user namespaces. I’ll go into more details on how to use that feature in a later blog post but simply put, LXC is no longer running as root so even if an attacker manages to escape the container, he’d find himself having the privileges of a regular user on the host.

All this is achieved by assigning ranges of uids and gids to existing users. Those users on the host will then be allowed to clone a new user namespace in which all uids/gids are mapped to uids/gids that are part of the user’s range.

This obviously means that you need to allocate a rather silly amount of uids and gids to each user who’ll be using LXC in that way. In a perfect world, you’d allocate 65536 uids and gids per container and per user. As this would likely exhaust the whole uid/gid range rather quickly on some systems, I tend to go with “just” 65536 uids and gids per user that’ll use LXC and then have the same range shared by all containers.

Anyway, that’s enough details about user namespaces for now. I’ll cover how to actually set that up and use those unprivileged containers in the next post.
