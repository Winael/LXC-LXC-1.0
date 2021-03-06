.. -*- coding: utf-8 -*-

----------------------
 5. Container storage
----------------------

:Date: 2013/12/27
:Author: Stéphane Graber

This is post 5 out of 10 in the `LXC 1.0 blog post series`_.

Storage backingstores
+++++++++++++++++++++

LXC supports a variety of storage backends (also referred to as
backingstore).
It defaults to none which simply stores the rootfs under
``/var/lib/lxc/<container>/rootfs`` but you can specify something else to
``lxc-create`` or ``lxc-clone`` with the ``-B`` option.

Currently supported values are:


directory based storage (none and dir)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This is the default backingstore, the container rootfs is stored under
``/var/lib/lxc/<container>/rootfs``

The ``--dir`` option (when using dir) can be used to override the path.


btrfs
~~~~~

With this backingstore LXC will setup a new subvolume for the
container which makes snapshotting much easier.


lvm
~~~

This one will use a new logical volume for the container.
The LV can be set with ``--lvname`` (the default is the container name).
The VG can be set with ``--vgname`` (the default is lxc).
The filesystem can be set with ``--fstype`` (the default is ext4).
The size can be set with ``--fssize`` (the default is 1G).
You can also use LVM thinpools with ``--thinpool``


overlayfs
~~~~~~~~~

This one is mostly used when cloning containers to create a container
based on another one and storing any changes in an overlay.

When used with ``lxc-create`` it'll create a container where any change
done after its initial creation will be stored in a delta0 directory
next to the containers rootfs.


zfs
~~~

Very similar to btrfs, as Ive not used either of those myself I cant
say much about them besides that it should also create some kind of
subvolume for the container and make snapshots and clones faster and
more space efficient.


Standard paths
++++++++++++++

One quick word with the way LXC usually works and where its storing
its files:


+ ``/var/lib/lxc`` (default location for containers)
+ ``/var/lib/lxcsnap`` (default location for snapshots)
+ ``/var/cache/lxc`` (default location for the template cache)
+ ``$HOME/.local/share/lxc`` (default location for unprivileged
  containers)
+ ``$HOME/.local/share/lxcsnap`` (default location for unprivileged
  snapshots)
+ ``$HOME/.cache/lxc`` (default location for unprivileged template cache)


The default path, also called ``lxcpath`` can be overridden on the command
line with the ``-P`` option or once and for all by setting ``lxcpath =
/new/path`` in ``/etc/lxc/lxc.conf`` (or ``$HOME/.config/lxc/lxc.conf`` for
unprivileged containers).

The snapshot directory is always snap appended to lxcpath so it'll
magically follow ``lxcpath``. The template cache is unfortunately
hardcoded and cant easily be moved short of relying on bind-mounts or
symlinks.

The default configuration used for all containers at creation time is
taken from
``/etc/lxc/default.conf`` (no unprivileged equivalent yet).
The templates themselves are stored in ``/usr/share/lxc/templates``.


Cloning containers
++++++++++++++++++

All those backingstores only really shine once you start cloning
containers.
For example, lets take our good old ``p1 Ubuntu`` container and lets say
you want to make a usable copy of it called ``p4``, you can simply do:

.. code::

   sudo lxc-clone -o p1 -n p4

And there you go, youve got a working ``p4`` container thatll be a simple
copy of ``p1`` but with a new mac address and its hostname properly set.

Now lets say you want to do a quick test against ``p1`` but dont want to
alter that container itself, yet you dont want to wait the time needed
for a full copy, you can simply do:

.. code::

   sudo lxc-clone -o p1 -n p1-test -B overlayfs -s

And there you go, youve got a new p1-test container which is entirely
based on the ``p1`` rootfs and where any change will be stored in the
``delta0`` directory of ``p1-test``.
The same ``-s`` option also works with lvm and btrfs (possibly zfs too)
containers and tells ``lxc-clone`` to use a snapshot rather than copy the
whole rootfs across.


Snapshotting
++++++++++++

So cloning is nice and convenient, great for things like development
environments where you want throw away containers. But in production,
snapshots tend to be a whole lot more useful for things like backup or
just before you do possibly risky changes.

In LXC we have a ``lxc-snapshot`` tool which will let you create, list,
restore and destroy snapshots of your containers.
Before I show you how it works, please note that ``lxc-snapshot``
currently doesnt appear to work with directory based containers. With
those it produces an empty snapshot, this should be fixed by the time
LXC 1.0 is actually released.

So, lets say we want to backup our p1-lvm container before installing
apache2 into it, simply run:

.. code::

   echo "before installing apache2" > snap-comment
   sudo lxc-snapshot -n p1-lvm -c snap-comment

At which point, you can confirm the snapshot was created with:

.. code::

   sudo lxc-snapshot -n p1-lvm -L -C

Now you can go ahead and install apache2 in the container.

If you want to revert the container at a later point, simply use:

.. code::

   sudo lxc-snapshot -n p1-lvm -r snap0


Or if you want to restore a snapshot as its own container, you can
use:

.. code::

   sudo lxc-snapshot -n p1-lvm -r snap0 p1-lvm-snap0

And youll get a new ``p1-lvm-snap0`` container which will contain a
working copy of ``p1-lvm`` as it was at ``snap0``.




.. _LXC 1.0 blog post series: ../../_build/en/index.html#intro-blog-post-series



