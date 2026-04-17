all: cpu

CPUS=$$(getconf _NPROCESSORS_ONLN)

NVIDIA_GPU = $(shell nvidia-smi -L 2>/dev/null | head -1)
CMAKE.cuda = -DGGML_CUDA=ON -DGGML_NATIVE=OFF $(if $(NVIDIA_GPU),-DCMAKE_CUDA_ARCHITECTURES=native)
ENV.cuda=env PATH=$$PATH:/usr/local/cuda/bin

CMAKE.metal=\
 -DGGML_METAL_EMBED_LIBRARY=ON\
 -DGGML_METAL_USE_BF16=ON\
 -DGGML_OPENMP=OFF\

%.build: llama.cpp/CMakeLists.txt
	cd llama.cpp && $(ENV.$(basename $@)) cmake -B build.$(basename $@) -G Ninja -DCMAKE_BUILD_TYPE=Release $(CMAKE.$(basename $@))
	cd llama.cpp && $(ENV.$(basename $@)) cmake --build build.$(basename $@) -j ${CPUS} --target llama-cli llama-completion llama-server llama-bench

LLAMA_COMPLETION=llama.cpp/build.$(basename $@)/bin/llama-completion
LLAMA_CLI=llama.cpp/build.$(basename $@)/bin/llama-cli

MODEL=-hf bartowski/SmolLM2-135M-Instruct-GGUF
%.run:
	${LLAMA_CLI} --list-devices
	${LLAMA_COMPLETION} ${MODEL} -p 'find x, when x = 1 + 2' -n 128 --single-turn

BENCH_TYPE ?=
%.bench:
	sh bench.sh $(basename $@) $(BENCH_TYPE)

%.clean:
	rm -rf llama.cpp/build.$(basename $@)

cpu: cpu.build cpu.run

cuda: cuda.build cuda.run

metal: metal.build metal.run

llama.cpp/CMakeLists.txt: llama.cpp

llama.cpp:
	git submodule update --recursive --init --depth=1 $@

clean: cpu.clean cuda.clean metal.clean

.PHONY: llama.cpp clean %.clean metal cpu cuda
