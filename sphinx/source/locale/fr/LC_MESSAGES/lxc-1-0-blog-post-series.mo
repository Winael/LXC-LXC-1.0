��          �       L      L  
   M     X     x     �  )   �     �  "   �       �   3     �  �   �  !   |  &   �  .   �  �   �  z   �     G    X  9  �  
             =     V  )   o     �  "   �     �  �   �  ,   �	  �   �	  C   �
  0   �
  )   "    L  ~   e     �  |  �   2013/12/20 :ref:`advanced-container-usage` :ref:`container-storage` :ref:`security-features` :ref:`some-more-advanced-container-usage` :ref:`unprivileged-containers` :ref:`your-first-ubuntu-container` :ref:`your-second-container` As a result, I’m preparing a series of 10 blog posts covering what I think are some of the most exciting features of LXC. The planned structure is: Intro.  Blog post series I’ll be updating this first blog post with links to all of the posts in the series. So if you want to bookmark or refer to these, please use this post. LXC 1.0: GUI in containers [9/10] LXC 1.0: Scripting with the API [8/10] LXC 1.0: Troubleshooting and debugging [10/10] Since I’ve been doing quite a bit of work on LXC lately in prevision for the LXC_ 1.0 release early next year, I thought that it’d be a good use of some of that extra time to blog about the current state of LXC. So it’s almost the end of the year, I’ve got about 10 days of vacation for the holidays and a bit of time on my hands. Stéphane Graber While they are all titled LXC 1.0, most of the things I’ll be showing will work just as well on older LXC. However some of the features will need a very very recent version of LXC (as in, current upstream git). I’ll try to make that clear and will explain how to use our `stable backports in Ubuntu <stable-backport_>`_ or `current upstream snapshots from our PPA <daily-ppa_>`_. Project-Id-Version: LXC 1.0 - Quickstart 1.0
Report-Msgid-Bugs-To: 
POT-Creation-Date: 2014-01-28 07:23
PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE
Last-Translator: FULL NAME <EMAIL@ADDRESS>
Language-Team: LANGUAGE <LL@li.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
 20/12/2013 :ref:`advanced-container-usage` :ref:`container-storage` :ref:`security-features` :ref:`some-more-advanced-container-usage` :ref:`unprivileged-containers` :ref:`your-first-ubuntu-container` :ref:`your-second-container` En conséquence, je prépare une série de 10 billets de blog couvrant ce que je pense être quelques-unes des caractéristiques les plus intéressantes de LXC. La structure prévue est : Intro. Série de billets de blog sur LXC 1.0 Je mettrai à jour ce premier billet de blog avec des liens vers tous les billets de la série. Donc, si vous souhaitez ajouter un signet ou vous référer à ceux-ci, je vous prie d'utiliser ce billet. LXC 1.0 : interface graphique à l'intérieur des conteneurs [9/10] LXC 1.0 : écriture de scripts avec l'API [8/10] LXC 1.0 : Dépannage et débogage [10/10] Puisque j'étais en train de faire un peu de travail sur LXC dernièrement en prévision de la sortie de la version 1.0 de LXC_ en début d'année prochaine, je pensais que ce serait une bonne utilisation de ce temps supplémentaire pour blogger au sujet de l'état actuel de LXC. Comme c'est presque la fin de l'année, j'ai environ 10 jours de congés pour les vacances et un peu de temps entre les mains. Stéphane Graber Alors que les billets sont tous intitulés LXC 1.0, la plupart des choses que je vais montrer fonctionnent aussi sur des versions moins récentes de LXC. Toutefois, certaines des fonctionnalités ont besoin d'une version très très récente de LXC (telle que celle disponible dans le dépôt git courant en amont). Je vais essayer de faire que ce soit clair et vais vous expliquer comment utiliser nos `rétroportages stables dans Ubuntu <https://launchpad.net/ubuntu/+source/lxc>`_ ou les `instantanés courants disponibles en amont dans notre Archive de Paquets Personnelle (PPA) <https://launchpad.net/~ubuntu-lxc/+archive/daily>`_. 