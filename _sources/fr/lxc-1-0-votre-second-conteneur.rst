.. -*- coding: utf-8 -*-

-----------------------------
2. Votre deuxième conteneur
-----------------------------

:Date: 21/12/2013
:Auteur: Stéphane Graber

Ceci est le billet 2 sur 10 dans la `série de billets de blog sur LXC 1.0`_.

Plus de modèles
+++++++++++++++

Donc, à ce stade, vous devriez avoir un conteneur Ubuntu en train de tourner qui s'appelle ``p1`` et a qui été créé en utilisant le modèle par défaut appelé simplement ``ubuntu``.

Mais LXC supporte beaucoup plus que le standard Ubuntu. En fait, dans `dépôt source courant` _ (et tous les mise à jours quotidienne du PPA source), nous supportons Alpine Linux, Alt Linux, Arch Linux, Busybox, CentOS, Cirros, Debian, Fedora, OpenMandriva, OpenSUSE, Oracle, Plamo, sshd, Ubuntu Cloud et Ubuntu.

Tous ceux qui se trouvent généralement dans ``/usr/share/lxc/templates``. Ils ont également tous généralement des options avancées supplémentaires que vous pouvez obtenir par le passage ``--help`` après l'appel de ``lxc-create`` (le ``--`` est nécessaire pour séparer les options de ``lxc-create`` du modèle).

La rédaction de modèles supplémentaires n'est pas trop difficile, ce sont essentiellement des exécutables (tous des scripts shell, mais ce n'est pas une obligation)  qui prennent un ensemble d'arguments standards et qui devraient produire un système de fichiers racine fonctionnant dans le chemin qui leur est fournit.

Une des choses à prendre en compte, c'est que du fait d'outils manquants, toutes les distributions ne peuvent par être lancées sur toutes les unes sur les autres. Il est généralement préférable d'essayer au préalable. Nous sommes toujours intéressés pour faire ces travaux sur plusieurs distributions, même si cela signifie de l'utilisation de certains trucs plutôt étranges (comme cela est fait dans le modèle de fedora) donc si vous avez une combinaison spécifique qui ne fonctionne pas pour le moment, les correctifs sont définitivement les bienvenus !

Quoi qu'il en soit, assez parlé pour le moment, avançons et créons un conteneur Oracle Linux que nous allons forcer en 32 bits.


.. code::

   sudo lxc-create -t oracle -n p2 -- -a i386

Sur la plupart des systèmes, ce sera d'abord un échec, vous invitant à installer le paquet ``rpm`` première qui est nécessaire pour des raisons de bootstrap. Alors, installez-le ainsi que ``yum`` et puis essayez à nouveau.

Après un certain temps de téléchargement des RPM, le conteneur sera créé, alors il faudra juste un :

.. code::

   sudo lxc-start -n p2

Et vous serez accueillis par l'invite de connexion Oracle Linux (root / root).

À ce moment, puisque que vous avez démarré le conteneur sans passer ``-d`` à ``lxc-start``, vous aurez à l'éteindre pour récupérer votre invite shell (vous ne pouvez pas détacher un conteneur qui n'a pas été démarré d'abord en arrière-plan).

Maintenant, vous vous demandez pourquoi Ubuntu dispose de deux modèles. Le modèle Ubuntu dont je me sers jusqu'à présent fait un bootstrap local en utilisant "debootstrap" en construisant en gros votre conteneur à partir de zéro, alors que le modèle Ubuntu Cloud (ubuntu-cloud) télécharge une image pour nuage pré-générés (identique à ce que vous obtenir sur EC2 ou d'autres services de cloud computing) et le démarre. Cette image comprend également cloud-init et prend en charge les métadonnées de nuage standard.

C'est une question de choix personnel qui vous plaît le plus. Personnellement, j'ai un miroir local de sorte que le modèle "ubuntu" est beaucoup plus rapide pour moi et plus sûr aussi plus puisque je sais que tout a été téléchargé à partir de l'archive en face de moi et assemblé localement sur ma machine.

Une dernière note sur les modèles. La plupart d'entre eux utilisent un cache local, aussi la génération initiale d'un conteneur pour une architecture donnée sera lent, mais toute génération ultérieur quelconque sera juste une copie locale de la mémoire cache et sera beaucoup plus rapide.

Auto-start
++++++++++

Alors que faire si vous voulez démarrer automatiquement un conteneur au moment du démarrage ?

Eh bien, c'était pris en charge pendant une longue période dans Ubuntu et d'autres distributions en utilisant des scripts d'initialisation et des liens symboliques dans ``/etc``, mais depuis très récemment (il ya deux jours), c'est désormais mis en oeuvre proprement en amont.

Alors, voici comment conteneurs à démarrage automatique fonctionnement maintenant :

Comme vous le savez, chaque conteneur dispose d'un fichier de configuration généralement sous
``/var/lib/lxc/<container name>/config``

Ce fichier est un fichier de typé clé = valeur avec une liste des clés valides spécifiées dans `lxc.conf(5)`_.

Les valeurs de démarrage liés qui sont disponibles sont les suivantes :

- ``lxc.start.auto`` = 0 (désactivé) ou 1 (activé)
- ``lxc.start.delay``  = 0 (delai en seconde à attendre après le démarrage du conteneur)
- ``lxc.start.order``  = 0 (priorité du conteneur, plus la valeur est élevée, plus tôt commence le démarrage du conteneur)
- ``lxc.group`` = groupe1, groupe2, groupe 3, ... (groups auxquel apprtient le conteneur)

Lorsque la machine démarre, un script d'initialisation demande à ``lxc-autostart``  de démarrer tous les conteneurs d'un groupe donné (par défaut, tous les contenants qui ne sont dans aucun groupes) dans le bon ordre et en attend le temps spécifié entre eux.

Pour illustrer cela, modifier ``/var/lib/lxc/p1/config``  et ajouter ces lignes dans le fichier :

.. code::

   lxc.start.auto = 1
   lxc.group = ubuntu

Et le fichier ``/var/lib/lxc/p2/config`` pour ajouter ces lignes:

.. code::

   lxc.start.auto = 1
   lxc.start.delay = 5
   lxc.start.order = 100


Faire cela signifie que seul le conteneur p2 sera lancé au démarrage (puisque seuls ceux sans groupe le sont par défaut), la la valeur d'ordre n'importera pas, car le conteneur  est seul et le script d'initialisation va attendre 5s avant de continuer.

Vous pouvez vérifier quels conteneurs sont automatiquement lancés en utilisant la commande ``lxc-ls``:

.. code ::

   stgraber@castiana:~$ sudo lxc-ls --fancy
   NAME    STATE    IPV4        IPV6                                    AUTOSTART     
   ---------------------------------------------------------------------------------
   
   p2      RUNNING  10.0.3.165  2607:f2c0:f00f:2751:216:3eff:fe3a:f1c1  YES

Maintenant, vous pouvez également jouer manuellement avec ces conteneurs à l'aide de la commande ``lxc-autostart`` qui qui vous permet de LANCER/ARRETER/TUER/RELANCER un conteneur marqué avec ``lxc.start.auto = 1`` .

Par exemple, vous pourriez faire:

.. code::

   sudo lxc-autostart -a

Qui va lancer un conteneur ayant ``lxc.start.auto = 1`` (en ignorant la valeur de ``lxc.group``), ce qui dans notre cas signifie qu'il va d'abord lancer ``p2`` (en raison de l'ordre = 100), puis attendre 5s (puisque ``delay = 5``) et ensuite lancer ``p1`` et retourner immédiatement après.

Si à ce moment vous souhaitez redémarrer tous les conteneurs qui sont dans le groupe ``ubuntu``, vous pouvez faire :

.. code::

   sudo lxc-autostart -r -g ubuntu

Vous pouvez également passer ``-L`` avec l'une de ces commandes ce qui imprimera tout simplement les conteneurs qui pourraient être affectés et quels pourraient être les délais sans réellement faire quelque chose (utile pour intégrer avec d'autres scripts).

Gels de vos conteneurs
++++++++++++++++++++++

Parfois, les conteneurs peuvent être des démons en cours d'exécution qui prennent du temps à l'arrêt ou au redémarrage, mais vous ne voulez lancer le conteneur parce que vous ne l'utilisez sur le moment.

Dans de tels cas, ``sudo lxc-freeze -n <nom du conteneur>`` peut être utilisé. Cela a pour effet de geler très simplement tous les processus dans le récipient de sorte qu'ils ne seront pas tout le temps alloué par l'ordonnanceur. Toutefois, les processus existeront toujours et utiliseront toujours la mémoire qu'ils utilisaient auparavant.

Lorsque vous avez besoin à nouveau du service, il suffit d'appeler ``sudo lxc-unfreeze -n <nom du conteneur>`` et tous les processus seront redémarrés.

Travailler en réseaux
+++++++++++++++++++++

Comme vous avez pu le constater dans le fichier de configuration pendant que vous définissiez les paramètres de démarrage automatique, LXC a une configuration réseau relativement souple.
Par défaut dans Ubuntu nous allouons un dispositif ``veth`` par conteneur qui pointe vers le pont ``lxcbr0`` sur l'hôte sur lequel nous exécutons un serveur minimal dnsmasq DHCP.

Alors que c'est généralement suffisant pour la plupart des gens. Vous voudrez peut-être quelque chose de légèrement plus complexe, comme plusieurs interfaces réseau dans un conteneur ou passer par les interfaces réseaux physiques, ... Les détails de toutes ces options sont répertoriées dans `lxc.conf(5)`_,  je ne vais donc pas les répéter ici, mais voici un petit exemple de ce qui peut être fait.

.. code::

   lxc.network.type = veth
   lxc.network.hwaddr = 00:16:3e:3a:f1:c1
   lxc.network.flags = up
   lxc.network.link = lxcbr0
   lxc.network.name = eth0

   lxc.network.type = veth
   lxc.network.link = virbr0
   lxc.network.name = virt0

   lxc.network.type = phys
   lxc.network.link = eth2
   lxc.network.name = eth1

Avec cette configuration mon conteneur aura trois interfaces, ``eh0`` sera le dispositif veth habituel dans le pont ``lxcbr0``, ``eth1`` sera l'interface ``eth2`` de l'hôte déplacé à l'intérieur du conteneur (il disparaîtra de l'hôte pendant que le conteneur sera en cours d'exécution) et ``virt0`` sera un autre dispositif veth dans le pont ``vurbr0`` sur l'hôte.

Ces deux dernières interfaces n'ont pas d'adresse MAC ou drapeaux réseau paramétrés, de sorte qu'ils obtiendront une adresse mac aléatoire au démarrage (non persistant) et dirigé vers le container pour activer le lien.

Attachement
+++++++++++

A condition que vous utilisiez un noyau suffisamment récent, c'est à dire 3.8 ou ultérieure, vous pouvez utiliser l'outil ``lxc-attacher``. Sa caractéristique la plus fondamentale est de vous donner un shell standard dans un conteneur en cours d'exécution :

.. code::

   sudo lxc-attach -n p1

Vous pouvez également utiliser des scripts pour exécuter des actions dans le conteneur, tels que :

.. code::

   sudo lxc-attach -n p1 -- restart ssh

Mais c'est beaucoup plus puissant que cela. Par exemple, prenez :

.. code::
   
   sudo lxc-attach -n p1 -e -s 'NETWORK|UTSNAME'

Dans ce cas, vous aurez un shell qui affichera ``root@ p1`` (grâce à ``UTSNAME``), et en exécutant ``ifconfig-a`` , vous aurez la liste des interfaces réseau du conteneur. Mais tout le reste proviendra de l'hôte. Passer également ``-e`` signifie que le groupe de contrôle, apparmor, ... les restrictions ne s'appliqueront pas à tous les processus lancer à partir de ce shell.

Cela peut être très utile à certains moments pour faire apparaître un logiciel situé sur la machine hôte, mais l'intérieur du réseau du conteneur ou de son espace de noms pid.

Passer un dispositif à un conteneur en cours d'exécution
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

C'est génial d'être en mesure d'entrer et de sortir du conteneur à volonté, mais qu'en est-il de l'accès à certains dispositifs aléatoires de votre hôte ?

Par défaut LXC va empêcher un tel accès en utilisant le groupe de contrôle comme un dispositif de mécanisme de filtrage. Vous pouvez modifier la configuration du conteneur pour autoriser les bons appareils supplémentaires puis redémarrez le conteneur.

Mais pour des choses plus ponctuelles, il y a aussi un outil très pratique appelé ``lxc-device``.
Avec lui, vous pouvez simplement faire :

.. code::

   sudo lxc-device add -n p1 /dev/ttyUSB0 /dev/ttyS0

Ce qui va ajouter (mknod) ``/dev/ttyS0``  dans le conteneur avec le même type/majeur/mineur que ``/dev/ttyUSB0``  puis ajoutera l'entrée correspondante du groupe de contrôle permettant l'accès depuis le conteneur.

Le même outil permet également le déplacement de dispositifs de réseau depuis l'hôte vers l'intérieur du conteneur.




.. _série de billets de blog sur LXC 1.0: ../../_build/html/fr/index.html#intro-blog-post-series
.. _dépôt source courant: https://github.com/lxc/lxc/tree/master/templates
.. _lxc.conf(5): http://qa.linuxcontainers.org/master/current/doc/man/lxc.conf.5.html
