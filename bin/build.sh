KERNEL_NAME="$1"
SETUP_SCRIPT="$2"
BRANCH="$3"
PATCHES="$4"

export flags="O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi-"

cd $GITHUB_WORKSPACE/kernel
curl -LSs "$SETUP_SCRIPT" | bash -s "$BRANCH"

cp $GITHUB_WORKSPACE/this-repo/dipper_defconfig arch/arm64/configs/
cp $GITHUB_WORKSPACE/this-repo/susfs_files/* ./ -r

if [ -n "$PATCHES" ]; then
  IFS=' ' read -r -a patch_array <<< "$PATCHES"
  for patch_file in "${patch_array[@]}"; do
    patch -p1 < "$GITHUB_WORKSPACE/this-repo/$patch_file"
  done
fi

git add . && git commit -m "clean working tree"

make $flags dipper_defconfig
make $flags -j$(nproc --all) 1> /dev/null

cp out/arch/arm64/boot/Image.gz-dtb $GITHUB_WORKSPACE/AnyKernel3
if [ -f out/arch/arm64/boot/dtbo.img ]; then
  cp out/arch/arm64/boot/dtbo.img $GITHUB_WORKSPACE/AnyKernel3
fi

zip -r $GITHUB_WORKSPACE/"$KERNEL_NAME".zip $GITHUB_WORKSPACE/AnyKernel3/*
cd $GITHUB_WORKSPACE