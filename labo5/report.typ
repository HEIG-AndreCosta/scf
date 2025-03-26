= SCF 2025 

== Laboratoire 05 
== Portage de Linux sur la carte DE-1

=== André Costa


== Objectifs 

Vous apprendrez comment partitionner une carte SD, compiler et démarrer Linux.

== Génération de la carte SD

La génération de la carte SD passe copier l'image fournie dessus.

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

== Compilation de Linux 

La deuxième étape passe par compiler Linux nous-mêmes.

On commence par cloner le repository:

```bash
git clone git@github.com:torvalds/linux.git --depth=1
```

Configurer avec le bon `defconfig`:

Notons que la toolchian `arm-linux-gnueabihf` est dans le `PATH`.

```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
``` 

Et finalement la compilation:

```bash
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -$(nproc)
``` 

A ce-moment le fichier `zImage` peut être trouvé dans `arch/arm/boot/zImage`.

== Création du Device Tree

Le device tree de la `de0` peut être trouvé dans `arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de0_nano_soc.dts`.

Pour suivre la convention de nommage je l'ai recopié dans le même repértoire avec la mention `de1` : `arch/arm/boot/dts/intel/socfpga/socfpga_cyclone5_de1_nano_soc.dts`

Après avoir supprimé les noeuds `gpio0`, `gpio1`, `gpio2` et `i2c0`, j'ai ajouté le noeud pour le bridge lightweight:

```dts
&fpga_bridge0 {
	reg = <0xff200000 0x100000>;
	status = "okay";
};
``` 


Et ajouté les `bootargs` comme décrit dans la donnée

```dts
	bootargs = "root=/dev/mmcblk0p3 rw rootwait earlyprintk";
```

Pour convenance, voici la différence entre les deux fichiers:

```diff
--- socfpga_cyclone5_de0_nano_soc.dts	2025-03-26 11:13:15.563865561 +0100
+++ socfpga_cyclone5_de1_nano_soc.dts	2025-03-26 12:11:30.019553335 +0100
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
 
@@ -41,6 +41,11 @@
 	};
 };
 
+&fpga_bridge0 {
+	reg = <0xff200000 0x100000>;
+	status = "okay";
+};
+
 &gmac1 {
 	status = "okay";
 	phy-mode = "rgmii";
@@ -61,31 +66,6 @@
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


Une fois le dts mis en place, il faut encore modifier le Makefile du répértoire `arch/arm/boot/dts/intel/socfpga/Makefile` pour ajouter le nouveau dts.

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

== ITS

Maintenant avec notre nouveau dts, le `de1soc.its` peut être modifié avec les bons chemins pour la `zImage` et le bon `dtb`:

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

Et pour le déployer, il suffit de copier sur la partition `BOOT`:

```bash
cp de1soc.itb /run/media/andre/BOOT/de1soc.itb
```

== Test Bridge HPS - FPGA

Une fois le programme `devmem2.c` téléchargé, il peut être cross-compilé avec la même toolchain utilisé pour compiler le noyau.

```bash
arm-linux-gnueabihf-gcc devmem2.c -o devmem2
```

Copié avec `scp`:

```bash
scp devmem2 root@192.168.0.2:~
```

L'utilisation est affichée lors que nous lançons le programme sans arguments

```bash
evl-de1 ~ # ./devmem2 

	Usage:	./devmem2 { address } [ type [ data ] ]
		address : memory address to act upon
		type    : access operation type : [b]yte, [h]alfword, [w]ord
		data    : data to be written
``` 


La donnée indique que les switches et les boutons sont mappés sur le bridge lwhps2fpga aux offsets `0x4b000` et `0x4b004` respectivement. Notons que l'adresse de base du bridge est `0xff200000`.


Pour lire les switches, on peut donc lancer le programme avec:

```bash
evl-de1 ~ # ./devmem2 0xff24b000
	/dev/mem opened.
	Memory mapped at address 0xb6f50000.
	Value at address 0xFF24B000 (0xb6f50000): 0x0
evl-de1 ~ # ./devmem2 0xff24b000
	/dev/mem opened.
	Memory mapped at address 0xb6f4f000.
	Value at address 0xFF24B000 (0xb6f4f000): 0x3FF
```

Et pour les boutons, on peut utiliser:

```bash
evl-de1 ~ # ./devmem2 0xff24b004
	/dev/mem opened.
	Memory mapped at address 0xb6fc5000.
	Value at address 0xFF24B004 (0xb6fc5004): 0x4
evl-de1 ~ # ./devmem2 0xff24b004
	/dev/mem opened.
	Memory mapped at address 0xb6f5c000.
	Value at address 0xFF24B004 (0xb6f5c004): 0x0
evl-de1 ~ # ./devmem2 0xff24b004
	/dev/mem opened.
	Memory mapped at address 0xb6f60000.
	Value at address 0xFF24B004 (0xb6f60004): 0x8
```

