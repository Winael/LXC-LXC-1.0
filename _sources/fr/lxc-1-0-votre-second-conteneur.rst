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

À ce moment, puisque que vous avez démarré le conteneur sans passer``-d`` à ``lxc-start``, vous aurez à l'éteindre pour récupérer votre invite shell (vous ne pouvez pas détacher un conteneur qui n'a pas été démarré d'abord en arrière-plan).

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
