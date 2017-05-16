#ndk 目录根据你的安装目录
export ANDROID_NDK=$NDK_ROOT
# 需要编译cup架构类型，加入下面的()中，用空格分割
export SUPPORTED_ARCHITECTURES=(armeabi armeabi-v7a armeabi-v7a-neon x86 x86_64)
#编译结果的目录
export PREFIXDIR=android-lib 
# NDK 编译工具版本，参考 ANDROID_NDK/toolchains/ 目录下面文件夹末尾数字
export NDK_TOOLCHAIN_ABI_VERSION=4.9
# 需要支持的 Android 版本 ， 参考 ANDROID_NDK/platforms/ 目录下面的文件夹名称
export ANDROID_API_VERSION=23

## 配置编译环境并且编译
function configAndMake(){
case ${ARCH} in
  armeabi-v7a | armeabi-v7a-neon | armeabi)
    CPU='cortex-a8'
  ;;
  x86)
    CPU='i686'
  ;;
  x86_64)
    CPU="x86-64"
   ;;
esac

PREFIX="${PREFIXDIR}/${ARCH}"

./configure \
   --prefix=$PREFIX \
   --enable-shared \
   --disable-static \
   --disable-doc \
   --disable-ffmpeg \
   --disable-ffplay \
   --disable-ffprobe \
   --disable-ffserver \
   --disable-doc \
   --disable-symver \
   --enable-small \
   --cross-prefix="$CROSS_PREFIX" \
   --cpu=$CPU \
   --target-os=linux \
   --arch=$ARCH \
   --enable-cross-compile \
   --sysroot=$SYSROOT \
   --extra-cflags="-I${TOOLCHAIN}/include $CFLAGS" \
   --extra-ldflags="-L${TOOLCHAIN}/lib $LDFLAGS" 
 # --extra-libs="-lpng -lexpat -lm" \
 # --extra-cxxflags="$CXX_FLAGS" || exit 1   
make clean
make -j8
make install

}

### 设置 abi 类型对应的编译工具参数
function initabi() {
case $ARCH in
  armeabi)
    NDK_ABI='arm'
    NDK_TOOLCHAIN_ABI='arm-linux-androideabi'
    NDK_CROSS_PREFIX="arm-linux-androideabi"
  ;;

  armeabi-v7a)
    NDK_ABI='arm'
    NDK_TOOLCHAIN_ABI='arm-linux-androideabi'
    NDK_CROSS_PREFIX="arm-linux-androideabi"
    CFLAGS="${CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
    LDFLAGS="${LDFLAGS} -march=armv7-a -Wl,--fix-cortex-a8"
  ;;

  armeabi-v7a-neon)
    NDK_ABI='arm'
    NDK_TOOLCHAIN_ABI='arm-linux-androideabi'
    NDK_CROSS_PREFIX="arm-linux-androideabi"
    CFLAGS="${CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
    LDFLAGS="${LDFLAGS} -march=armv7-a -Wl,--fix-cortex-a8"
  ;;

  x86)
    NDK_ABI='x86'
    NDK_TOOLCHAIN_ABI='x86-linux-android'
    NDK_CROSS_PREFIX="i686-linux-android"
    CFLAGS="$CFLAGS -march=i686"
  ;;

   x86_64)
    NDK_ABI='x86_64'
    NDK_TOOLCHAIN_ABI='x86_64-linux-android'
    NDK_CROSS_PREFIX="x86_64-linux-android"
    CFLAGS="$CFLAGS -march=x86-64 -m64"
   ;;

esac

CROSS_PREFIX=${TOOLCHAIN}/bin/${NDK_CROSS_PREFIX}-
NDK_SYSROOT=${TOOLCHAIN}/sysroot
export PKG_CONFIG_LIBDIR="${TOOLCHAIN}/lib/pkgconfig"

$ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
   --arch=$NDK_ABI \
   --platform=android-${ANDROID_API_VERSION} \
   --install-dir=$TOOLCHAIN \
   --force
   
  export CC="${CROSS_PREFIX}gcc"
  export LD="${CROSS_PREFIX}ld"
  export RANLIB="${CROSS_PREFIX}ranlib"
  export STRIP="${CROSS_PREFIX}strip"
  export READELF="${CROSS_PREFIX}readelf"
  export OBJDUMP="${CROSS_PREFIX}objdump"
  export ADDR2LINE="${CROSS_PREFIX}addr2line"
  export AR="${CROSS_PREFIX}ar"
  export AS="${CROSS_PREFIX}as"
  export CXX="${CROSS_PREFIX}g++"
  export OBJCOPY="${CROSS_PREFIX}objcopy"
  export ELFEDIT="${CROSS_PREFIX}elfedit"
  export CPP="${CROSS_PREFIX}cpp"
  export DWP="${CROSS_PREFIX}dwp"
  export GCONV="${CROSS_PREFIX}gconv"
  export GDP="${CROSS_PREFIX}gdb"
  export GPROF="${CROSS_PREFIX}gprof"
  export NM="${CROSS_PREFIX}nm"
  export SIZE="${CROSS_PREFIX}size"
  export STRINGS="${CROSS_PREFIX}strings"

}

## 初始化环境参数
function initParam(){
CFLAGS='-O3 -fpic -pipe -w'
LDFLAGS=' '
FFMPEG_PKG_CONFIG="$(pwd)/ffmpeg-pkg-config"
TOOLCHAIN=$HOME/fftoolchain #toolchain 安装目录
SYSROOT=$TOOLCHAIN/sysroot/
}

## 编译某一种 cpu 对应的 lib
function build_one(){
   initParam
   initabi
   configAndMake
   cleaner
}

## 编译所以类型 cpu 对应的 lib
function buildAll(){
  for i in "${SUPPORTED_ARCHITECTURES[@]}"
  do
     echo "now ,start to build $i"
     ARCH=$i
     build_one
  done

}

## 删除编译工具
function cleaner(){
  rm -rf $TOOLCHAIN
  rm -rf ./compat/strtod.o
}

buildAll

