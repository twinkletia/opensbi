set -ex

if [ -d fsbuild ]; then
    rm -rf fsbuild
fi
if [ -f linux ]; then
    rm linux
fi
#build initramfs

pushd ../busybox
make ARCH=riscv CROSS_COMPILE=riscv32-unknown-linux-gnu- defconfig
make install ARCH=riscv CROSS_COMPILE=riscv32-unknown-linux-gnu- CFLAGS=-static -j `nproc`
popd

mkdir fsbuild
pushd fsbuild
cp -r /root/software/busybox/_install/*/ ./
mkdir -p dev etc/init.d lib/modules mnt proc tmp var/log var/run var/tmp
pushd dev
mknod console c 5 1
mknod hvc c 229 0
mknod loop0 b 7 0
mknod null c 1 3
ln -s null tty2
ln -s null tty3
ln -s null tty4
popd
pushd etc/init.d
touch rcS
chmod 755 rcS
popd
ln -s bin/busybox init
popd

#build linux

pushd ../linux
sed -i -e 's/CONFIG_INITRAMFS_SOURCE=.*/CONFIG_INITRAMFS_SOURCE=\"\/root\/software\/opensbi\/fsbuild\"/g' /root/software/linux/arch/riscv/configs/rv32xSoC_defconfig
make ARCH=riscv CROSS_COMPILE=riscv32-unknown-linux-gnu- rv32xSoC_defconfig
make CFLAGS="-march=rv32ima_zicsr -mabi=ilp32" LDFLAGS="-march=rv32ima_zicsr -mabi=ilp32" ARCH=riscv CROSS_COMPILE=riscv32-unknown-linux-gnu- all -j`nproc`
popd

#build payload

make clean
make -C ../../simulation/bootrom -B LOADEROPT=-DBINSIZE=0\ -DHEAD=0x80000000
make -C ../../simulation -B SIMOPT=-DKERNEL_START_ADDR=0x80400000
make -C ../bootrom -B
make CROSS_COMPILE=riscv32-unknown-elf- PLATFORM_DIR=platform PLATFORM=rv32xsoc FW_PAYLOAD_PATH=/root/software/linux/arch/riscv/boot/Image FW_FDT_PATH=/root/software/bootrom/rv32xsoc.dtb

#create bootable mmc sim(40M kernel, 60M rootfs)
pushd ../buildroot
make defconfig BR2_DEFCONFIG=configs/rv32xsoc_defconfig
make
popd
dd if=build/platform/rv32xsoc/firmware/fw_payload.bin of=block_device.img
dd if=/root/software/buildroot/output/images/rootfs.ext2 of=block_device.img bs=1k seek=40k count=60k

cp ../../simulation/bootrom.hex ./
cp ../../simulation/rv32x_simulation ./
cp ../../simulation/gtk.sh ./
cp ../../simulation/rv32x.gtkw ./

ln -s build/platform/rv32xsoc/firmware/fw_payload.elf linux
#clear 
#./rv32x_simulation linux --debug-linux --print-entry --print-exception