all: configure build

iree/configure_bazel.py:
	git submodule update --recursive --init --depth=1

iree.configure: iree/configure_bazel.py
	git -C iree checkout .
	env $(if ${WITH_CLANG},CC=/usr/bin/clang CXX=/usr/bin/clang++,CC=/usr/bin/gcc CXX=/usr/bin/g++) python3 $^

configure: iree.configure

BAZEL_CACHE_PERSISTENT=${CURDIR}/.cache/bazel
BAZEL_CACHE=${CURDIR}/.cache/bazel
BAZEL=set -eux;cd iree;bazel --output_base ${BAZEL_CACHE}
BAZEL_OPTS=$(if $(IDX_CHANNEL),,--repository_cache=${BAZEL_CACHE_PERSISTENT}-repo --disk_cache=${BAZEL_CACHE_PERSISTENT}-build)

TARGETS=\
 //tools:iree-compile\
 //tools:iree-opt\

BAZEL_BUILD_OPTS=${BAZEL_OPTS} --define use_stablehlo=true\
  $(if ${WITH_GDB} ,--compilation_mode dbg, --compilation_mode opt --strip=always)

fetch:
	${BAZEL} fetch ${BAZEL_OPTS} ${TARGETS}

build:
	${BAZEL} build ${BAZEL_BUILD_OPTS} ${TARGETS}

PROTOBUF_ROOTS=\
 iree/pjrt/execute_options.proto\
 iree/pjrt/compile_options.proto\
 iree/xla.proto\

PROTOBUF_FILES= ${PROTOBUF_ROOTS}\
 iree/autotune_results.proto\
 iree/autotuning.proto\
 iree/service/hlo.proto\
 iree/service/metrics.proto\
 iree/stream_executor/cuda/cuda_compute_capability.proto\
 iree/stream_executor/device_description.proto\
 iree/tsl/protobuf/dnn.proto\
 iree/xla_data.proto\

GOOGLE_PROTOBUF_FILES=\
 any.proto\
 duration.proto\
 timestamp.proto\
 wrappers.proto\

hlo.clean:
	git -C $(basename $@) clean -xdf .

run: hlo.clean run.exec run.protobuf

PROTOC=iree/bazel-bin/external/com_google_protobuf/protoc 
run.protobuf:
	${BAZEL} run ${BAZEL_BUILD_OPTS} @com_google_protobuf//:protoc
	mkdir -p hlo/google/protobuf
	cp -pv $(addprefix .cache/bazel/external/protobuf/src/google/protobuf/,${GOOGLE_PROTOBUF_FILES}) hlo/google/protobuf/
	set -eux;$(foreach d,$(sort $(dir $(PROTOBUF_FILES))), mkdir -p hlo/$d ;) true
	$(foreach f,$(PROTOBUF_FILES),\
 cp -v iree/$f hlo/$f;) true
	set -eux;$(foreach f,$(PROTOBUF_ROOTS),\
 ${PROTOC} --proto_path=hlo -o/dev/null hlo/$f;) true
	set -eux;$(foreach f, add.3x2 Identity.2x2,\
 ${PROTOC} --decode=iree.HloModuleProto --proto_path=hlo hlo/xla/xla.proto < hlo/${f}.xla.pb > hlo/${f}.xla.txt;) true
	${PROTOC} --decode=iree.CompileOptionsProto --proto_path=hlo xla/pjrt/compile_options.proto < hlo/compile_options.0.pb > hlo/compile_options.0.txt
	set -eux;$(foreach f, add.3x2 Identity.2x2,\
 iree/bazel-bin/xla/hlo/translate/xla-translate --hlo-to-mlir-hlo hlo/${f}.xla.pb | xla/bazel-bin/xla/hlo/translate/xla-translate --mlir-hlo-to-hlo-text >hlo/${f}.txt;) true

run.exec:
	${BAZEL} build ${BAZEL_BUILD_OPTS} ${TARGET}
	rm -f hlo/pjrt_c_api_cpu_plugin.so
	cp -pv iree/bazel-bin/xla/pjrt/c/pjrt_c_api_cpu_plugin.so.runfiles/xla/xla/pjrt/c/pjrt_c_api_cpu_plugin.so hlo/
	chmod +w hlo/pjrt_c_api_cpu_plugin.so
	$(if ${WITH_GDB},,strip hlo/pjrt_c_api_cpu_plugin.so)
	cp -pv iree/xla/pjrt/c/pjrt_c_api.h hlo/
	${BAZEL} run ${BAZEL_BUILD_OPTS} //iree/examples/axpy:stablehlo_compile_test 
	cp -pv $(addprefix iree/bazel-bin/xla/examples/axpy/stablehlo_compile_test.runfiles/xla/, *.mlir.bc *.pb) hlo/
	${BAZEL} run ${BAZEL_BUILD_OPTS} //iree/pjrt/c:pjrt_c_api_cpu_test
	${BAZEL} run ${BAZEL_BUILD_OPTS} //iree/pjrt/cpu:cpu_client_test
	cp -pv iree/bazel-bin/xla/pjrt/cpu/cpu_client_test.runfiles/xla/*.pb hlo/

patches:
	git -C iree diff xla/pjrt/cpu > cpu_client_test.patch
	git -C iree diff xla/pjrt/pjrt_c_api_client.cc > pjrt_c_api_client.patch

hlo:
	${MAKE} -C hlo run clean

log:
	${BAZEL} info command_log

clean:
	${BAZEL} clean --expunge

.PHONY:\
 %.build\
 build\
 builder.build\
 clean\
 configure\
 fetch\
 hlo\
 iree.configure\
 log\
 patches\
 pjrt.build\