.. -*- coding: utf-8 -*-

---------------------------------------
 4. Some more advanced container usage
---------------------------------------

:Date: 2013/12/23
:Author: Stéphane Graber

This is post 4 out of 10 in the `LXC 1.0 blog post series`_.

Running foreign architectures
+++++++++++++++++++++++++++++

By default LXC will only let you run containers of one of the architectures supported by the host. That makes sense since after all, your CPU doesn’t know what to do with anything else.

Except that we have this convenient package called ``qemu-user-static`` which contains a whole bunch of emulators for quite a few interesting architectures. The most common and useful of those is qemu-arm-static which will let you run most armv7 binaries directly on x86.

The ``ubuntu`` template knows how to make use of ``qemu-user-static``, so you can simply check that you have the ``qemu-user-static`` package installed, then run:

.. code::

   sudo lxc-create -t ubuntu -n p3 -- -a armhf

After a rather long bootstrap, you’ll get a new ``p3`` container which will be mostly running Ubuntu armhf. I’m saying mostly because the qemu emulation comes with a few limitations, the biggest of which is that any piece of software using the ``ptrace()`` syscall will fail and so will anything using netlink. As a result, LXC will install the host architecture version of upstart and a few of the networking tools so that the containers can boot properly.

.. code::

   stgraber@castiana:~$ file /bin/ls
   /bin/ls: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), 
   dynamically linked (uses shared libs), for GNU/Linux 2.6.24, 
   ""BuildID[sha1]"" =e50e0a5dadb8a7f4eaa2fd715cacb9842e157dc7, stripped
   stgraber@castiana:~$ sudo lxc-start -n p3 -d
   stgraber@castiana:~$ sudo lxc-attach -n p3
   root@p3:/# file /bin/ls
   /bin/ls: ELF 32-bit LSB  executable, ARM, EABI5 version 1 (SYSV), 
   dynamically linked (uses shared libs), for GNU/Linux 2.6.32, 
   ""BuildID[sha1]"" =88ff013a8fd9389747fb1fea1c898547fb0f650a, stripped
   root@p3:/# exit
   stgraber@castiana:~$ sudo lxc-stop -n p3
   stgraber@castiana:~$

Hooks
+++++

As we know people like to script their containers and that our configuration can’t always accommodate every single use case, we’ve introduced a set of hooks which you may use.

Those hooks are simple paths to an executable file which LXC will run at some specific time in the lifetime of the container. Those executables will also be passed a set of useful environment variables so they can easily know what container invoked them and what to do.

The currently available hooks are (details in `lxc.conf(5)`_):

- ``lxc.hook.pre-start`` (called before any initialization is done)
- ``lxc.hook.pre-mount`` (called after creating the mount namespace but before mounting anything)
- ``lxc.hook.mount`` (called after the mounts but before pivot_root)
- ``lxc.hook.autodev`` (identical to mount but only called if using ``autodev``)
- ``lxc.hook.start`` (called in the container right before ``/sbin/init``)
- ``lxc.hook.post-stop`` (run after the container has been shutdown)
- ``lxc.hook.clone`` (called when cloning a container into a new one)

Additionally each network section may also define two additional hooks:

- ``lxc.network.script.up`` (called in the network namespace after the interface was created)
- ``lxc.network.script.down`` (called in the network namespace before destroying the interface)

All of those hooks may be specified as many times as you want in the configuration so you can use each hooking point multiple times.

As a simple example, let’s add the following to our ``p1`` container:

.. code::

   lxc.hook.pre-start = /var/lib/lxc/p1/pre-start.sh

And create the hook itself at ``/var/lib/lxc/p1/pre-start.sh``:

.. code::

   #!/bin/sh
   echo "arguments: $*" > /tmp/test
   echo "environment:" >> /tmp/test
   env | grep LXC >> /tmp/test

Make it executable (``chmod 755``) and then start the container.
Checking ``/tmp/test`` you should see:

.. code::

   arguments: p1 lxc pre-start
   environment:
   LXC_ROOTFS_MOUNT=/usr/lib/x86_64-linux-gnu/lxc
   LXC_CONFIG_FILE=/var/lib/lxc/p1/config
   LXC_ROOTFS_PATH=/var/lib/lxc/p1/rootfs
   LXC_NAME=p1

Android containers
++++++++++++++++++

I’ve often been asked whether it was possible to run Android in an LXC container. Well, the short answer is yes. However it’s not very simple and it really depends on what you want to do with it.

The first thing you’ll need if you want to do this is get your machine to run an Android kernel, you’ll need to have any modules needed by Android built and loaded before you can start the container.

Once you have that, you’ll need to create a new container by hand.
Let’s put it in ``/var/lib/lxc/android/``, in there, you need a configuration file similar to this one:

.. code::

   lxc.rootfs = /var/lib/lxc/android/rootfs
   lxc.utsname = armhf

   lxc.network.type = none

   lxc.devttydir = lxc
   lxc.tty = 4
   lxc.pts = 1024
   lxc.arch = armhf
   lxc.cap.drop = mac_admin mac_override
   lxc.pivotdir = lxc_putold

   lxc.hook.pre-start = /var/lib/lxc/android/pre-start.sh

   lxc.aa_profile = unconfined

``/var/lib/lxc/android/pre-start.sh`` is where the interesting bits happen. It needs to be an executable shell script, containing something along the lines of:

.. code::

   #!/bin/sh
   mkdir -p $LXC_ROOTFS_PATH
   mount -n -t tmpfs tmpfs $LXC_ROOTFS_PATH
   
   cd $LXC_ROOTFS_PATH
   cat /var/lib/lxc/android/initrd.gz | gzip -d | cpio -i
   
   # Create /dev/pts if missing
   mkdir -p $LXC_ROOTFS_PATH/dev/pts

Then get the initrd for your device and place it in ``/var/lib/lxc/android/initrd.gz``.

At that point, when starting the LXC container, the Android initrd will be unpacked on a tmpfs (similar to Android’s ramfs) and Android’s init will be started which in turn should mount any partition that Android requires and then start all of the usual services.

Because there are no apparmor, cgroup or even network configuration applied to it, the container will have a lot of rights and will typically completely crash the machine. You unfortunately have to be familiar with the way Android works and not be afraid to modify its init scripts if not even its init process to only start the bits you actually want.

I can’t provide a generic recipe there as it completely depends on what you’re interested on, what version of Android and what device you’re using. But it’s clearly possible to do and you may want to look at Ubuntu Touch to see how we’re doing it by default there.

One last note, Android’s init script isn’t in ``/sbin/init``, so you need to tell LXC where to load it with:

.. code::

   lxc-start -n android -- /init

LXC on Android devices
++++++++++++++++++++++

So now that we’ve seen how to run Android in LXC, let’s talk about running Ubuntu on Android in LXC.

LXC has been ported to bionic (Android’s C library) and while not feature-equivalent with its glibc build, it’s still good enough to be used.

Unfortunately due to the kind of low level access LXC requires and the fact that our primary focus isn’t Android, installation could be easier…You won’t be finding LXC on the Google PlayStore and we won’t provide you with a .apk that you can install.

Instead every time something changes in the upstream git branch, we produce a new tarball which can be downloaded here: http://qa.linuxcontainers.org/master/current/android-armel/lxc-android.tar.gz

This build is known to work with Android >= 4.2 but will quite likely work on older versions too.

For this to work, you’ll need to grab your device’s kernel configuration and run ``lxc-checkconfig`` against it to see whether it’s compatible with LXC or not. Unfortunately it’s very likely that it won’t be… In that case, you’ll need to go hunt for the kernel source for your device, add the missing feature flags, rebuild it and update your device to boot your updated kernel.

As scary as this may sound, it’s usually not that difficult as long as your device is unlocked and you’re already using an alternate ROM like Cyanogen which usually make their kernel git tree easily available.

Once your device has a working kernel, all you need to do is unpack our tarball as root in your device’s ``/`` directory, copy an arm container to ``/data/lxc/containers/<container name>``, get into ``/data/lxc`` and run ``./run-lxc lxc-start -n <container name>”``.
A few seconds later you’ll be greeted by a login prompt.




.. _LXC 1.0 blog post series: ../../_build/en/index.html#intro-blog-post-series
