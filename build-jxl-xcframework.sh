#!/bin/bash

git clone https://github.com/libjxl/libjxl.git --recursive
pushd libjxl

git checkout v0.8.1 --force
git submodule update --init --recursive

mkdir -p build
pushd build

CMAKE_OSX_ARCHITECTURES='arm64' cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_OSX_DEPLOYMENT_TARGET='12.0' ..
CMAKE_OSX_ARCHITECTURES='arm64' cmake --build . --target jxl-static -- -j
CMAKE_OSX_ARCHITECTURES='arm64' cmake --build . --target jxl_threads-static -- -j

popd
popd

mkdir -p jpeg-xl/lib
mkdir -p jpeg-xl/include/jxl
cp -R libjxl/build/lib/libjxl*.a jpeg-xl/lib
cp -R libjxl/build/third_party/highway/libhwy.a jpeg-xl/lib
cp -R libjxl/build/third_party/brotli/libbrotli*-static.a jpeg-xl/lib

cp -R libjxl/build/lib/include/jxl/* jpeg-xl/include/jxl/
cp -R libjxl/lib/include/jxl/* jpeg-xl/include/jxl/

pushd jpeg-xl

pushd lib
xcrun libtool -static -o libJpegXL.a libbrotlicommon-static.a libbrotlidec-static.a libbrotlienc-static.a libhwy.a libjxl.a libjxl_threads.a
popd

xcodebuild -create-xcframework -library lib/libJpegXL.a -headers include -output ../jxl.xcframework

popd