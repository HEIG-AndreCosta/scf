KERNELDIR := /home/andre/dev/heig-vd/scf/scf_2025/linux
TOOLCHAIN := /opt/toolchains/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
obj-m := access.o

PWD := $(shell pwd)
WARN := -W -Wall -Wextra -Wstrict-prototypes -Wmissing-prototypes

all: access access_user

access_user: access_user.c
	 /opt/toolchains/gcc-linaro-11.3.1-2022.06-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc -o access_user $<
access:
	@echo "Building with kernel sources in $(KERNELDIR)"
	$(MAKE) ARCH=arm CROSS_COMPILE=$(TOOLCHAIN) -C $(KERNELDIR) M=$(PWD) ${WARN}
	rm -rf *.o *~ core .depend .*.cmd *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a

clean:
	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers *.mod *.a access_user
