all: configure build

submodule:
	git submodule update --recursive --init --depth=1

LiteRT/configure.py: submodule

WITH_CLANG?=1

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

LiteRT/third_party/tensorflow/third_party/xla/third_party/py/python_wheel.bzl:
	git -C LiteRT/third_party/tensorflow/ checkout master

LiteRT.patch: LiteRT/third_party/tensorflow/third_party/xla/third_party/py/python_wheel.bzl
	git -C litert apply <cxx_version.patch
 
LiteRT.configure: LiteRT/configure LiteRT.patch 
	git -C LiteRT checkout .
	printf "$(subst ${space},\n,${CONFIG})\n" | $<

patches:
	git -C LiteRT diff .bazelrc >cxx_version.patch

configure: LiteRT.configure

BAZEL_CACHE_PERSISTENT=${CURDIR}/.cache/bazel
BAZEL_CACHE=${CURDIR}/.cache/bazel
BAZEL=set -eux;cd LiteRT;bazel --output_base ${BAZEL_CACHE}
BAZEL_OPTS=$(if $(IDX_CHANNEL),,--repository_cache=${BAZEL_CACHE_PERSISTENT}-repo --disk_cache=${BAZEL_CACHE_PERSISTENT}-build)

TARGETS_TEST=$(addprefix //litert/tools:,\
 benchmark_litert_model_test\
 apply_plugin_test\
 apply_plugin_main_for_test\
)

TARGETS=$(addprefix //litert/tools:,\
 apply_plugin\
 run_model\
)\
 ${TARGETS_TEST}

BAZEL_BUILD_OPTS=${BAZEL_OPTS} --define use_stablehlo=true\
  $(if ${WITH_GDB} ,--compilation_mode dbg, --compilation_mode opt --strip=always)

fetch:
	${BAZEL} fetch ${BAZEL_OPTS} ${TARGETS}

build:
	${BAZEL} build ${BAZEL_BUILD_OPTS} ${TARGETS}

run:
	${BAZEL} run ${BAZEL_BUILD_OPTS} ${TARGETS_TEST}

clean:
	${BAZEL} clean --expunge

.PHONY:\
 build\
 builder.build\
 clean\
 configure\
 fetch\
 LiteRT.configure\
 LiteRT.patch\
 log\
 log\
 patches\
 submodule\
