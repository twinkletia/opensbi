set -ex

make clean
make CROSS_COMPILE=riscv32-unknown-elf- PLATFORM=rv32xsoc FW_PAYLOAD_PATH=../../linux/arch/riscv/boot/Image FW_FDT_PATH=../bootrom/rv32xsoc.dtb
make -C ../../simulation
cp ../../simulation/bootrom.hex ./
cp ../../simulation/rv32x_simulation ./
cp ../../simulation/gtk.sh ./
cp ../../simulation/rv32x.gtkw ./