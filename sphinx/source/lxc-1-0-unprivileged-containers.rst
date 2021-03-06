.. -*- coding: utf-8 -*-

.. _lxc-1-0-unprivileged-containers:

***********************
Unprivileged containers
***********************

Introduction to unprivileged containers
=======================================

The support of unprivileged containers is in my opinion one of the most important new features of LXC 1.0.

You may remember from previous posts that I mentioned that LXC should be considered unsafe because while running in a separate namespace, ``uid 0`` in your container is still equal to ``uid 0`` outside of the container, meaning that if you somehow get access to any host resource through proc, sys or some random syscalls, you can potentially escape the container and then you’ll be root on the host.

That’s what user namespaces were designed for and implemented. It was a multi-year effort to think them through and slowly push the hundreds of patches required into the upstream kernel, but finally with 3.12 we got to a point where we can start a full system container entirely as a user.

So how do those user namespaces work ? Well, simply put, each user that’s allowed to use them on the system gets assigned a range of unused uids and gids, ideally a whole 65536 of them. You can then use those uids and gids with two standard tools called ``newuidmap`` and ``newgidmap`` which will let you map any of those uids and gids to virtual uids and gids in a user namespace.

That means you can create a container with the following configuration:

.. code::

    lxc.id_map = u 0 100000 65536
    lxc.id_map = g 0 100000 65536

The above means that I have one uid map and one gid map defined for my container which will map uids and gids 0 through 65536 in the container to uids and gids 100000 through 165536 on the host.

For this to be allowed, I need to have those ranges assigned to my user at the system level with:

.. code::
    
    stgraber@castiana:~$ grep stgraber /etc/sub* 2>/dev/null
    /etc/subgid:stgraber:100000:65536
    /etc/subuid:stgraber:100000:65536

LXC has now been updated so that all the tools are aware of those unprivileged containers. The standard paths also have their unprivileged equivalents:

.. code::
    
    /etc/lxc/lxc.conf => ~/.config/lxc/lxc.conf
    /etc/lxc/default.conf => ~/.config/lxc/default.conf
    /var/lib/lxc => ~/.local/share/lxc
    /var/lib/lxcsnaps => ~/.local/share/lxcsnaps
    /var/cache/lxc => ~/.cache/lxc

Your user, while it can create new user namespaces in which it’ll be ``uid 0`` and will have some of root’s privileges against resources tied to that namespace will obviously not be granted any extra privilege on the host.

One such thing is creating new network devices on the host or changing bridge configuration. To workaround that, we wrote a tool called ``lxc-user-nic`` which is the only ``SETUID`` binary part of LXC 1.0 and which performs one simple task.
It parses a configuration file and based on its content will create network devices for the user and bridge them. To prevent abuse, you can restrict the number of devices a user can request and to what bridge they may be added.

An example is my own ``/etc/lxc/lxc-usernet`` file:

.. code::

    stgraber veth lxcbr0 10

This declares that the user ``stgraber`` is allowed up to 10 veth type devices to be created and added to the bridge called ``lxcbr0``.

Between what’s offered by the user namespace in the kernel and that setuid tool, we’ve got all that’s needed to run most distributions unprivileged.

Pre-requirements
================

All examples and instructions I’ll be giving below are expecting that you are running a perfectly up to date version of Ubuntu 14.04 (codename trusty). That’s a pre-release of Ubuntu so you may want to run it in a VM or on a spare machine rather than upgrading your production computer.

The reason to want something that recent is because the rough requirements for well working unprivileged containers are:

- Kernel: 3.13 + a couple of staging patches (which Ubuntu has in its kernel)
- User namespaces enabled in the kernel
- A very recent version of shadow that supports subuid/subgid
- Per-user cgroups on all controllers (which I turned on a couple of weeks ago)
- LXC 1.0 beta2 or higher (released two days ago)
- A version of PAM with a loginuid patch that’s yet to be in any released version

Those requirements happen to all be true of the current development release of Ubuntu as of two days ago.

LXC pre-built containers
========================

User namespaces come with quite a few obvious limitations. For example in a user namespace you won’t be allowed to use mknod to create a block or character device as being allowed to do so would let you access anything on the host. Same thing goes with some filesystems, you won’t for example be allowed to do loop mounts or mount an ext partition, even if you can access the block device.

Those limitations while not necessarily world ending in day to day use are a big problem during the initial bootstrap of a container as tools like debootstrap, yum, … usually try to do some of those restricted actions and will fail pretty badly.

Some templates may be tweaked to work and workaround such as a modified fakeroot could be used to bypass some of those limitations but the goal of the LXC project isn’t to require all of our users to be distro engineers, so we came up with a much simpler solution.

I wrote a new template called “download” which instead of assembling the rootfs and configuration locally will instead contact a server which contains daily pre-built rootfs and configuration for most common templates.

Those images are built from our Jenkins server using a few machines I have on my home network (a set of powerful x86 builders and a quadcore ARM board). The actual build process is pretty straightforward, a basic chroot is assembled, then the current git master is downloaded, built and the standard templates are run with the right release and architecture, the resulting rootfs is compressed, a basic config and metadata (expiry, files to template, …) is saved, the result is pulled by our main server, signed with a dedicated GPG key and published on the public web server.

The client side is a simple template which contacts the server over https (the domain is also DNSSEC enabled and available over IPv6), grabs signed indexes of all the available images, checks if the requested combination of distribution, release and architecture is supported and if it is, grabs the rootfs and metadata tarballs, validates their signature and stores them in a local cache. Any container creation after that point is done using that cache until the time the cache entries expires at which point it’ll grab a new copy from the server.

The current list of images is (as can be requested by passing ``-list``):

.. code::

    ---
    DIST      RELEASE   ARCH    VARIANT    BUILD
    ---
    debian    wheezy    amd64   default    20140116_22:43
    debian    wheezy    armel   default    20140116_22:43
    debian    wheezy    armhf   default    20140116_22:43
    debian    wheezy    i386    default    20140116_22:43
    debian    jessie    amd64   default    20140116_22:43
    debian    jessie    armel   default    20140116_22:43
    debian    jessie    armhf   default    20140116_22:43
    debian    jessie    i386    default    20140116_22:43
    debian    sid       amd64   default    20140116_22:43
    debian    sid       armel   default    20140116_22:43
    debian    sid       armhf   default    20140116_22:43
    debian    sid       i386    default    20140116_22:43
    oracle    6.5       amd64   default    20140117_11:41
    oracle    6.5       i386    default    20140117_11:41
    plamo     5.x       amd64   default    20140116_21:37
    plamo     5.x       i386    default    20140116_21:37
    ubuntu    lucid     amd64   default    20140117_03:50
    ubuntu    lucid     i386    default    20140117_03:50
    ubuntu    precise   amd64   default    20140117_03:50
    ubuntu    precise   armel   default    20140117_03:50
    ubuntu    precise   armhf   default    20140117_03:50
    ubuntu    precise   i386    default    20140117_03:50
    ubuntu    quantal   amd64   default    20140117_03:50
    ubuntu    quantal   armel   default    20140117_03:50
    ubuntu    quantal   armhf   default    20140117_03:50
    ubuntu    quantal   i386    default    20140117_03:50
    ubuntu    raring    amd64   default    20140117_03:50
    ubuntu    raring    armhf   default    20140117_03:50
    ubuntu    raring    i386    default    20140117_03:50
    ubuntu    saucy     amd64   default    20140117_03:50
    ubuntu    saucy     armhf   default    20140117_03:50
    ubuntu    saucy     i386    default    20140117_03:50
    ubuntu    trusty    amd64   default    20140117_03:50
    ubuntu    trusty    armhf   default    20140117_03:50
    ubuntu    trusty    i386    default    20140117_03:50
    
The template has been carefully written to work on any system that has a POSIX compliant shell with wget. gpg is recommended but can be disabled if your host doesn’t have it (at your own risks).

The same template can be used against your own server, which I hope will be very useful for enterprise deployments to build templates in a central location and have them pulled by all the hosts automatically using our expiry mechanism to keep them fresh.

While the template was designed to workaround limitations of unprivileged containers, it works just as well with system containers, so even on a system that doesn’t support unprivileged containers you can do:

.. code::

    lxc-create -t download -n p1 -- -d ubuntu -r trusty -a amd64

And you’ll get a new container running the latest build of Ubuntu 14.04 amd64.

Using unprivileged LXC
======================

Right, so let’s get you started, as I already mentioned, all the instructions below have only been tested on a very recent Ubuntu 14.04 (trusty) installation.

You may want to grab a daily build and run it in a VM.

Install the required packages:

.. code::

    sudo apt-get update
    sudo apt-get dist-upgrade
    sudo apt-get install lxc systemd-services uidmap

Now a quick workaround while we wait to have our new cgroup manager in Ubuntu, put the following into ``/etc/init/lxc-unpriv-cgroup.conf``:

.. code::

    start on starting systemd-logind and started cgroup-lite
    
    script
        set +e
    
        echo 1 > /sys/fs/cgroup/memory/memory.use_hierarchy
    
        for entry in /sys/fs/cgroup/*/cgroup.clone_children; do
            echo 1 > $entry
        done
    
        exit 0
    end script

This trick is required because logind doesn’t configure use_hierarchy or clone_children the way LXC needs them.

Now, reboot your machine for those cgroups to get properly reconfigured.

Then, assign yourself a set of uids and gids with:

.. code:: 

    sudo usermod –add-subuids 100000-165536 $USER
    sudo usermod –add-subgids 100000-165536 $USER

Now create ``~/.config/lxc/default.conf`` with the following content:

.. code::

    lxc.network.type = veth
    lxc.network.link = lxcbr0
    lxc.network.flags = up
    lxc.network.hwaddr = 00:16:3e:xx:xx:xx
    lxc.id_map = u 0 100000 65536
    lxc.id_map = g 0 100000 65536

And ``/etc/lxc/lxc-usernet`` with:

.. code::

    <your username> veth lxcbr0 10

And that’s all you need. Now let’s create our first unprivileged container with:

.. code:

    lxc-create -t download -n p1 -- -d ubuntu -r trusty -a amd64

You should see the following output from the download template:

.. code::

    Setting up the GPG keyring
    Downloading the image index
    Downloading the rootfs
    Downloading the metadata
    The image cache is now ready
    Unpacking the rootfs
    
    ---
    You just created an Ubuntu container (release=trusty, arch=amd64).
    The default username/password is: ubuntu / ubuntu
    To gain root privileges, please use sudo.
    
So looks like your first container was created successfully, now let’s see if it starts:

.. code::

    ubuntu@trusty-daily:~$ lxc-start -n p1 -d
    ubuntu@trusty-daily:~$ lxc-ls --fancy
    NAME  STATE    IPV4     IPV6     AUTOSTART  
    ------------------------------------------
    p1    RUNNING  UNKNOWN  UNKNOWN  NO

It’s running! At this point, you can get a console using ``lxc-console`` or can SSH to it by looking for its IP in the ARP table (``arp -n``).

One thing you probably noticed above is that the IP addresses for the container aren’t listed, that’s because unfortunately LXC currently can’t attach to an unprivileged container’s namespaces. That also means that some fields of ``lxc-info`` will be empty and that you can’t use `̀`lxc-attach``. However we’re looking into ways to get that sorted in the near future.

There are also a few problems with job control in the kernel and with PAM, so doing a non-detached ``lxc-start`` will probably result in a rather weird console where things like sudo will most likely fail. SSH may also fail on some distros. A patch has been sent upstream for this, but I just noticed that it doesn’t actually cover all cases and even if it did, it’s not in any released version yet.

Quite a few more improvements to unprivileged containers are to come until the final 1.0 release next month and while we certainly don’t expect all workloads to be possible with unprivileged containers, it’s still a huge improvement on what we had before and a very good building block for a lot more interesting use cases.
