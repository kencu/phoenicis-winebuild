#!/bin/bash
cd /root
git clone https://github.com/AndreRH/hangover
cd hangover
git submodule init
git submodule update

mkdir -p /root/hangover-build/

cd /root/hangover/
mkdir -p build/libiconv32
cd build/libiconv32
../../libiconv/configure --host=i686-w64-mingw32 --prefix="/root/hangover-build/i686-w64-mingw32"
make -j 4
make install

cd /root/hangover/
mkdir -p build/libiconv64
cd build/libiconv64
../../libiconv/configure --host=x86_64-w64-mingw32 --prefix="/root/hangover-build/x86_64-w64-mingw32"
make -j 4
make install

cd /root/hangover/libxml2
NOCONFIGURE=1 ./autogen.sh
cd /root/hangover/

mkdir -p build/libxml2_32
cd build/libxml2_32
../../libxml2/configure --host=i686-w64-mingw32 --enable-static=no --enable-shared=yes --without-python --without-zlib --without-lzma --with-iconv=/root/hangover-build/i686-w64-mingw32 --prefix=/root/hangover-build/i686-w64-mingw32
make -j 4
make install

cd /root/hangover/
mkdir -p build/libxml2_64
cd build/libxml2_64
../../libxml2/configure --host=x86_64-w64-mingw32 --enable-static=no --enable-shared=yes --without-python --without-zlib --without-lzma --with-iconv=/root/hangover-build/x86_64-w64-mingw32 --prefix=/root/hangover-build/x86_64-w64-mingw32
make -j 4
make install

cd /root/hangover/libxslt
NOCONFIGURE=1 ./autogen.sh

add $(LIBXML_LIBS) in the hangover/libxslt/libexslt/Makefile.am, line 30

cd /root/hangover/
mkdir -p build/libxslt32
cd build/libxslt32
../../libxslt/configure --host=i686-w64-mingw32 --enable-static=no --enable-shared=yes --without-python --without-plugins --without-crypto --prefix=/root/hangover-build/i686-w64-mingw32 PATH=/root/hangover-build/i686-w64-mingw32/bin:$PATH PKG_CONFIG_PATH=/root/hangover-build/i686-w64-mingw32/lib/pkgconfig
make -j4
make install

cd /root/hangover/
mkdir -p build/libxslt64
cd build/libxslt64
../../libxslt/configure --host=x86_64-w64-mingw32 --enable-static=no --enable-shared=yes --without-python --without-plugins --without-crypto --prefix=/root/hangover-build/x86_64-w64-mingw32 PATH=/root/hangover-build/x86_64-w64-mingw32/bin:$PATH PKG_CONFIG_PATH=/root/hangover-build/x86_64-w64-mingw32/lib/pkgconfig
make -j4




##### WINE
mkdir -p /root/hangover/build/wine-tools
cd /root/hangover/build/wine-tools
../../wine/configure --enable-win64
make __tooldeps__ -j 4


##### Cross environment
export FRAMEWORK="10.11"

## Some tools are not directly found by wine
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ld" "/root/osxcross/target/bin/ld"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-otool" "/root/osxcross/target/bin/otool"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ranlib" "/root/osxcross/target/bin/ranlib"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ar" "/root/osxcross/target/bin/ar"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-as" "/root/osxcross/target/bin/as"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-install_name_tool" "/root/osxcross/target/bin/install_name_tool"

export CC="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"

##### GLIB
cd /root/hangover
NOCONFIGURE=1 ./autogen.sh
./configure --prefix="/root/hangover-build/x86_64-apple-darwin15/" --host x86_64-apple-darwin15


## This hack will allow winegcc to use the right compiler
echo '$CC "$@"' > "/root/osxcross/target/bin/x86_64-apple-darwin15-gcc"
chmod +x "/root/osxcross/target/bin/x86_64-apple-darwin15-gcc"

mkdir -p /root/hangover/build/wine-host
cd /root/hangover/build/wine-host
export C_INCLUDE_PATH="/root/osxcross/target/macports/pkgs/opt/local/include/:/root/osxcross/target/macports/pkgs/opt/local/include/libxml2/:/root/vkd3d/include/"
export LIBRARY_PATH="/root/osxcross/target/macports/pkgs/opt/local/lib"
../../wine/configure --enable-win64 --host x86_64-apple-darwin15 --prefix="/" --with-wine-tools="/root/hangover/build/wine-tools" LFFLAGS=" -Wl,-rpath,/opt/x11/lib -L/root/osxcross/target/macports/pkgs/opt/local/lib -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"
touch /root/hangover/build/wine-host/.built

rm /root/osxcross/target/bin/ld
rm /root/osxcross/target/bin/otool
rm /root/osxcross/target/bin/ranlib
rm /root/osxcross/target/bin/ar
rm /root/osxcross/target/bin/as
rm /root/osxcross/target/bin/install_name_tool

mkdir -p /root/hangover/build/wine-guest
cd /root/hangover/build/wine-guest
export C_INCLUDE_PATH="/root/hangover-build/x86_64-w64-mingw32/include/:/root/hangover-build/x86_64-w64-mingw32/include/libxml2/"
export LIBRARY_PATH="/root/hangover-build/x86_64-w64-mingw32/lib:/root/hangover-build/x86_64-w64-mingw32/bin"
export LDFLAGS="-L/root/hangover-build/x86_64-w64-mingw32/lib -L/root/hangover-build/x86_64-w64-mingw32/bin -lxml2"
../../wine/configure --disable-tests --host=x86_64-w64-mingw32 --with-wine-tools=../wine-tools --without-freetype --with-xml --with-xslt ac_cv_lib_soname_xslt="libxslt-1.dll"

mkdir -p /root/hangover/build/wine-guest32
cd /root/hangover/build/wine-guest32
export C_INCLUDE_PATH="/root/hangover-build/i686-w64-mingw32/include/:/root/hangover-build/i686-w64-mingw32/include/libxml2/"
export LIBRARY_PATH="/root/hangover-build/i686-w64-mingw32/lib:/root/hangover-build/i686-w64-mingw32/bin"
export LDFLAGS="-L/root/hangover-build/i686-w64-mingw32/lib -L/root/hangover-build/i686-w64-mingw32/bin -lxml2"
../../wine/configure --disable-tests --host=i686-w64-mingw32 --with-wine-tools=../wine-tools --without-freetype --with-xml --with-xslt ac_cv_lib_soname_xslt="libxslt-1.dll"

mkdir -p /root/hangover/build/qemu


ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ld" "/root/osxcross/target/bin/ld"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-otool" "/root/osxcross/target/bin/otool"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ranlib" "/root/osxcross/target/bin/ranlib"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-ar" "/root/osxcross/target/bin/ar"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-as" "/root/osxcross/target/bin/as"
ln -s "/root/osxcross/target/bin/x86_64-apple-darwin15-install_name_tool" "/root/osxcross/target/bin/install_name_tool"

export CC="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"

mkdir -p /root/hangover/bin/
touch /root/hangover/bin/Rez
chmod +x /root/hangover/bin/Rez
touch /root/hangover/bin/SetFile
chmod +x /root/hangover/bin/SetFile

omp install glib2-devel

cat << EOF > /root/hangover/bin/qemugcc
#!/bin/bash
export CC="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"
/root/hangover/build/wine-tools/tools/winegcc/winegcc -b x86_64-apple-darwin15  -B/root/hangover/build/wine-tools/tools/winebuild/ -I/root/hangover/build/wine-tools/include/ -I/root/hangover/wine/include -lpthread -DWINE_NOWINSOCK -I/root/osxcross/target/macports/pkgs/opt/local/include/glib-2.0/ -I/root/hangover/glib/glib/ -L/root/osxcross/target/macports/pkgs/opt/local/lib --sysroot=/root/hangover/build/wine-host/ "\$@"
EOF
chmod +x /root/hangover/bin/qemugcc


cat << EOF > /root/hangover/bin/qemug++
#!/bin/bash
export CC="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"
export CXX="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"
/root/hangover/build/wine-tools/tools/winegcc/wineg++ -b x86_64-apple-darwin15 -B/root/hangover/build/wine-tools/tools/winebuild -I/root/hangover/build/wine-tools/include -I/root/hangover/wine/include -lpthread -DWINE_NOWINSOCK -I/root/osxcross/target/macports/pkgs/opt/local/include/glib-2.0/ -I/root/hangover/glib/glib/ --sysroot=/root/hangover/build/wine-host/ -L/root/osxcross/target/macports/pkgs/opt/local/lib "\$@"
EOF
chmod +x /root/hangover/bin/qemug++

cat << EOF > /root/hangover/bin/dllgcc
#!/bin/bash
export CC="clang-7 -O3 -target x86_64-apple-darwin15 -mlinker-version=0.0 -mmacosx-version-min=10.8 -B/root/osxcross/target/bin/ -isysroot/root/osxcross/target/SDK/MacOSX$FRAMEWORK.sdk/  -F/root/osxcross/target/macports/pkgs/opt/local/Library/Frameworks"
/root/hangover/build/wine-tools/tools/winegcc/winegcc -b x86_64-apple-darwin15  -B/root/hangover/build/wine-tools/tools/winebuild/ -I/root/hangover/build/wine-host/include/ -I/root/hangover/wine/include --sysroot=/root/hangover/build/wine-host/ "\$@"
EOF
chmod +x /root/hangover/bin/dllgcc

export PATH="/root/hangover/bin:$PATH"

CC="qemugcc" CXX="qemug++" ../../qemu/configure --disable-bzip2 --disable-libusb --disable-sdl --disable-snappy --disable-virtfs --disable-opengl --python=/usr/bin/python2.7 --disable-xen --disable-lzo --disable-qom-cast-debug --disable-vnc --disable-seccomp --disable-strip --disable-hax --disable-gnutls --disable-nettle --disable-replication --disable-tpm --disable-gtk --disable-gcrypt --disable-linux-aio --disable-system --disable-tools --disable-linux-user --disable-guest-agent --enable-windows-user --disable-fdt --disable-capstone

mkdir -p x86_64-windows-user/qemu_guest_dll64
mkdir -p x86_64-windows-user/qemu_host_dll64
mkdir -p x86_64-windows-user/qemu_guest_dll32
mkdir -p x86_64-windows-user/qemu_host_dll32


cp /usr/lib/gcc/i686-w64-mingw32/6.3-win32/libgcc_s_sjlj-1.dll x86_64-windows-user/qemu_guest_dll32
