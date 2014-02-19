.. -*- coding: utf-8 -*-

.. _lxc-1-0-scripting-with-the-api:

**********************
Scripting with the api
**********************

The API
=======

The first version of liblxc was introduced in LXC 0.9 but it was very much at an experimental state. LXC 1.0 however will ship with a much more complete API, covering all of LXC’s features. We’ve actually been rebasing all of our tools (lxc-*) to using that API rather than doing direct calls to the internal functions.

The API also comes with a whole set of tests which we run as part of our continuous integration setup and before distro uploads.

There are also quite a few bindings for those who don’t feel like writing C, we have lua and python3 bindings in-tree upstream and there are official out-of-tree bindings for Go and ruby.

The API documentation can be found at:
https://qa.linuxcontainers.org/master/current/doc/api/

It’s not necessarily the most readable API documentation ever and certainly could do with some examples, especially for the bindings, but it does cover all functions that are exported over the API. Any help improving our API documentation is very much welcome!

The basics
==========

So let’s start with a very simple example of the LXC API using C, the following example will create a new container struct called “apicontainer”, create a root filesystem using the new download template, start the container, print its state and PID number, then attempt a clean shutdown before killing it.

.. code:: c
   :number-lines:

   #include <stdio.h>

   #include <lxc/lxccontainer.h>

   int main() {
       struct lxc_container *c;
       int ret = 1;

       /* Setup container struct */
       c = lxc_container_new("apicontainer", NULL);
       if (!c) {
           fprintf(stderr, "Failed to setup lxc_container struct\n");
           goto out;
       }
   
       if (c->is_defined(c)) {
           fprintf(stderr, "Container already exists\n");
           goto out;
       }
   
       /* Create the container */
       if (!c->createl(c, "download", NULL, NULL, LXC_CREATE_QUIET,
                       "-d", "ubuntu", "-r", "trusty", "-a", "i386", NULL)) {
           fprintf(stderr, "Failed to create container rootfs\n");
           goto out;
       }

       /* Start the container */
       if (!c->start(c, 0, NULL)) {
           fprintf(stderr, "Failed to start the container\n");
           goto out;
       }
   
       /* Query some information */
       printf("Container state: %s\n", c->state(c));
       printf("Container PID: %d\n", c->init_pid(c));
   
       /* Stop the container */
       if (!c->shutdown(c, 30)) {
           printf("Failed to cleanly shutdown the container, forcing.\n");
           if (!c->stop(c)) {
               fprintf(stderr, "Failed to kill the container.\n");
               goto out;
           }
       }
   
       /* Destroy the container */
       if (!c->destroy(c)) {
           fprintf(stderr, "Failed to destroy the container.\n");
           goto out;
       }
   
       ret = 0;
   out:
       lxc_container_put(c);
       return ret;
   }

So as you can see, it’s not very difficult to use, most functions are fairly straightforward and error checking is pretty simple (most calls are boolean and errors are printed to stderr by LXC depending on the loglevel).

Python3 scripting
=================

As much fun as C may be, I usually like to script my containers and C isn’t really the best language for that. That’s why I wrote and maintain the official python3 binding.

The equivalent to the example above in python3 would be:

.. code:: python
   :number-lines:

   import lxc
   import sys
   
   # Setup the container object
   c = lxc.Container("apicontainer")
   if c.defined:
       print("Container already exists", file=sys.stderr)
       sys.exit(1)
   
   # Create the container rootfs
   if not c.create("download", lxc.LXC_CREATE_QUIET, {"dist": "ubuntu",
                                                      "release": "trusty",
                                                      "arch": "i386"}):
       print("Failed to create the container rootfs", file=sys.stderr)
       sys.exit(1)
   
   # Start the container
   if not c.start():
       print("Failed to start the container", file=sys.stderr)
       sys.exit(1)
   
   # Query some information
   print("Container state: %s" % c.state)
   print("Container PID: %s" % c.init_pid)
   
   # Stop the container
   if not c.shutdown(30):
       print("Failed to cleanly shutdown the container, forcing.")
       if not c.stop():
           print("Failed to kill the container", file=sys.stderr)
           sys.exit(1)
   
   # Destroy the container
   if not c.destroy():
       print("Failed to destroy the container.", file=sys.stderr)
       sys.exit(1)

Now for that specific example, python3 isn’t that much simpler than the C equivalent.

But what if we wanted to do something slightly more tricky, like iterating through all existing containers, start them (if they’re not already started), wait for them to have network connectivity, then run updates and shut them down?

.. code:: python
   :number-lines:
   
   import lxc
   import sys
   
   for container in lxc.list_containers(as_object=True):
       # Start the container (if not started)
       started=False
       if not container.running:
           if not container.start():
               continue
           started=True
   
       if not container.state == "RUNNING":
           continue
   
       # Wait for connectivity
       if not container.get_ips(timeout=30):
           continue
   
       # Run the updates
       container.attach_wait(lxc.attach_run_command,
                             ["apt-get", "update"])
       container.attach_wait(lxc.attach_run_command,
                             ["apt-get", "dist-upgrade", "-y"])
   
       # Shutdown the container
       if started:
           if not container.shutdown(30):
               container.stop()

The most interesting bit in the example above is the ``attach_wait`` command, which basically lets your run a standard python function in the container’s namespaces, here’s a more obvious example:

.. code:: python
   :number-lines:
   
   import lxc
   
   c = lxc.Container("p1")
   if not c.running:
       c.start()
   
   def print_hostname():
       with open("/etc/hostname", "r") as fd:
           print("Hostname: %s" % fd.read().strip())
   
   # First run on the host
   print_hostname()
   
   # Then on the container
   c.attach_wait(print_hostname)
   
   if not c.shutdown(30):
       c.stop()

And the output of running the above:

.. code::

   stgraber@castiana:~$ python3 lxc-api.py
   /home/stgraber/<frozen>:313: Warning: The python-lxc API isn't yet stable and may change at any point in the future.
   Hostname: castiana
   Hostname: p1

It may take you a little while to wrap your head around the possibilities offered by that function, especially as it also takes quite a few flags (look for ``LXC_ATTACH_*`` in the C API) which lets you control which namespaces to attach to, whether to have the function contained by apparmor, whether to bypass cgroup restrictions, …

That kind of flexibility is something you’ll never get with a virtual machine and the way it’s supported through our bindings makes it easier than ever to use by anyone who wants to automate custom workloads.

You can also use the API to script cloning containers and using snapshots (though for that example to work, you need current upstream master due to a small bug I found while writing this…):

.. code:: python
   :number-lines:
   
   import lxc
   import os
   import sys
   
   if not os.geteuid() == 0:
       print("The use of overlayfs requires privileged containers.")
       sys.exit(1)
   
   # Create a base container (if missing) using an Ubuntu 14.04 image
   base = lxc.Container("base")
   if not base.defined:
       base.create("download", lxc.LXC_CREATE_QUIET, {"dist": "ubuntu",
                                                      "release": "precise",
                                                      "arch": "i386"})
   
       # Customize it a bit
       base.start()
       base.get_ips(timeout=30)
       base.attach_wait(lxc.attach_run_command, ["apt-get", "update"])
       base.attach_wait(lxc.attach_run_command, ["apt-get", "dist-upgrade", "-y"])
   
       if not base.shutdown(30):
           base.stop()
   
   # Clone it as web (if not already existing)
   web = lxc.Container("web")
   if not web.defined:
       # Clone base using an overlayfs overlay
       web = base.clone("web", bdevtype="overlayfs",
                        flags=lxc.LXC_CLONE_SNAPSHOT)
   
       # Install apache
       web.start()
       web.get_ips(timeout=30)
       web.attach_wait(lxc.attach_run_command, ["apt-get", "update"])
       web.attach_wait(lxc.attach_run_command, ["apt-get", "install",
                                                "apache2", "-y"])
   
       if not web.shutdown(30):
           web.stop()
   
   # Create a website container based on the web container
   mysite = web.clone("mysite", bdevtype="overlayfs",
                      flags=lxc.LXC_CLONE_SNAPSHOT)
   mysite.start()
   ips = mysite.get_ips(family="inet", timeout=30)
   if ips:
       print("Website running at: http://%s" % ips[0])
   else:
       if not mysite.shutdown(30):
           mysite.stop()

The above will create a base container using a downloaded image, then clone it using an overlayfs based overlay, add apache2 to it, then clone that resulting container into yet another one called ``mysite``. So ``mysite`` is effectively an overlay clone of ``web`` which is itself an overlay clone of ``base``.

So there you go, I tried to cover most of the interesting bits of our API with the examples above, though there’s much more available, for example, I didn’t cover the snapshot API (currently restricted to system containers) outside of the specific overlayfs case above and only scratched the surface of what’s possible to do with the attach function.

LXC 1.0 will release with a stable version of the API, we’ll be doing additions in the next few 1.x versions (while doing bugfix only updates to 1.0.x) and hope not to have to break the whole API for quite a while (though we’ll certainly be adding more stuff to it).
