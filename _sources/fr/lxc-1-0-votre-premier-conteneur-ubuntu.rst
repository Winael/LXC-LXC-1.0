.. -*- coding: utf-8 -*-

-----------------------------------
 1. Votre premier conteneur Ubuntu
-----------------------------------

:Date: 20/12/2013
:Auteur: Stéphane Graber

Ceci est le billet 1 sur 10 dans la `série de billets de blog sur LXC 1.0`_.

Alors, qu'est-ce que LXC ?
++++++++++++++++++++++++++

La plupart d'entre vous savez probablement déjà la réponse à cette question, mais voilà :

.. epigraph::

   *« LXC est une interface de l'espace utilisateur pour les fonctionnalités de confinement du noyau Linux.*
   *Grâce à une API puissante et des outils simples, il permet aux utilisateurs de Linux de créer et de gérer des conteneurs système ou applicatifs facilement. »*

Je suis l'un des deux responsables des sources de LXC avec Serge Hallyn.

Le projet est très activement développé avec des étapes chaque mois et une version stable à venir en Février. Il a, jusqu'ici, été développé par 67 contributeurs à partir d'un large éventail de milieux et sociétés.

Le projet est principalement développé sur github: http://github.com/lxc

Nous avons un site Web à l'adresse: http://linuxcontainers.org

Et des listes de diffusion à l'adresse: http://lists.linuxcontainers.org

LXC 1.0
+++++++

Alors, de quoi s'agit-il dans la version 1.0 ?

Eh bien, pour dire les choses simplement, ça va être la première vraie version stable de LXC et la première que nous allons supporter pendant 5 ans avec sortie de correction de bugs. C'est aussi celle qui sera incluse dans Ubuntu 14.04 LTS, publiée en Avril 2014.

Elle va aussi sortir avec une API stable et un ensemble de liaisons, un bon nombre de nouvelles fonctionnalités intéressantes qui seront détaillées dans les prochains billets et le support pour un large éventail de distributions hôtes et invitées (y compris Android).

Comment l'obtenir ?
+++++++++++++++++++

Je suppose que la plupart d'entre vous utiliseront Ubuntu. Pour les prochains billet, j'utiliserai es sources construites quotidiennement pour Ubuntu 14.04 mais nous maintenons une constructions quotidienne des paquets pour Ubuntu 12.04, 12.10, 13.04, 13.10 et 14.04, donc si vous voulez le dernier code source, vous pouvez utiliser `notre PPA`_.

Sinon, LXC est aussi inclus dans les dépôts Ubuntu et tout à fait utilisable depuis Ubuntu 12.04 LTS. Vous pouvez choisir d'utiliser la version qui vient avec cette version que vous avez, ou vous pouvez utiliser une version rétroportée que nous maintenons.

Si vous voulez construire vous-même la dernière version de LXC, vous pouvez le faire (non recommandé lorsque vous pouvez simplement utiliser les paquets de votre distribution) :

.. code::

   git clone git://github.com/lxc/lxc
   cd lxc
   sh autogen.sh
   # Vous aurez probablement envie de lancer le script configure avec 
   # --help, puis de définir les chemins
   ./configure
   make
   sudo make install

Qu'en est-il du premier conteneur ?
+++++++++++++++++++++++++++++++++++

Ah oui, c'était effectivement le but de ce post n'est-ce pas?

Ok, alors maintenant que vous avez installé LXC, en utilisant j'espère les paquets Ubuntu, c'est vraiment aussi simple que :

.. code::

   # Création d'un conteneur "p1" en utilisant le modèle "ubuntu" 
   # et la même version d'Ubuntu
   # Et architecture que l'hôte. Passer "-- --help" pour lister toutes 
   # les options disponibles.
   sudo lxc-create -t ubuntu -n p1

   # Démarrage du conteneur (en tâche de fond)
   sudo lxc-start -n p1 -d

   # Arrêt du conteneur via un de ces moyens
   ## Attachement à la console du conteneur (ctrl-a + q pour détacher)
   sudo lxc-console -n p1

   ## Apparition en bash directement dans le conteneur (sans passer par 
   ## la connexion de la console),
   ## Nécessite un noyau >= 3.8
   sudo lxc-attach -n p1

   ## SSH dans le conteneur
   sudo lxc-info -n p1
   ssh ubuntu@<ip from lxc-info>

   # Arrêt du conteneur via un de ces moyens
   ## Arrêt de l'intérieur
   sudo poweroff

   ## Arrêt proprement de l'extérieur
   sudo lxc-stop -n p1

   ## Conteneur tué depuis l'extérieur
   sudo lxc-stop -n p1 -k

Et voilà, c'est votre premier conteneur. Vous remarquerez que tout fonctionne normalement sur Ubuntu. Nos noyaux supportent toutes les fonctionnalités que LXC peut utiliser et notre paquets configurent un pont et un serveur DHCP que les conteneurs utiliseront par défaut.
Tout cela est évidemment configurable et sera couvert dans les billets à venir.



.. _série de billets de blog sur LXC 1.0: ../../_build/fr/index.html#intro-serie-de-billets-de-blog
.. _notre PPA: https://launchpad.net/~ubuntu-lxc/+archive/daily
