.. -*- coding: utf-8 -*-

--------------------------------
 1. Your first Ubuntu container
--------------------------------

:Date: 2013/12/20
:Author: Stéphane Graber

This is post 1 out of 10 in the `LXC 1.0 blog post series`_.

So what’s LXC ?
+++++++++++++++

Most of you probably already know the answer to that one, but here it goes:

.. epigraph::

   *“LXC is a userspace interface for the Linux kernel containment features.*
   *Through a powerful API and simple tools, it lets Linux users easily create and manage system or application containers.”*

I’m one of the two upstream maintainers of LXC along with Serge Hallyn.

The project is quite actively developed with milestones every month and a stable release coming up in February. It’s so far been developed by 67 contributors from a wide range of backgrounds and companies.

The project is mostly developed on github: http://github.com/lxc

We have a website at: http://linuxcontainers.org

And mailing lists at: http://lists.linuxcontainers.org

LXC 1.0
+++++++

So what’s that 1.0 release all about?

Well, simply put it’s going to be the first real stable release of LXC and the first we’ll be supporting for 5 years with bugfix releases. It’s also the one which will be included in Ubuntu 14.04 LTS to be released in April 2014.

It’s also going to come with a stable API and a set of bindings, quite a few interesting new features which will be detailed in the next few posts and support for a wide range of host and guest distributions (including Android).

How to get it ?
+++++++++++++++

I’m assuming most of you will be using Ubuntu. For the next few posts, I’ll myself be using the current upstream daily builds on Ubuntu 14.04 but we maintain daily builds on 12.04, 12.10, 13.04, 13.10 and 14.04, so if you want the latest upstream code, you can use `our PPA`_.

Alternatively, LXC is also directly in Ubuntu and quite usable since Ubuntu 12.04 LTS. You can choose to use the version which comes with whatever release you are on, or you can use one the backported version we maintain.

If you want to build it yourself, you can do (not recommended when you can simply use the packages for your distribution):

.. code::

   git clone git://github.com/lxc/lxc
   cd lxc
   sh autogen.sh
   # You will probably want to run the configure script with --help and then set the paths
   ./configure
   make
   sudo make install

What about that first container ?
+++++++++++++++++++++++++++++++++

Oh right, that was actually the goal of this post wasn’t it?

Ok, so now that you have LXC installed, hopefully using the Ubuntu packages, it’s really as simple as:

.. code::

   # Create a "p1" container using the "ubuntu" template and the same version of Ubuntu
   # and architecture as the host. Pass "-- --help" to list all available options.
   sudo lxc-create -t ubuntu -n p1

   # Start the container (in the background)
   sudo lxc-start -n p1 -d

   # Enter the container in one of those ways
   ## Attach to the container's console (ctrl-a + q to detach)
   sudo lxc-console -n p1

   ## Spawn bash directly in the container (bypassing the console login), 
   ## requires a >= 3.8 kernel
   sudo lxc-attach -n p1

   ## SSH into it
   sudo lxc-info -n p1
   ssh ubuntu@<ip from lxc-info>

   # Stop the container in one of those ways
   ## Stop it from within
   sudo poweroff

   ## Stop it cleanly from the outside
   sudo lxc-stop -n p1

   ## Kill it from the outside
   sudo lxc-stop -n p1 -k

And there you go, that’s your first container. You’ll note that everything usually just works on Ubuntu. Our kernels have support for all the features that LXC may use and our packages setup a bridge and a DHCP server that the containers will use by default.
All of that is obviously configurable and will be covered in the coming posts.



.. _LXC 1.0 blog post series: ../../_build/en/index.html#intro-blog-post-series
.. _our PPA: https://launchpad.net/~ubuntu-lxc/+archive/daily
