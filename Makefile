all: configure build

submodule:
	git submodule update --recursive --init --depth=1

LiteRT/configure.py: submodule

CONFIG=/usr/bin/python3\
 /usr/lib/python3/dist-packages\
 N\
 N\
 ${if ${WITH_CLANG},Y,N}\
 ${if ${WITH_CLANG},/usb/bin/gcc,/usr/bin/clang}\
 -Wno-sign-compare\
 N\
 -Wno-c++20-designator -Wno-gnu-inline-cpp-without-extern\

space=${_space_} ${_space_}
 
LiteRT.configure: LiteRT/configure
	git -C LiteRT checkout .
	printf "$(subst ${space},\n,${CONFIG})\n"	| $^

configure: LiteRT.configure

BAZEL_CACHE_PERSISTENT=${CURDIR}/.cache/bazel
BAZEL_CACHE=${CURDIR}/.cache/bazel
BAZEL=set -eux;cd LiteRT;bazel --output_base ${BAZEL_CACHE}
BAZEL_OPTS=$(if $(IDX_CHANNEL),,--repository_cache=${BAZEL_CACHE_PERSISTENT}-repo --disk_cache=${BAZEL_CACHE_PERSISTENT}-build)

TARGETS=\
 //litert/runtime:metrics\

BAZEL_BUILD_OPTS=${BAZEL_OPTS} --define use_stablehlo=true\
  $(if ${WITH_GDB} ,--compilation_mode dbg, --compilation_mode opt --strip=always)

fetch:
	${BAZEL} fetch ${BAZEL_OPTS} ${TARGETS}

build:
	${BAZEL} build ${BAZEL_BUILD_OPTS} ${TARGETS}

clean:
	${BAZEL} clean --expunge

.PHONY:\
 build\
 builder.build\
 clean\
 configure\
 fetch\
 LiteRT.configure\
 log\
 patches\
 submodule\