#include "title.typ"
#set heading(numbering: "1.")
#set page(  
  numbering: (x, ..) => [#x],
  number-align: center + bottom,
)

#pagebreak()

#outline(title: "Table des matières", depth: 3, indent: 15pt)

#pagebreak()

= Introduction

Le présent rapport documente la procédure de développement d'un driver pour Linux permettant d'interagir avec le bridge Lightweight HPS-to-FPGA sur une carte DE1-SoC.
Ce laboratoire s'inscrit dans la suite des travaux précédents et vise à établir une communication efficace entre le processeur ARM et la partie FPGA de la carte via le bus AXI.

La mise en place de ce driver nécessite plusieurs étapes critiques: la préparation d'une carte SD avec une image Linux adaptée,
la modification du Device Tree pour déclarer notre périphérique, la compilation du noyau Linux avec notre configuration spécifique,
et enfin le développement du driver lui-même ainsi que d'une application utilisateur pour le tester.

Ce document détaille l'ensemble du processus, depuis la préparation de l'environnement jusqu'à l'implémentation et au test du driver.
Les choix techniques effectués y sont justifiés et les commandes nécessaires pour reproduire la démarche sont fournies.

#pagebreak()

= Objectifs 

L’objectif de ce laboratoire est de développer un driver basique qui permet de lire et écrire sur le bridge Lightweight HPS-to-FPGA.

= Préparation de la carte SD

La génération de la carte SD passe par copier l'image fournie dessus.

Pour cela, le plus simple est d'utiliser la commande `dd`

Deux possibilités se présentent :

Celle-ci sauvegarde l'image `de1soc.img` dans l'ordinateur.

```bash
gzip -d de1soc.img.gz
sudo dd if=de1soc.img of=/dev/sda bs=4M status=progress
```

Celle-ci ne sauvegarde pas l'image `de1soc.img` dans l'ordinateur.

```bash
cat de1soc.img.gz | gunzip | sudo dd of=/dev/sda bs=4M status=progress
``` 
= Clone Linux

On peut avoir accès aux sources du kernel linux en le clonant.

```bash
git clone https://github.com/torvalds/linux.git --depth=1
```

= Création du Device Tree

Le dts est fourni dans les fichiers rendus pour ce labo. Il suffit de le copier au bon endroit:

```bash
cp <path_to_dts> <path_to_linux>/arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de1_nano_soc.dts
```

Une fois le dts mis en place, il faut encore modifier le `Makefile` du répértoire `arch/arm/boot/dts/intel/socfpga/Makefile` pour ajouter le nouveau target `dtb`.

```diff
diff --git a/arch/arm/boot/dts/intel/socfpga/Makefile b/arch/arm/boot/dts/intel/socfpga/Makefile
index c467828ae..e719407bb 100644
--- a/arch/arm/boot/dts/intel/socfpga/Makefile
+++ b/arch/arm/boot/dts/intel/socfpga/Makefile
@@ -10,6 +10,7 @@ dtb-$(CONFIG_ARCH_INTEL_SOCFPGA) += \
 	socfpga_cyclone5_mcvevk.dtb \
 	socfpga_cyclone5_socdk.dtb \
 	socfpga_cyclone5_de0_nano_soc.dtb \
+	socfpga_cyclone5_de1_nano_soc.dtb \
 	socfpga_cyclone5_sockit.dtb \
 	socfpga_cyclone5_socrates.dtb \
 	socfpga_cyclone5_sodia.dtb \
```

== Procédure de création

Le device tree de la `de0` peut être trouvé dans `arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de0_nano_soc.dts`.

Pour suivre la convention de nommage je l'ai recopié dans le même repértoire avec la mention `de1` : `arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de1_nano_soc.dts`

Après avoir supprimé les noeuds `gpio0`, `gpio1`, `gpio2` et `i2c0`, j'ai ajouté le noeud pour le bridge lightweight:

```dts
&fpga_bridge0 {
	reg = <0xff200000 0x100000>;
	status = "okay";
};
``` 

Ajouté les `bootargs` comme décrit dans la donnée du labo5

```dts
	bootargs = "root=/dev/mmcblk0p3 rw rootwait earlyprintk";
```

Et finalement ajouté le noeud `de1_io` pour notre driver:

```diff
	de1_io {
		compatible = "de1_io";
		reg = <0xff200000 0x28>;
		status = "okay";
	};
```

Pour convenance, voici la différence entre les deux fichiers:

```diff
--- socfpga_cyclone5_de0_nano_soc.dts	2025-04-09 15:38:39.286836130 +0200
+++ socfpga_cyclone5_de1_nano_soc.dts	2025-04-09 15:38:42.370834805 +0200
@@ -6,11 +6,11 @@
 #include "socfpga_cyclone5.dtsi"
 
 / {
-	model = "Terasic DE-0(Atlas)";
+	model = "Terasic DE-1(Atlas)";
 	compatible = "terasic,de0-atlas", "altr,socfpga-cyclone5", "altr,socfpga";
 
 	chosen {
-		bootargs = "earlyprintk";
+		bootargs = "root=/dev/mmcblk0p3 rw rootwait earlyprintk";
 		stdout-path = "serial0:115200n8";
 	};
 
@@ -39,6 +39,18 @@
 			linux,default-trigger = "heartbeat";
 		};
 	};
+
+	de1_io {
+		compatible = "de1_io";
+		reg = <0xff200000 0x28>;
+		status = "okay";
+	};
+};
+
+&fpga_bridge0 {
+	reg = <0xff200000 0x100000>;
+	status = "okay";
 };
 
 &gmac1 {
@@ -61,31 +73,6 @@
 	max-frame-size = <3800>;
 };
 
-&gpio0 {
-	status = "okay";
-};
-
-&gpio1 {
-	status = "okay";
-};
-
-&gpio2 {
-	status = "okay";
-};
-
-&i2c0 {
-	status = "okay";
-	clock-frequency = <100000>;
-
-	adxl345: adxl345@53 {
-		compatible = "adi,adxl345";
-		reg = <0x53>;
-
-		interrupt-parent = <&portc>;
-		interrupts = <3 2>;
-	};
-};
-
 &mmc0 {
 	vmmc-supply = <&regulator_3_3v>;
 	vqmmc-supply = <&regulator_3_3v>;
```

Une fois le dts mis en place, j'ai modifié le Makefile du répértoire `arch/arm/boot/dts/intel/socfpga/Makefile` pour ajouter le nouveau target `dtb`.

```diff
diff --git a/arch/arm/boot/dts/intel/socfpga/Makefile b/arch/arm/boot/dts/intel/socfpga/Makefile
index c467828ae..e719407bb 100644
--- a/arch/arm/boot/dts/intel/socfpga/Makefile
+++ b/arch/arm/boot/dts/intel/socfpga/Makefile
@@ -10,6 +10,7 @@ dtb-$(CONFIG_ARCH_INTEL_SOCFPGA) += \
 	socfpga_cyclone5_mcvevk.dtb \
 	socfpga_cyclone5_socdk.dtb \
 	socfpga_cyclone5_de0_nano_soc.dtb \
+	socfpga_cyclone5_de1_nano_soc.dtb \
 	socfpga_cyclone5_sockit.dtb \
 	socfpga_cyclone5_socrates.dtb \
 	socfpga_cyclone5_sodia.dtb \
```

= Compilation Linux

Configurer avec le bon `defconfig`:

Note: si la toolchain `arm-linux-gnueabihf` n'est dans le `PATH`, il faut changer `arm-linux-gnueabihf-` avec le chemin complet de celle-ci.

```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
``` 

Et finalement la compilation:

```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
``` 

A ce-moment le fichier `zImage` peut être trouvé dans `arch/arm/boot/zImage` et le device tree compilé dans `arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de1_nano_soc.dtb`.

= Déploiement Kernel - ITS

Une fois la compilation terminé, le `de1soc.its` peut être modifié avec les bons chemins pour la `zImage` et le bon `dtb`:

Note: Adapter les chemins par rapport à où se trouve le fichier `.its` en relation avec les sources linux.
Le fichier est fourni avec ce rapport.
Voici la différence avec l'`its` fournit pour le labo 5.

```diff
diff --git a/labo5/de1soc.its b/labo5/de1soc.its
index 3b55b7b..8c2d183 100755
--- a/labo5/de1soc.its
+++ b/labo5/de1soc.its
@@ -25,7 +25,7 @@
 
 		linux {
 			description = "Linux kernel";
-			data = /incbin/(" ");
+			data = /incbin/("../linux/arch/arm/boot/zImage");
 			type = "kernel";
 			arch = "arm";
 			os = "linux";
@@ -36,7 +36,7 @@
 
 		fdt {
 			description = "Linux device tree blob";
-			data = /incbin/("arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de0_nano_soc.dtb");
+			data = /incbin/("../linux/arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de1_nano_soc.dtb");
 			type = "flat_dt";
 			arch = "arm64";
 			compression = "none";
``` 

La compilation se fait avec `mkimage`:

```bash
mkimage -f de1soc.its de1soc.itb
```

Et pour le déployer, il suffit de copier le nouveau `.itb` sur la partition `BOOT` de la carte SD:

Note: Changer le chemin vers le bon. Pour cela, la commande `lsblk` est très utile :).

```bash
cp de1soc.itb /run/media/andre/BOOT/de1soc.itb
```

Notons que le `mount` se fait automatiquement sur ma machine et je n'ai pas eu besoin de le faire.

Le driver ainsi que l'application user-space seront deployés par ssh et donc, on n'aura plus besoin de recompiler le kernel.
La carte SD peut être inséré dans la carte `DE1-SoC`. 

= Programmation FPGA

Aucun changement a eu lieu dans le code FPGA pour ce labo.
Pour convenance, le fichier `.sof` utilisé dans le labo précedent est fourni avec ce rapport.
Si un problème survient, il peut être regénéré avec les sources et la procédure fournis lors du rendu du laboratoire 6.

Pour programmer l'FPGA, on peut utiliser le script `pgm_fpga.py` fourni au début du semestre:

```bash
python3 pgm_fpga.py --sof <path_to_fpga_ip_axi4lite.sof>
```

= Driver de1_io

== Compilation
La compilation peut s'effectuer avec le `Makefile` fourni.
Avant de compiler, il faut modifier les premières lignes pour qu'elles pointent sur les chemins du kernel et de la toolchain correctement:

```makefile
KERNELDIR := /home/andre/dev/heig-vd/scf/scf_2025/linux
TOOLCHAIN := /opt/toolchains/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
```

Ensuite, la compilation peut se faire avec:

```bash
make
```

Le `makefile` compile aussi l'application user space dont je parlerai toute à l'heure.

== Utilisation

Une fois le driver déployé sur la carte `de1-soc`, il peut être inséré à chaud avec:

```bash
insmod access.ko
```

Pour les détails de déploiement, cf chapitre #ref(<deploy>)

== Implémentation

Du côté bus, nous avons des `memory-mapped IO` ce qui est considéré comme un `platform_device` dans le monde `Linux`.

Notre driver sera alors un `platform_driver` et je décide d'utiliser le framework `misc` pour la gestion du côté `user-space`.
Cette framework mettra en place nottament l'entrée dans `/dev` nécéssaire.

Nous devons déclarer les 5 fonctions suivantes dans notre driver:

- Probe
- Remove
- Write Callback
- Read Callback
- Ioctl Callback

Les fonctions `init` et `exit` sont mises en place par le fait qu'on déclare un `platform_driver` avec la macro:

```c
/*
 * As init and exit function only have to register and unregister the
 * platform driver, we can use this helper macros that will automatically
 * create the functions.
 */
module_platform_driver(access_driver);
```

Comme demandé dans la donnée, les fonctions `write` et `read` doivent, respectivement écrire et lire dans le registre antérieurement séléctionné avec ioctl.

```c
static ssize_t on_write(struct file *filp, const char __user *buf, size_t count,
			loff_t *ppos)
{
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);
	uint32_t reg_value = 0;

	if (buf == NULL || count < sizeof(reg_value)) {
		return 0;
	}

	if (copy_from_user(&reg_value, buf, sizeof(reg_value))) {
		return 0;
	}

	iowrite32(reg_value, priv->mem_ptr + priv->selected_offset);

	return sizeof(reg_value);
}
```

```c
static ssize_t on_read(struct file *filp, char __user *buf, size_t count,
		       loff_t *ppos)
{
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);
	uint32_t reg_value = 0;

	if (buf == NULL || count < sizeof(reg_value)) {
		return 0;
	}

	reg_value = ioread32(priv->mem_ptr + priv->selected_offset);

	if (copy_to_user(buf, &reg_value, sizeof(reg_value))) {
		printk("Copy to user failed\n");
		return 0;
	}
	return sizeof(reg_value);
}
```

Finalement, la fonction IOCTL n'accepte qu'une seule commande, la séléction du registre actuel:

```c
#define IOCTL_ACCESS_SELECT_REGISTER 0
```

```c
static long on_ioctl(struct file *filp, unsigned int code, unsigned long value)
{
	struct axi_slave_controller *priv = container_of(
		filp->private_data, struct axi_slave_controller, miscdev);

	printk("IOCTL %d %lu \n", code, value);

	if (code != IOCTL_ACCESS_SELECT_REGISTER) {
		return -EINVAL;
	}

	if (value > priv->reg_count) {
		return -EINVAL;
	}
	priv->selected_offset = value * sizeof(uint32_t);
	return 0;
}
```

= Application User Space

== Compilation

Une application user space est fournie qui permet de tester l'écriture/lecture sur la carte `DE1-SoC` en passant par le driver `de1_io`.
La compilation est effectué avec le même `Makefile` que pour le driver.

```sh
make
```

== Utilisation


Une fois l'application déployée sur la carte `DE1-SoC`, elle peut être utilisée ainsi:

```sh
Usage: ./access_user <dev_file_name> <read|write> <register> [<write_value>]
```

Par exemple:

```bash
# Lire les switches
./access_user /dev/de1_io read 4

# Allumer toutes les leds
./access_user /dev/de1_io write 6 1023
```

Pour les détails de déploiement, cf chapitre #ref(<deploy>)

== Implémentation

L'application sélectionne le registre à lire ou écrire avec un appel sur `ioctl`:

```c
	int err = ioctl(fileno(fp), IOCTL_ACCESS_SELECT_REGISTER, reg);
	if (err) {
		printf("Failed to select the register %d", reg);
		return EXIT_FAILURE;
	}
```

Et soit lit le registre ou écrit une valeur dessus:

```c
	if (is_write) {
		const uint32_t value = atoi(argv[4]);
		printf("W: %#x = %#x\n", reg, value);
		return fwrite(&value, sizeof(value), 1, fp) == sizeof(value) ?
			       EXIT_SUCCESS :
			       EXIT_FAILURE;
	}
	uint32_t value = 0;

	ssize_t bytes_read = fread(&value, 1, sizeof(value), fp);

	if (bytes_read != sizeof(value)) {
		printf("Failed to read register %zu\n", bytes_read);
		return EXIT_FAILURE;
	}
	printf("R: %#x = %#x\n", reg, value);
```

#pagebreak()

= Déploiement Driver et Application User Space <deploy>

Le déploiement peut se faire avec `scp`:

```sh
scp access.ko access_user root@192.168.0.2:~
```

Dans la carte `de1`, le driver peut être inséré avec:

```sh
insmod access.ko
```

Le code user space peut être lancé avec les commandes lancées précedemment. 
Par exemple:

```bash
# Lire les switches
./access_user /dev/de1_io read 4

# Allumer toutes les leds
./access_user /dev/de1_io write 6 1023
```

Voici, pour référence, la description des registres:

#table(
  columns: (auto, auto, auto, auto),
  align: (center, left, center, left),
  inset: 8pt,
  stroke: 0.75pt,
  [*Register Number*], [*Offset*], [*R/W*], [*Description*],

  [0], [0x00], [R], [Constant (0xBADB100D)],
  [1], [0x04], [RW], [Test Register],
  [2], [0x08], [R], [Input register (Keys)],
  [3], [0x0C], [RW], [Edge capture register (Keys)],
  [4], [0x10], [R], [Input register (Switch)],
  [5], [0x14], [RW], [Output register (LED)],
  [6], [0x18], [W], [Set register (LED)],
  [7], [0x1C], [W], [Clear register (LED)],
  [8], [0x20], [RW], [Output register (HEX3-0)],
  [9], [0x24], [RW], [Output register (HEX5-4)]
)

#pagebreak()

= Conclusion

Ce laboratoire m'a permis de développer avec succès un driver Linux pour le bridge Lightweight HPS-to-FPGA sur la carte DE1-SoC.
Grâce à ce driver, il est désormais possible de lire et d'écrire dans les différents registres mémoire mappés,
permettant ainsi d'interagir avec les périphériques connectés à la partie FPGA depuis l'espace utilisateur.

La méthode choisie, utilisant un driver de type `platform_driver` avec le `framework misc`, s'est avérée efficace pour créer une interface simple d'utilisation.
Les opérations de lecture et d'écriture fonctionnent comme prévu, et l'application utilisateur développée permet de tester facilement ces fonctionnalités.

Ce travail constitue une base solide pour des développements futurs plus complexes. Il serait notamment intéressant d'étendre les fonctionnalités du driver pour
gérer des interruptions ou implémenter des mécanismes de synchronisation plus avancés. De plus, l'application utilisateur pourrait être enrichie pour offrir une
interface plus conviviale ou pour permettre des interactions plus complexes avec le matériel.

En conclusion, ce laboratoire a permis d'acquérir une compréhension approfondie de l'architecture du système et des mécanismes de communication entre le processeur et la FPGA,
tout en maîtrisant les techniques de développement de drivers sous Linux.
